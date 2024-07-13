#include-once

Func _shlwapi_PathIsURLW($sURL)
    Local $aRet = DllCall("shlwapi.dll", "int", "PathIsURLW", "wstr", $sURL)
    If @error <> 0 Then Return SetError(@error)
    Return $aRet[0]
EndFunc
