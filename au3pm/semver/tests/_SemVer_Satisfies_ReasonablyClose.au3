#include "..\SemVer.au3"
#include "libraries\assert.au3"

; Test 1: Higher patch
$a = "1.2.3"
$b = "~1.2.1"

$ret = _SemVer_Satisfies($a, $b)
$err = @error

Assert(0, $err)
Assert(True, $ret)


; Test 2: Lower patch
$a = "1.2.3"
$b = "~1.2.5"

$ret = _SemVer_Satisfies($a, $b)
$err = @error

Assert(0, $err)
Assert(False, $ret)


; Test 3a: Different minor versions
$a = "1.2.3"
$b = "~1.3.0"

$ret = _SemVer_Satisfies($a, $b)
$err = @error

Assert(0, $err)
Assert(False, $ret)


; Test 3b: Different minor versions
$a = "1.3.0-prerelease"
$b = "~1.2.3"

$ret = _SemVer_Satisfies($a, $b)
$err = @error

Assert(0, $err)
Assert(False, $ret)
