#include-once

$json = au3pm_json_load()

If $CmdLine[0] = 1 Then
    ;list available scripts.
    ConsoleWrite('Available scripts:'&@CRLF)
    If $json.Item('scripts').Count = 0 Then
        ConsoleWrite('No scripts available.'&@CRLF)
        Exit 0
    EndIf

    $aKeys = $json.Item('scripts').Keys()
    For $sKey In $aKeys
        ConsoleWrite(' - '&$sKey&@CRLF)
    Next
    Exit 0
EndIf

If Not $json.Item('scripts').Exists($CmdLine[2]) Then
    ConsoleWriteErrorLine(StringFormat('script "%s" does not exist', $CmdLine[2]))
    Exit 0
EndIf

$command = $json.Item('scripts').Item($CmdLine[2])

Exit RunWait(@ComSpec & " /c " & $command)
