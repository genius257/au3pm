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

ConsoleWriteLine('AutoIt3 package manager by genius257. Prebuild.')
ConsoleWriteLine('Disclaimer: this is a prebuild. NOTHING is guaranteed to work or be completed at this stage.')
ConsoleWriteLine()

Global $command = $CmdLine[0] > 0 ? $CmdLine[1] : ''
$command = StringLower($command)

Switch ($command)
    Case 'bin'
    Case 'bugs'
    Case 'build'
    Case 'config'
        #include "./commands/config.au3"
    Case 'depricate'
    Case 'edit'
    Case 'get'
    Case 'explore'
    Case 'help', ''
        ConsoleWriteLine('usage: au3pm (command)'&@CRLF)
        ConsoleWriteLine('Where (command) is one of: ')
        ConsoleWriteLine(@TAB & _ArrayToString($commands, ', '))
    Case 'init'
        #include "./commands/init.au3"
    Case 'install'
        #include "./commands/install.au3"
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
