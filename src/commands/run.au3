#include-once

Func Command_Run($sName = Null)
    Local $json = au3pm_json_load()

    If $sName = Null Then
        ;list available scripts.
        ConsoleWrite('Available scripts:'&@CRLF)
        If $json.Item('scripts').Count = 0 Then
            ConsoleWrite('No scripts available.'&@CRLF)
            Return SetError(0)
        EndIf

        Local $aKeys = $json.Item('scripts').Keys()
        For $sKey In $aKeys
            ConsoleWrite(' - '&$sKey&@CRLF)
        Next
        Return SetError(0)
    EndIf

    If Not MapExists($json['scripts'], $sName) Then
        ConsoleWriteErrorLine(StringFormat('script "%s" does not exist', $sName))
        Return SetError(0)
    EndIf

    Local $command = $json['scripts'][$sName]

    Return RunWait(@ComSpec & " /c " & $command)
EndFunc