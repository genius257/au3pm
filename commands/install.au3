If $CmdLine[0] = 1 Then
    If Not FileExists(@WorkingDir & '\au3pm.json') Then
        ConsoleWriteLine('au3pm.json not found.')
        Exit 0
    EndIf

    $json = FileRead(@WorkingDir & '\au3pm.json')
    $json = json_parse(json_lex($json))[0]
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
        ElseIf IsArray(__SemVer_ConditionParse($info)) Then ; https://github.com/semver/semver/issues/232#issuecomment-405596809
            ConsoleWriteLine('Semver detected. au3pm repository lookup...')
            $url = fetchPackage($dependency, $info)
        Else
            ConsoleWriteLine(StringFormat('Specification in %s is invalid and/or not supported', $dependency))
            ConsoleWriteLine('Exitting...')
            Exit 1
        EndIf

        InstallPackage($url, $dependency)
        If @error <> 0 Then
            ConsoleWriteErrorLine(StringFormat("Error occured while installing %s", $dependency))
            Exit 1
        EndIf
        If $lock.Item("packages").Exists($dependency) Then $lock.Item("packages").Remove($dependency)
        $lock.Item("packages").Add($dependency, $url)
    Next
    au3pm_lock_save($lock)
Else
    $version = "*"
    If StringRegExp($CmdLine[2], "^[a-zA-Z \-_0-9]+$", 0) Then
        ConsoleWriteLine("assuming au3pm package")
        $url = fetchPackage($CmdLine[2], ($CmdLine[0] > 2 And Not $CmdLine[3] == "-g") ? $CmdLine[3] : "*")
        $dependency = $CmdLine[2]
        $version = $CmdLine[0] > 2 And Not $CmdLine[3] == "-g" ? $CmdLine[3] : "*"
    ElseIf StringRegExp($CmdLine[2], "^[a-zA-Z -_0-9]+@[\s=v]*(\d+|x|\*)(\.(?:\d+|x|\*)|)(\.(?:\d+|x|\*)|)?\s*(\-[A-Za-z0-9\-\.]+|)\s*(\+[A-Za-z0-9\-\.]+|)\s*$", 0) Then ;FIXME: ranges such as ^3 currently not supported by the regex
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
            InetGet($url, $path, 16)
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
    InstallPackage($url, $dependency);, False, Execute("$CmdLine[3]") == "-g")
    If @error <> 0 Then
        ConsoleWriteErrorLine(StringFormat("Error occured while installing %s", $dependency))
        Exit 1
    EndIf
    If $au3pm.Item("dependencies").Exists($dependency) Then $au3pm.Item("dependencies").Remove($dependency)
    $au3pm.Item("dependencies").Add($dependency, $version)
    If $lock.Item("packages").Exists($dependency) Then $lock.Item("packages").Remove($dependency)
    $lock.Item("packages").Add($dependency, $url)
    au3pm_json_save($au3pm)
    au3pm_lock_save($lock)

    Exit 0
EndIf
