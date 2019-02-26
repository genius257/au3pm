#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Outfile=bin\au3pm.exe
#AutoIt3Wrapper_Outfile_x64=bin\au3pm_x64.exe
#AutoIt3Wrapper_UseX64=n
#AutoIt3Wrapper_Change2CUI=y
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****

#include <WinAPIFiles.au3>
#include <File.au3>
#include <Array.au3>

#include "au3pm\au3json\json.au3"
#include "au3pm\semver\SemVer.au3"

;FIXME: support au3pm-lock.yaml

Global $commands = [ _
    'bin', _
    'bugs', _
    'build', _
    'config', _
    'depricate', _
    'edit', _
    'get', _
    'explore', _
    'help', _
    'init', _
    'install', _
    'list', _
    'owner', _
    'pack', _
    'rebuild', _
    'restart', _
    'start', _
    'stop', _
    'test', _
    'uninstall', _
    'update', _
    'version' _
]

ConsoleWriteLine('AutoIt package manager by genius257. Prebuild.')
ConsoleWriteLine('Disclaimer: this is a prebuild. NOTHING is guaranteed to work or be completed at this stage.')
ConsoleWriteLine()

Global $command = $CmdLine[0] > 0 ? $CmdLine[1] : ''
$command = StringLower($command)

Switch ($command)
    Case 'bin'
    Case 'bugs'
    Case 'build'
    Case 'config'
        ;one of many sub commands under config, needed to verify if the system is working
        $include = RegRead('HKEY_CURRENT_USER\Software\AutoIt v3\AutoIt', "Include");It should be a REG_SZ (string) value
        If @error <> 0 Then ConsoleWriteLine('WARNING: failed to read registry value at "HKEY_CURRENT_USER\Software\AutoIt v3\AutoIt" called "Include"')
        $includes = StringSplit($include, ';', 2)
        $bFound = False
        For $include In $includes
            If Not $include = './au3pm/' Then ContinueLoop
            $bFound = True
            ExitLoop
        Next
        ConsoleWriteLine($bFound ? 'au3pm includes should work with normal #include statement' : 'Missing au3pm include path, needed to use normal #include statements!')
    Case 'depricate'
    Case 'edit'
    Case 'get'
    Case 'explore'
    Case 'help', ''
        ConsoleWriteLine('usage: au3pm (command)'&@CRLF)
        ConsoleWriteLine('Where (command) is one of: ')
        ConsoleWriteLine(@TAB & _ArrayToString($commands, ', '))
    Case 'init'
        $hFile = _WinAPI_CreateFile('CON', 2, 2)
        $input = ""
        $tBuffer = DllStructCreate('char')
        $nRead = 0
        ConsoleWrite("input: ")
        While 1
            _WinAPI_ReadFile($hFile, DllStructGetPtr($tBuffer), 1, $nRead)
            If DllStructGetData($tBuffer, 1) = @CR Then ExitLoop
            If $nRead > 0 Then $input &= DllStructGetData($tBuffer, 1)
        WEnd
        FileClose($hFile)
        ConsoleWrite("Input was: " & '"' & $input & '"' & @CRLF)
        Exit 0
    Case 'install'
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
                ;FIXME: support ranges like: 1.0.0 - 2.0.0
                ElseIf IsArray(__SemVer_ConditionParse($info)) Then ; https://github.com/semver/semver/issues/232#issuecomment-405596809
                    ConsoleWriteLine('Semver detected. au3pm repository lookup...')
                    ;TODO
                    ContinueLoop
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
    Case 'list'
    Case 'owner'
    Case 'pack'
    Case 'rebuild'
    Case 'restart'
    Case 'start'
    Case 'stop'
    Case 'test'
    Case 'uninstall'
    Case 'update'
    Case Else
        ConsoleWriteLine(StringFormat('The command %s is not supported.', $command))
        Local $match
        Local $p, $q
        $p = levenshtein($command, $commands[0])
        $match = $commands[0]
        For $c In $commands
            $q = levenshtein($command, $c)
            If $q < $p Then
                $match = $c
                $p = $q
            EndIf
        Next
        ConsoleWriteLine(@CRLF&"Did you mean: "&$match)
EndSwitch

Func ConsoleWriteLine($data='')
    ConsoleWrite($data&@CRLF)
EndFunc

Func levenshtein( $a, $b ); source: https://www.autoitscript.com/forum/topic/179886-comparing-strings/
    Local $i, $j, $cost, $d[1], $min1, $min2, $min3

    If StringLen( $a ) = 0 Then Return StringLen( $b )
    If StringLen( $b ) = 0 Then Return StringLen( $a )

    ReDim $d[ StringLen( $a ) + 1][ StringLen( $b ) + 1]

    For $i = 0 To StringLen( $a )
        $d[$i][0] = $i
    Next

    For $j = 0 To StringLen( $b )
        $d[ 0][$j] = $j
    Next

    For $i = 1 To StringLen( $a )
        For $j = 1 To StringLen( $b )
            $cost =  ( StringMid($a, $i, 1) = StringMid($b, $j, 1) ? 0 : 1)

            $min1 = $d[$i - 1][$j] + 1
            $min2 = $d[$i][$j - 1] + 1
            $min3 = $d[$i - 1][$j - 1] + $cost

            If $min1 <= $min2 And $min1 <= $min3 Then
                $d[$i][$j] = $min1
            ElseIf $min2 <= $min1 And $min2 <= $min3 Then
                $d[$i][$j] = $min2
            Else
                $d[$i][$j] = $min3
            EndIf
        Next
    Next

    Return $d[StringLen( $a )][StringLen( $b )]
EndFunc
