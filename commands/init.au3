;Double enter bug in user input handling on win8 and up
DllCall("Kernel32.dll", "bool", "FreeConsole")
_WinAPI_AttachConsole()

$hFile = _WinAPI_CreateFile('CON', 2, 2)
$input = ""
$tBuffer = DllStructCreate('char')
$nRead = 0
ConsoleWrite("package name: ")
While 1
    _WinAPI_ReadFile($hFile, DllStructGetPtr($tBuffer), 1, $nRead)
    If DllStructGetData($tBuffer, 1) = @CR Then ExitLoop
    If $nRead > 0 Then $input &= DllStructGetData($tBuffer, 1)
WEnd
FileClose($hFile)
ConsoleWrite("Input was: " & '"' & $input & '"' & @CRLF)

Exit 0
