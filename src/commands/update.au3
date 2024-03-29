$json = au3pm_json_load()
$lock = au3pm_lock_load()

Func Command_Update($sPackage = Null)
    If $sPackage = Null Then
        $dependencies = $json.Item('dependencies')
        If @error <> 0 Then
            ConsoleWriteLine('no dependencies found in au3pm.json')
            Return SetError(0)
        EndIf

        $resolvedDependencies = getPackageDependencyTree($dependencies)
        $dependencies = $resolvedDependencies

        ;FIXME: add function to download and install package

        For $dependency In $dependencies
            If _SemVer_Gte($lock.Item("packages").Item($dependency), $dependencies.Item($dependency)) Then
                ConsoleWriteLine(StringFormat("[%s] old >= new, no upgrade needed", $dependency))
                ContinueLoop
            ;Else
                ;ConsoleWriteLine(StringFormat('[%s] should be upgraded', $dependency))
                ;ContinueLoop
            EndIf
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
                Return SetError(1)
            EndIf

            InstallPackage($url[2], $dependency)
            If @error <> 0 Then
                ConsoleWriteErrorLine(StringFormat("Error occured while installing %s", $dependency))
                Return SetError(1)
            EndIf
            If $lock.Item("packages").Exists($dependency) Then $lock.Item("packages").Remove($dependency)
            $lock.Item("packages").Add($dependency, $url[1])
        Next

        au3pm_lock_save($lock)
        Return SetError(0)
    EndIf

    $dependency = $CmdLine[2]

    $dependencies = $json.Item('dependencies')
    if Not $dependencies.Exists($dependency) Then
        ConsoleWriteErrorLine(StringFormat('dedpendency "%s" not found in au3pm.json', $dependency))
        Return SetError(1)
    EndIf
    $version = $dependencies.Item($dependency)
    $dependencies = _json_decode('{}')
    $dependencies.Add($dependency, $version)

    $resolvedDependencies = getPackageDependencyTree($dependencies)
    $dependencies = $resolvedDependencies

    For $dependency In $dependencies
        If _SemVer_Gte($lock.Item("packages").Item($dependency), $dependencies.Item($dependency)) Then
            ConsoleWriteLine(StringFormat("[%s] old >= new, no upgrade needed", $dependency))
            ContinueLoop
        EndIf
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
            Return SetError(1)
        EndIf

        InstallPackage($url[2], $dependency)
        If @error <> 0 Then
            ConsoleWriteErrorLine(StringFormat("Error occured while installing %s", $dependency))
            Return SetError(1)
        EndIf
        If $lock.Item("packages").Exists($dependency) Then $lock.Item("packages").Remove($dependency)
        $lock.Item("packages").Add($dependency, $url[1])
    Next

    au3pm_lock_save($lock)
    Return SetError(0)
EndFunc
