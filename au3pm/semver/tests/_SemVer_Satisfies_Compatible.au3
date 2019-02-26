#include "..\SemVer.au3"
#include "libraries\assert.au3"

; Test 1: Higher minor
$a = "1.2.3"
$b = "^1.1.1"

$ret = _SemVer_Satisfies($a, $b)
$err = @error

Assert(0, $err)
Assert(True, $ret)


; Test 2: Lower minor
$a = "1.2.3"
$b = "^1.3.5"

$ret = _SemVer_Satisfies($a, $b)
$err = @error

Assert(0, $err)
Assert(True, $ret)


; Test 3a: Different major versions
$a = "1.2.3"
$b = "^3.2.1"

$ret = _SemVer_Satisfies($a, $b)
$err = @error

Assert(0, $err)
Assert(False, $ret)


; Test 4: Next major pre-release
$a = "2.0.0-prerelease"
$b = "^1.2.3"

$ret = _SemVer_Satisfies($a, $b)
$err = @error

Assert(0, $err)
Assert(False, $ret)
