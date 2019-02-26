#include "..\SemVer.au3"
#include "libraries\assert.au3"

; Test 1a: Simple or
$a = "1.2.1"
$b = "1.2.1 || 1.2.5"

$ret = _SemVer_Satisfies($a, $b)
$err = @error

Assert(0, $err)
Assert(True, $ret)


; Test 1b: Simple or
$a = "1.2.3"
$b = "1.2.1 || 1.2.5"

$ret = _SemVer_Satisfies($a, $b)
$err = @error

Assert(0, $err)
Assert(False, $ret)


; Test 2: OR with ranges
$a = "1.2.3"
$b = "1.1 || 1.2.2 - 1.2.5"

$ret = _SemVer_Satisfies($a, $b)
$err = @error

Assert(0, $err)
Assert(True, $ret)
