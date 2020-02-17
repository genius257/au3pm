#include-once

$json = au3pm_json_load()

$dependencies = $json.Item('dependencies')
If @error <> 0 Then
    ConsoleWriteLine('no dependencies found in au3pm.json')
    Exit 0
EndIf

For $dependency In $dependencies
    $command = @ScriptFullPath

    $iERROR = RunWait(@ScriptFullPath & " build", @WorkingDir & "\au3pm\" & $dependency)
    If @error <> 0 Then
        ConsoleWriteErrorLine(StringFormat("%s build failed with code: %s", $dependency, $iERROR))
        Exit $iERROR
    EndIf
Next
