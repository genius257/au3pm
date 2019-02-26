#include "..\SemVer.au3"
#include "libraries\assert.au3"

; Test 1: Greater than
$a = "1.2.5"
$b = ">1.2.3"

$ret = _SemVer_Satisfies($a, $b)
$err = @error

Assert(True, $ret)
Assert(0, $err)

; Test2: Greater than with pre-release
$a = "1.2.3"
$b = ">1.2.3-prerelease"

$ret = _SemVer_Satisfies($a, $b)
$err = @error

Assert(True, $ret)
Assert(0, $err)

; Test3: Greater than with equal versions
$a = "1.2.3"
$b = ">1.2.3"

$ret = _SemVer_Satisfies($a, $b)
$err = @error

Assert(False, $ret)
Assert(0, $err)
