#include "..\SemVer.au3"
#include "libraries\assert.au3"

; Test 1: Basic compare
$a = "1.1.1"

$ret = _SemVer_Compare($a, $a)
$err = @error

Assert(0, $ret)
Assert(0, $err)


; Test 2: Compare with wildcard
$a = "1.2.3"
$b = "1.2.*"


$ret = _SemVer_Compare($a, $b)
$err = @error

Assert(0, $ret)
Assert(0, $err)