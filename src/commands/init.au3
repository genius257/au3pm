#include-once
#include <FileConstants.au3>
#include <WinAPIProc.au3>
#include "../lib/console.au3"

Func Command_Init()
    Local $packagePath = StringFormat("%s\au3pm.json", @WorkingDir)
    If FileExists($packagePath) Then
        ConsoleWriteLine("ERROR: au3pm.json already exists!")
        Return SetError(1)
    EndIf

    ;Double enter bug in user input handling on win8 and up
    DllCall("Kernel32.dll", "bool", "FreeConsole")
    _WinAPI_AttachConsole()

    ConsoleWrite("package name: ")
    Local $name = ConsoleReadLineSync()

    ConsoleWrite("version: ")
    Local $version = ConsoleReadLineSync()
    If $version == "" Then $version = "1.0.0"

    ConsoleWrite("description: ")
    Local $description = ConsoleReadLineSync()

    ConsoleWrite("main file: ")
    Local $main = ConsoleReadLineSync()
    If $main == "" Then $main = "index.au3"

    Local $hFile
    If Not FileExists(@WorkingDir&"\"&$main) Then
        $hFile = FileOpen(@WorkingDir&"\"&$main, $FO_OVERWRITE)
        If @error <> 0 Then
            ConsoleWriteLine(StringFormat('ERROR: failed creating file "%s"', @WorkingDir&"\"&$main))
            Return SetError(1)
        EndIf
        FileClose($hFile)
    EndIf

    $hFile = FileOpen($packagePath, $FO_OVERWRITE + $FO_UTF8)
    If @error <> 0 Then
        ConsoleWriteLine(StringFormat('ERROR: failed creating file "%s"', $packagePath))
        Return SetError(1)
    EndIf

    FileWrite($hFile, StringFormat( _
        '{"name":"%s","version":"%s","description":"%s","main":"%s","scripts":{},"dependencies":{},"devDependencies":{},"bin":{}}', _
        StringRegExpReplace($name, '["\\]', '\$0'), _
        StringRegExpReplace($version, '["\\]', '\$0'), _
        StringRegExpReplace($description, '["\\]', '\$0'), _
        StringRegExpReplace($main, '["\\]', '\$0') _
    ))
    If @error <> 0 Then
        ConsoleWriteLine(StringFormat('ERROR: failed writing to file "%s"', $packagePath))
        FileClose($hFile)
        Return SetError(1)
    EndIf

    FileClose($hFile)

    return SetError(0)
EndFunc
