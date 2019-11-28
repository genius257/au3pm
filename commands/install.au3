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

    ConsoleWriteLine('Clearing dependency folder'&@CRLF)
    DirRemove(@WorkingDir & '\au3pm\', 1)
    DirCreate(@WorkingDir & '\au3pm\')

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
    Next
Else
    If $CmdLine[0] > 2 Then
        ConsoleWriteLine("currently only up to two arguemnts in install command are supported.")
        Exit 1
    EndIf

    If StringRegExp($CmdLine[2], "^[a-zA-Z \-_0-9]+$", 0) Then
        ConsoleWriteLine("assuming au3pm package")
        $url = fetchPackage($CmdLine[2], $CmdLine[0] > 2 ? $CmdLine[3] : "*")
        $dependency = $CmdLine[2]
    ElseIf StringRegExp($CmdLine[2], "^[a-zA-Z -_0-9]+@[\s=v]*(\d+|x|\*)(\.(?:\d+|x|\*)|)(\.(?:\d+|x|\*)|)?\s*(\-[A-Za-z0-9\-\.]+|)\s*(\+[A-Za-z0-9\-\.]+|)\s*$", 0) Then ;FIXME: ranges such as ^3 currently not supported by the regex
        ConsoleWriteLine("assuming au3pm package with specifed semver rule")
        $aPackage = StringRegExp($CmdLine[2], "([^@]+)@([^@]+)", 1)
        $url = fetchPackage($aPackage[0], $aPackage[1])
        $dependency = $aPackage[0]
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

    InstallPackage($url, $dependency)
    If @error <> 0 Then
        ConsoleWriteErrorLine(StringFormat("Error occured while installing %s", $dependency))
        Exit 1
    EndIf

    Exit 0
    ;folder - symlink in current project
    ;tarball file
    ;au3pm regestry
EndIf
