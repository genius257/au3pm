#include-once

$json = au3pm_json_load()

If Not $json.Item('scripts').Exists($CmdLine[2]) Then
    ConsoleWriteErrorLine(StringFormat('script "%s" does not exist', $CmdLine[2]))
    Exit 0
EndIf

$command = $json.Item('scripts').Item($CmdLine[2])

Exit ShellExecuteWait($command)
