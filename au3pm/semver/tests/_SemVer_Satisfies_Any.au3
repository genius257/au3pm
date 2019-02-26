#include "..\SemVer.au3"
#include "libraries\assert.au3"

; Test 1: As Blank
$a = "1.2.1"
$b = ""

$ret = _SemVer_Satisfies($a, $b)
$err = @error

Assert(0, $err)
Assert(True, $ret)

; Test2a: As wildcard *
$a = "1.2.3-prerelease"
$b = "*"

$ret = _SemVer_Satisfies($a, $b)
$err = @error

Assert(0, $err)
Assert(True, $ret)

; Test2b: As wildcard x
$a = "1.2.3"
$b = "x"

$ret = _SemVer_Satisfies($a, $b)
$err = @error

Assert(0, $err)
Assert(True, $ret)
