#include-once

#cs
# Generate au3pm tmp dir string
#
# @return string
#ce
Func generateTempDir()
    $tmp = @TempDir & '\' & StringFormat('au3pm %s-%s-%s %s-%s-%s %s', @MDAY, @MON, @YEAR, @HOUR, @MIN, @SEC, @MSEC); & '\'
    Return $tmp
EndFunc

Func isDirectory($sFilePath)
    Return StringInStr(FileGetAttrib($sFilePath), "D") > 0
EndFunc
