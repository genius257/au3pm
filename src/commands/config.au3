#include-once
#include <StringConstants.au3>
#include "../lib/console.au3"

;one of many sub commands under config, needed to verify if the system is working
Func Command_Config()
    $include = RegRead('HKEY_CURRENT_USER\Software\AutoIt v3\AutoIt', "Include");It should be a REG_SZ (string) value
    If @error <> 0 Then ConsoleWriteLine('WARNING: failed to read registry value at "HKEY_CURRENT_USER\Software\AutoIt v3\AutoIt" called "Include"')
    $includes = StringSplit($include, ';', $STR_NOCOUNT)
    $bFound = False
    For $include In $includes
        If Not $include = './au3pm/' Then ContinueLoop
        $bFound = True
        ExitLoop
    Next
    ConsoleWriteLine($bFound ? 'au3pm includes should work with normal #include statement' : 'Missing au3pm include path, needed to use normal #include statements!')
EndFunc
