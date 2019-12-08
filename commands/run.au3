#include-once

$json = json_parse(json_lex(FileRead(@WorkingDir&"\au3pm.json")))

$command = $json.Item('scripts').Item($CmdLine[2])

Exit ShellExecuteWait($command)
