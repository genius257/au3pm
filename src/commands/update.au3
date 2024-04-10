#include-once
#include "../lib/console.au3"
#include "../../au3pm/semver/SemVer.au3"

$json = au3pm_json_load()
$lock = au3pm_lock_load()

Func Command_Update($sPackage = Null)
    If $sPackage = Null Then
        $dependencies = $json['dependencies']
        If @error <> 0 Then
            ConsoleWriteLine('no dependencies found in au3pm.json')
            Return SetError(0)
        EndIf

        $resolvedDependencies = getPackageDependencyTree($dependencies)
        $dependencies = $resolvedDependencies

        ;FIXME: add function to download and install package

        For $dependency In $dependencies
            If _SemVer_Gte($lock["packages"][$dependency], $dependencies[$dependency]) Then
                ConsoleWriteLine(StringFormat("[%s] old >= new, no upgrade needed", $dependency))
                ContinueLoop
            ;Else
                ;ConsoleWriteLine(StringFormat('[%s] should be upgraded', $dependency))
                ;ContinueLoop
            EndIf
            $info = $dependencies[$dependency]
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
                Return SetError(1)
            EndIf

            InstallPackage($url[2], $dependency)
            If @error <> 0 Then
                ConsoleWriteErrorLine(StringFormat("Error occured while installing %s", $dependency))
                Return SetError(1)
            EndIf
            If MapExists($lock["packages"], $dependency) Then MapRemove($lock["packages"], $dependency)
            $lock["packages"][$dependency] = $url[1]
        Next

        au3pm_lock_save($lock)
        Return SetError(0)
    EndIf

    $dependency = $CmdLine[2]

    $dependencies = $json['dependencies']
    if Not $dependencies.Exists($dependency) Then
        ConsoleWriteErrorLine(StringFormat('dedpendency "%s" not found in au3pm.json', $dependency))
        Return SetError(1)
    EndIf
    $version = $dependencies[$dependency]
    $dependencies = _json_decode('{}')
    $dependencies[$dependency] = $version

    $resolvedDependencies = getPackageDependencyTree($dependencies)
    $dependencies = $resolvedDependencies

    For $dependency In $dependencies
        If _SemVer_Gte($lock["packages"][$dependency], $dependencies[$dependency]) Then
            ConsoleWriteLine(StringFormat("[%s] old >= new, no upgrade needed", $dependency))
            ContinueLoop
        EndIf
        $info = $dependencies[$dependency]
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
            Return SetError(1)
        EndIf

        InstallPackage($url[2], $dependency)
        If @error <> 0 Then
            ConsoleWriteErrorLine(StringFormat("Error occured while installing %s", $dependency))
            Return SetError(1)
        EndIf
        If MapExists($lock["packages"], $dependency) Then MapRemove($lock["packages"], $dependency)
        $lock["packages"][$dependency] = $url[1]
    Next

    au3pm_lock_save($lock)
    Return SetError(0)
EndFunc
