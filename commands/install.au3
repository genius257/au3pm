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

    $tmp = @TempDir & '\' & StringFormat('au3pm %s-%s-%s %s-%s-%s %s', @MDAY, @MON, @YEAR, @HOUR, @MIN, @SEC, @MSEC); & '\'
    DirCreate($tmp)

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

        ConsoleWriteLine('Downloading ' & $info)
        ConsoleWriteLine()
        $tmp_file = _TempFile($tmp, '~')

        InetGet($url, $tmp_file, 16, 0)
        If @error <> 0 Then
            ConsoleWriteLine('Failure downloading. Exitting...')
            Exit 1
        EndIf

        ConsoleWriteLine('Extracting...')

        If RunWait(@ScriptDir & StringFormat('\7za.exe x -y -o"%s" "%s"', $tmp & '\out\', $tmp_file)) <> 0 Then
            ConsoleWriteLine('Failure extracting. Exitting...')
            Exit 1
        EndIf
        If DirMove(_FileListToArray($tmp&'\out\', '*', 2, True)[1], @WorkingDir & '\au3pm\'&$dependency&'\') <> 1 Then
            ConsoleWriteLine('Failure moving extracted content to au3pm folder. Exitting...')
            Exit 1
        EndIf
    Next

    DirRemove($tmp, 1)
Else
    If $CmdLine[0] > 2 Then
        ConsoleWriteLine("currently only up to two arguemnts in install command are supported.")
        Exit 1
    EndIf

    If StringRegExp($CmdLine[2], "^[a-zA-Z \-_0-9]+$", 0) Then
        ConsoleWriteLine("assuming au3pm package")
        $a = fetchPackage($CmdLine[2], $CmdLine[0] > 2 ? $CmdLine[3] : "*")
    ElseIf StringRegExp($CmdLine[2], "^[a-zA-Z -_0-9]+@[\s=v]*(\d+|x|\*)(\.(?:\d+|x|\*)|)(\.(?:\d+|x|\*)|)?\s*(\-[A-Za-z0-9\-\.]+|)\s*(\+[A-Za-z0-9\-\.]+|)\s*$", 0) Then ;FIXME: ranges such as ^3 currently not supported by the regex
        ConsoleWriteLine("assuming au3pm package with specifed semver rule")
        $aPackage = StringRegExp($CmdLine[2], "([^@]+)@([^@]+)", 1)
        $a = fetchPackage($aPackage[0], $aPackage[1])
    ElseIf StringRegExp($CmdLine[2], "^(([^:\/?#]+):)(\/\/([^\/?#]*))?([^?#]*)(\?([^#]*))?(#(.*))?", 0) Then
        ConsoleWriteLine("assuming direct archive link.")
    Else
        ConsoleWriteError(StringFormat('dont know how to handle install parameter: "%s"\n', $CmdLine[2]))
        Exit 1
    EndIf

    If @error <> 0 Then
        ConsoleWriteError("No package found, matching your criteria")
        Exit 1
    EndIf
    ConsoleWrite($a&@CRLF)

    ;$url = fetchPackage($CmdLine[2], "*")
    ;$url = fetchPackage('', $CmdLine[2])
    ;ConsoleWriteLine($url)
    Exit 0
    ;folder - symlink in current project
    ;tarball file
    ;au3pm regestry
EndIf
