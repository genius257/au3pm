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

    HttpSetUserAgent('Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:65.0) Gecko/20100101 Firefox/65.0')
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
    ;folder - symlink in current project
    ;tarball file - 
    ;au3pm regestry
EndIf
