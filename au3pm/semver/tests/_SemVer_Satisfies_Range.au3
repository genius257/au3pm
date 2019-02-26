#include "..\SemVer.au3"
#include "libraries\assert.au3"

$a = "1.2.3"
$b = "1.1.0 - 1.2.5" ; Note that spaces are required around the '-'

$ret = _SemVer_Satisfies($a, $b)
$err = @error

Assert(0, $err)
Assert(True, $ret)
