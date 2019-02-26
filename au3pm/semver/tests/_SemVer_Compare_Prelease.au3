#include "..\SemVer.au3"
#include "libraries\assert.au3"

$a = "1.3.0-prerelease"
$b = "1.2.*"

$ret = _SemVer_Compare($a, $b)
$err = @error

Assert(1, $ret)
Assert(0, $err)