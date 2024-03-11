#include-once

#include '../lib/console.au3'

Func Command_Version()
    Local $version = FileGetVersion(@ScriptFullPath)

    ConsoleWriteLine($version)
EndFunc
