#include "..\SemVer.au3"
#include "libraries\assert.au3"

$a = "2.1.1"
$b = "1.1.1"

$ret = _SemVer_Compare($a, $b)
$err = @error

Assert(1, $ret)
Assert(0, $err)

$ret = _SemVer_Compare($b, $a)
$err = @error

Assert(-1, $ret)
Assert(0, $err)