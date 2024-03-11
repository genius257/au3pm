#include-once

Func ConsoleWriteLine($data='')
    ConsoleWrite($data&@CRLF)
EndFunc

Func ConsoleWriteErrorLine($data='')
    ConsoleWriteError($data&@CRLF)
EndFunc

Func ConsoleReadLineSync()
    Local $hFile = _WinAPI_CreateFile('CON', 2, 2)
    Local $input = ""
    Local $tBuffer = DllStructCreate('char')
    Local $nRead = 0
    While 1
        _WinAPI_ReadFile($hFile, DllStructGetPtr($tBuffer), 1, $nRead)
        If DllStructGetData($tBuffer, 1) = @CR Then ExitLoop
        If $nRead > 0 Then $input &= DllStructGetData($tBuffer, 1)
    WEnd
    FileClose($hFile)
    Return $input
EndFunc
