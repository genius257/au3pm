#include-once

Func isDirectory($sFilePath)
    Return StringInStr(FileGetAttrib($sFilePath), "D") > 0
EndFunc
