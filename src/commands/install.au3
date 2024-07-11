#include-once

#include <AutoItConstants.au3>
#include <Crypt.au3>
#include "../lib/config.au3"
#include "../lib/package.au3"
#include "../lib/console.au3"
#include "../../au3pm/au3-md5/md5.au3"

Func Command_Install($sPackage = Null, $sAlias = Null)
    Local $config = au3pm_config_load()
    Local $config_source = @extended

    if $sPackage = Null Then
        ; if no lock file is available, resolve package hashes and generate lock file

        Switch $config_source
            Case $_au3pm_config_lockFile
                ConsoleWrite('Checking lock file hash...'&@CRLF)
                $expected_hash = $config.hash
                $actual_hash = md5(_json_encode($config.packages))
                If Not ($expected_hash == $actual_hash) Then
                    ConsoleWrite("Lockfile content hash mismatch: " & '"' & $expected_hash & '"' & " != " & '"' & $actual_hash & '"' & @CRLF)
                    ConsoleWrite('Generating new lock file...'&@CRLF)
                    ContinueCase
                EndIf

                ConsoleWriteLine('Clearing dependency folder'&@CRLF)
                DirRemove(@WorkingDir & '\au3pm\', $DIR_REMOVE)
                DirCreate(@WorkingDir & '\au3pm\')

                For $oPackage In $config.packages
                    InstallPackage($oPackage.url, $oPackage.name, False, $oPackage.integrity)
                    If @error <> 0 Then
                        ConsoleWrite(StringFormat("Package ""%s"" failed to install.\n", $oPackage.name))
                        Return SetError(1)
                    EndIf
                Next
            Case $_au3pm_config_configFile
                If $config_source = $_au3pm_config_configFile Then
                    ConsoleWriteLine('No au3pm-lock.json found.'&@CRLF)
                Else
                    $config = au3pm_json_load()
                    If @error <> 0 Then
                        ContinueCase
                    EndIf
                EndIf
                ConsoleWriteLine('Resolving dependencies...'&@CRLF)

                ; Combine dependencies and devDependencies
                Local $dependencies = $config.dependencies
                If MapExists($config, 'devDependencies') Then
                    Redim $dependencies[UBound($dependencies) + UBound($config.devDependencies)]
                    For $i = 0 To UBound($config.devDependencies)
                        $dependencies[UBound($dependencies) + $i] = $config.devDependencies[$i]
                    Next
                EndIf

                $resolvedDependencies = getPackageDependencyTree($dependencies)
                If @error <> 0 Then
                    ConsoleWrite("Failed resolving package dependency tree"&@CRLF)
                    Return SetError(1, 0, 1)
                EndIf
                Local $lock_config[UBound($resolvedDependencies)]
                ConsoleWrite(_json_encode_pretty($resolvedDependencies)&@CRLF)

                ConsoleWriteLine('Clearing dependency folder'&@CRLF)
                DirRemove(@WorkingDir & '\au3pm\', $DIR_REMOVE)
                DirCreate(@WorkingDir & '\au3pm\')

                Local $iCount = 0
                For $dependency In MapKeys($resolvedDependencies)
                    Local $sIntegrity = InstallPackage($resolvedDependencies[$dependency]['url'], $dependency)

                    If @error <> 0 Then
                        ConsoleWrite("Installation of package failed: "&$dependency&@CRLF)
                    EndIf
                    Local $lock_config_entry[]
                    $lock_config_entry['name'] = $dependency
                    $lock_config_entry['url'] = $resolvedDependencies[$dependency]['url']
                    $lock_config_entry['integrity'] = $sIntegrity
                    $lock_config[$iCount] = $lock_config_entry
                    $iCount += 1
                Next
                Local $lock_config_object[]
                $lock_config_object['hash'] = md5(_json_encode($lock_config))
                $lock_config_object['packages'] = $lock_config

                au3pm_lock_save($lock_config_object)
            Case $_au3pm_config_noFile
                ConsoleWriteLine('No au3pm.json or au3pm-lock.json found. Please run "au3pm init" first.')
                Return SetError(1, 0, 1)
            Case Else
                ConsoleWriteLine(StringFormat('Unexpected config source: %s \n', $config_source))
                Return SetError(1, 0, 1)
        EndSwitch

        Return SetError(@error, @extended, 1);
    EndIf

    ; Specific package should be installed

    ;$dependencies = 

    ConsoleWriteLine($sPackage)
EndFunc

#cs

If $CmdLine[0] = 1 Then
    ;; FIXME: use au3pm-lock file, instead if available!
    If Not FileExists(@WorkingDir & '\au3pm.json') Then
        ConsoleWriteLine('au3pm.json not found.')
        Exit 0
    EndIf

    $json = FileRead(@WorkingDir & '\au3pm.json')
    $json = _json_decode($json)
    If @error <> 0 Then
        ConsoleWriteLine('problem occured when reading au3pm.json')
        Exit 1
    EndIf
    $dependencies = $json.Item('dependencies')
    If @error <> 0 Then
        ConsoleWriteLine('no dependencies found in au3pm.json')
        Exit 0
    EndIf

    $resolvedDependencies = getPackageDependencyTree($dependencies)
    $dependencies = $resolvedDependencies

    ConsoleWriteLine('Clearing dependency folder'&@CRLF)
    DirRemove(@WorkingDir & '\au3pm\', 1)
    DirCreate(@WorkingDir & '\au3pm\')
    FileDelete($__au3pm_lock_path)
    $lock = au3pm_lock_load()

    For $dependency In $dependencies
        ConsoleWrite($dependency&@CRLF)
        $info = $dependencies.Item($dependency)
        If StringRegExp($info, '^([^/]+/.*)(?:#(.*))$') Then
            $url = StringRegExp($info, '^([^/]+/.*?)(?:#(.*))?$', 1)
            ConsoleWriteLine('Github detected.')
            $url = StringFormat("https://github.com/%s/archive/%s.zip", $url[0], execute('$url[1]') ? $url[1] : 'master')
        ElseIf IsArray(__SemVer_ConditionParse($info)) Or StringLower($dependency) == 'autoit' Then ; https://github.com/semver/semver/issues/232#issuecomment-405596809
            ConsoleWriteLine('Semver detected. au3pm repository lookup...')
            $url = fetchPackage($dependency, $info)
        Else
            ConsoleWriteLine(StringFormat('Specification in %s is invalid and/or not supported', $dependency))
            ConsoleWriteLine('Exitting...')
            Exit 1
        EndIf

        InstallPackage($url[2], $dependency)
        If @error <> 0 Then
            ConsoleWriteErrorLine(StringFormat("Error occured while installing %s", $dependency))
            Exit 1
        EndIf
        If $lock.Item("packages").Exists($dependency) Then $lock.Item("packages").Remove($dependency)
        $lock.Item("packages").Add($dependency, $url[1])
    Next
    au3pm_lock_save($lock)
Else
    $version = "*"
    If StringRegExp($CmdLine[2], "^[[:alpha:][:digit:]\-\.\_\~]+$", 0) Then
        ConsoleWriteLine("assuming au3pm package")
        $url = fetchPackage($CmdLine[2], ($CmdLine[0] > 2 And Not $CmdLine[3] == "-g") ? $CmdLine[3] : "*")
        If @error = 0 Then
            $dependency = $CmdLine[2]
            $version = $url[1]
        EndIf
    ElseIf StringRegExp($CmdLine[2], "^[[:alpha:][:digit:]\-\.\_\~]+@[\s=v]*(\d+|x|\*)(\.(?:\d+|x|\*)|)(\.(?:\d+|x|\*)|)?\s*(\-[A-Za-z0-9\-\.]+|)\s*(\+[A-Za-z0-9\-\.]+|)\s*$", 0) Then ;FIXME: ranges such as ^3 currently not supported by the regex
        ConsoleWriteLine("assuming au3pm package with specifed semver rule")
        $aPackage = StringRegExp($CmdLine[2], "([^@]+)@([^@]+)", 1)
        $url = fetchPackage($aPackage[0], $aPackage[1])
        $dependency = $aPackage[0]
        $version = $aPackage[1]
    ElseIf StringRegExp($CmdLine[2], "^(([^:\/?#]+):)(\/\/([^\/?#]*))?([^?#]*)(\?([^#]*))?(#(.*))?", 0) Then
        ConsoleWriteLine("assuming direct archive link.")
        ConsoleWriteErrorLine("not yet implemented!")
        Exit 1
    Else
        ConsoleWriteError(StringFormat('Dont know how to handle install parameter: "%s"\n', $CmdLine[2]))
        Exit 1
    EndIf

    If @error <> 0 Then
        ConsoleWriteError("No package found, matching your criteria")
        Exit 1
    EndIf

    ; TODO: use getPackageDependencyTree before installing, to handle dependencies!

    If $dependency == "au3pm" Then
        If Execute("$CmdLine[3]") == "-g" Then
            $path = @LocalAppDataDir&"\au3pm\_au3pm.exe"
            $destination = @LocalAppDataDir&"\au3pm\au3pm.exe"
            If Not FileExists($path) Then DirCreate(_WinAPI_PathRemoveFileSpec($path))
            InetGet($url[2], $path, 16)
            If @error <> 0 Then
                FileDelete($path)
                ConsoleWriteErrorLine(StringFormat("An error occured when getting %s", $dependency))
                Exit 1
            EndIf
            If FileExists($destination) Then
                ConsoleWriteLine(StringFormat("replacing current %s", $dependency))
                ConsoleWriteLine(StringFormat("%s => %s", FileGetVersion($destination), FileGetVersion($path)))
                FileDelete($destination)
                FileMove($path, $destination)
                _WindowsInstaller_registerSoftware()
            Else
                ConsoleWriteLine(StringFormat("installing %s for current user", $dependency))
                FileMove($path, $destination)
                _WindowsInstaller_registerSoftware()
                _au3pm_addCommand()
            EndIf
        EndIf
        ;FIXME: support non -g flag?
        Exit 0
    EndIf

    $au3pm = au3pm_json_load()
    $lock = au3pm_lock_load()

    $originalDependency = $dependency
    $originalVersion = $url[1]
    $originalUrl = $url[2]

    $dependencies = _json_decode('{}')
    $dependencies.Add($dependency, $url[1])
    $resolvedDependencies = getPackageDependencyTree($dependencies)
    ;ConsoleWriteLine(json_stringify($resolvedDependencies))
    $dependencies = $resolvedDependencies

    For $dependency In $dependencies
        ConsoleWrite($dependency&@CRLF)
        $info = $dependencies.Item($dependency)
        If StringRegExp($info, '^([^/]+/.*)(?:#(.*))$') Then
            $url = StringRegExp($info, '^([^/]+/.*?)(?:#(.*))?$', 1)
            ConsoleWriteLine('Github detected.')
            $url = StringFormat("https://github.com/%s/archive/%s.zip", $url[0], execute('$url[1]') ? $url[1] : 'master')
        ElseIf IsArray(__SemVer_ConditionParse($info)) Then ; https://github.com/semver/semver/issues/232#issuecomment-405596809
            ConsoleWriteLine('Semver detected. au3pm repository lookup...')
            $url = fetchPackage($dependency, $info)
        Else
            ConsoleWriteLine(StringFormat('Specification in %s is invalid and/or not supported', $dependency))
            ConsoleWriteLine('Exitting...')
            Exit 1
        EndIf

        InstallPackage($url[2], $dependency)
        If @error <> 0 Then
            ConsoleWriteErrorLine(StringFormat("Error occured while installing %s", $dependency))
            Exit 1
        EndIf
        If $lock.Item("packages").Exists($dependency) Then $lock.Item("packages").Remove($dependency)
        $lock.Item("packages").Add($dependency, $url[1])
    Next
    ;InstallPackage($url[2], $dependency);, False, Execute("$CmdLine[3]") == "-g")
    ;If @error <> 0 Then
    ;    ConsoleWriteErrorLine(StringFormat("Error occured while installing %s", $dependency))
    ;    Exit 1
    ;EndIf
    If $au3pm.Item("dependencies").Exists($originalDependency) Then $au3pm.Item("dependencies").Remove($originalDependency)
    $au3pm.Item("dependencies").Add($originalDependency, $originalVersion)
    ;If $lock.Item("packages").Exists($dependency) Then $lock.Item("packages").Remove($dependency)
    ;$lock.Item("packages").Add($dependency, $url[1])
    au3pm_json_save($au3pm)
    au3pm_lock_save($lock)

    Exit 0
EndIf

#ce
