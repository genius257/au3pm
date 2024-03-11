#include-once

Func Command_Rebuild()
    Local $json = au3pm_json_load()

    Local $dependencies = $json.Item('dependencies')
    If @error <> 0 Then
        ConsoleWriteLine('no dependencies found in au3pm.json')
        Return SetError(0)
    EndIf

    For $dependency In $dependencies
        Local $command = @ScriptFullPath

        Local $iERROR = RunWait(@ScriptFullPath & " build", @WorkingDir & "\au3pm\" & $dependency)
        If @error <> 0 Then
            ConsoleWriteErrorLine(StringFormat("%s build failed with code: %s", $dependency, $iERROR))
            Return SetError($iERROR)
        EndIf
    Next
EndFunc
