;Double enter bug in user input handling on win8 and up
DllCall("Kernel32.dll", "bool", "FreeConsole")
_WinAPI_AttachConsole()

ConsoleWrite("package name: ")
$input = ConsoleReadLineSync()
ConsoleWriteLine(StringFormat('Input was: "%s"', $input))

Exit 0
