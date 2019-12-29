#include-once

$json = au3pm_json_load()

$command = $json.Item('scripts').Item($CmdLine[2])

Exit ShellExecuteWait($command)
