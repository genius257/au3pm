#include "..\SemVer.au3"
#include "libraries\assert.au3"

$a = "1.2.3"
$b = "1.2.3"

$ret = _SemVer_Satisfies($a, $b)
$err = @error

Assert(True, $ret)
Assert(0, $err)
