#include <Array.au3>

#cs
# AutoIt3 MD5
# https://github.com/genius257/au3-md5
#
# Copyright 2021, Anders Pedersen
# https://green-tag.dk
#
# Licensed under the MIT license:
# https://opensource.org/licenses/MIT
#
# Based on
# https://github.com/blueimp/JavaScript-MD5
#ce

Func md5($string, $key = Null, $raw = False)
    If Null = $key Then
        If Not $raw Then
            Return hexMD5($string)
        EndIf
        Return rawMD5($string)
    EndIf
    If Not $raw Then
        Return hexHMACMD5($key, $string)
    EndIf
    Return rawHMACMD5($key, $string)
EndFunc

Func hexMD5($s)
    Return rstr2hex(rawMD5($s))
EndFunc

Func rawMD5($s)
    Return rstrMD5(str2rstrUTF8($s))
EndFunc

Func hexHMACMD5($k, $d)
    Return rstr2hex(rawHMACMD5($k, $d))
EndFunc

Func rawHMACMD5($k, $d)
    Return rstrHMACMD5(str2rstrUTF8($k), str2rstrUTF8($d))
EndFunc

Func str2rstrUTF8($input)
    Return BinaryToString(StringToBinary($input, 4), 1)
EndFunc

Func rstr2hex($input)
    Local $hexTab = '0123456789abcdef'
    Local $output = ''
    Local $x
    Local $i
    For $i = 0 To StringLen($input) - 1 Step +1
        $x = Asc(StringMid($input, $i + 1, 1))
        $output &= StringMid($hexTab, BitAND(UnsignedRightShift($x, 4), 0x0f) + 1, 1) & StringMid($hexTab, BitAND($x, 0x0f) + 1, 1)
    Next
    Return $output
EndFunc

Func rstrMD5($s)
    Return binl2rstr(binlMD5(rstr2binl($s), StringLen($s) * 8))
EndFunc

Func rstrHMACMD5($key, $data)
    Local $i
    Local $bkey = rstr2binl($key)
    Local $ipad[16]
    Local $opad[16]
    Local $hash
    $ipad[15] = Default
    $opad[15] = Default
    if (StringLen($bkey) > 16) Then
      $bkey = binlMD5($bkey, StringLen($key) * 8)
    EndIf
    For $i = 0 To 16 - 1 Step +1
        $ipad[$i] = BitXOR(Execute("$bkey[$i]"), 0x36363636)
        $opad[$i] = BitXOR(Execute("$bkey[$i]"), 0x5c5c5c5c)
    Next
    $hash = binlMD5(__ArrayConcatenate($ipad, rstr2binl($data)), 512 + StringLen($data) * 8)
    Return binl2rstr(binlMD5(__ArrayConcatenate($opad, $hash), 512 + 128))
EndFunc

Func rstr2binl($input)
    Local $i
    Local $output[BitShift(StringLen($input) * 8, 5) + 1]
    For $i = 0 To UBound($output) - 1 Step +1
        $output[$i] = 0
    Next
    Local $length8 = StringLen($input) * 8
    For $i = 0 To $length8 - 1 Step +8
        $output[BitShift($i, 5)] = BitOR($output[BitShift($i, 5)], BitShift(BitAND(Asc(StringMid($input, $i / 8 + 1)), 0xff), Mod($i, 32) * -1))
    Next
    return $output
EndFunc

Func binlMD5($x, $len)
    ; append padding
    Redim $x[BitShift($len, 5) + 1] ; FIXME
    $x[BitShift($len, 5)] = BitOR($x[BitShift($len, 5)], BitShift(0x80, Mod($len, 32) * -1))
    Redim $x[BitShift(UnsignedRightShift(($len + 64), 9), 4 * -1) + 14 + 1] ; FIXME
    $x[BitShift(BitShift(($len + 64), 9), 4 * -1) + 14] = $len

    Local $i
    Local $olda
    Local $oldb
    Local $oldc
    Local $oldd
    Local $a = 1732584193
    Local $b = -271733879
    Local $c = -1732584194
    Local $d = 271733878

    For $i = 0 To UBound($x) - 1 Step +16
      $olda = $a
      $oldb = $b
      $oldc = $c
      $oldd = $d

      $a = md5ff($a, $b, $c, $d, $x[$i], 7, -680876936)
      $d = md5ff($d, $a, $b, $c, $x[$i + 1], 12, -389564586)
      $c = md5ff($c, $d, $a, $b, $x[$i + 2], 17, 606105819)
      $b = md5ff($b, $c, $d, $a, $x[$i + 3], 22, -1044525330)
      $a = md5ff($a, $b, $c, $d, $x[$i + 4], 7, -176418897)
      $d = md5ff($d, $a, $b, $c, $x[$i + 5], 12, 1200080426)
      $c = md5ff($c, $d, $a, $b, $x[$i + 6], 17, -1473231341)
      $b = md5ff($b, $c, $d, $a, $x[$i + 7], 22, -45705983)
      $a = md5ff($a, $b, $c, $d, $x[$i + 8], 7, 1770035416)
      $d = md5ff($d, $a, $b, $c, $x[$i + 9], 12, -1958414417)
      $c = md5ff($c, $d, $a, $b, $x[$i + 10], 17, -42063)
      $b = md5ff($b, $c, $d, $a, $x[$i + 11], 22, -1990404162)
      $a = md5ff($a, $b, $c, $d, $x[$i + 12], 7, 1804603682)
      $d = md5ff($d, $a, $b, $c, $x[$i + 13], 12, -40341101)
      $c = md5ff($c, $d, $a, $b, $x[$i + 14], 17, -1502002290)
      $b = md5ff($b, $c, $d, $a, Execute("$x[$i + 15]"), 22, 1236535329)

      $a = md5gg($a, $b, $c, $d, $x[$i + 1], 5, -165796510)
      $d = md5gg($d, $a, $b, $c, $x[$i + 6], 9, -1069501632)
      $c = md5gg($c, $d, $a, $b, $x[$i + 11], 14, 643717713)
      $b = md5gg($b, $c, $d, $a, $x[$i], 20, -373897302)
      $a = md5gg($a, $b, $c, $d, $x[$i + 5], 5, -701558691)
      $d = md5gg($d, $a, $b, $c, $x[$i + 10], 9, 38016083)
      $c = md5gg($c, $d, $a, $b, Execute("$x[$i + 15]"), 14, -660478335)
      $b = md5gg($b, $c, $d, $a, $x[$i + 4], 20, -405537848)
      $a = md5gg($a, $b, $c, $d, $x[$i + 9], 5, 568446438)
      $d = md5gg($d, $a, $b, $c, $x[$i + 14], 9, -1019803690)
      $c = md5gg($c, $d, $a, $b, $x[$i + 3], 14, -187363961)
      $b = md5gg($b, $c, $d, $a, $x[$i + 8], 20, 1163531501)
      $a = md5gg($a, $b, $c, $d, $x[$i + 13], 5, -1444681467)
      $d = md5gg($d, $a, $b, $c, $x[$i + 2], 9, -51403784)
      $c = md5gg($c, $d, $a, $b, $x[$i + 7], 14, 1735328473)
      $b = md5gg($b, $c, $d, $a, $x[$i + 12], 20, -1926607734)

      $a = md5hh($a, $b, $c, $d, $x[$i + 5], 4, -378558)
      $d = md5hh($d, $a, $b, $c, $x[$i + 8], 11, -2022574463)
      $c = md5hh($c, $d, $a, $b, $x[$i + 11], 16, 1839030562)
      $b = md5hh($b, $c, $d, $a, $x[$i + 14], 23, -35309556)
      $a = md5hh($a, $b, $c, $d, $x[$i + 1], 4, -1530992060)
      $d = md5hh($d, $a, $b, $c, $x[$i + 4], 11, 1272893353)
      $c = md5hh($c, $d, $a, $b, $x[$i + 7], 16, -155497632)
      $b = md5hh($b, $c, $d, $a, $x[$i + 10], 23, -1094730640)
      $a = md5hh($a, $b, $c, $d, $x[$i + 13], 4, 681279174)
      $d = md5hh($d, $a, $b, $c, $x[$i], 11, -358537222)
      $c = md5hh($c, $d, $a, $b, $x[$i + 3], 16, -722521979)
      $b = md5hh($b, $c, $d, $a, $x[$i + 6], 23, 76029189)
      $a = md5hh($a, $b, $c, $d, $x[$i + 9], 4, -640364487)
      $d = md5hh($d, $a, $b, $c, $x[$i + 12], 11, -421815835)
      $c = md5hh($c, $d, $a, $b, Execute("$x[$i + 15]"), 16, 530742520)
      $b = md5hh($b, $c, $d, $a, $x[$i + 2], 23, -995338651)

      $a = md5ii($a, $b, $c, $d, $x[$i], 6, -198630844)
      $d = md5ii($d, $a, $b, $c, $x[$i + 7], 10, 1126891415)
      $c = md5ii($c, $d, $a, $b, $x[$i + 14], 15, -1416354905)
      $b = md5ii($b, $c, $d, $a, $x[$i + 5], 21, -57434055)
      $a = md5ii($a, $b, $c, $d, $x[$i + 12], 6, 1700485571)
      $d = md5ii($d, $a, $b, $c, $x[$i + 3], 10, -1894986606)
      $c = md5ii($c, $d, $a, $b, $x[$i + 10], 15, -1051523)
      $b = md5ii($b, $c, $d, $a, $x[$i + 1], 21, -2054922799)
      $a = md5ii($a, $b, $c, $d, $x[$i + 8], 6, 1873313359)
      $d = md5ii($d, $a, $b, $c, Execute("$x[$i + 15]"), 10, -30611744)
      $c = md5ii($c, $d, $a, $b, $x[$i + 6], 15, -1560198380)
      $b = md5ii($b, $c, $d, $a, $x[$i + 13], 21, 1309151649)
      $a = md5ii($a, $b, $c, $d, $x[$i + 4], 6, -145523070)
      $d = md5ii($d, $a, $b, $c, $x[$i + 11], 10, -1120210379)
      $c = md5ii($c, $d, $a, $b, $x[$i + 2], 15, 718787259)
      $b = md5ii($b, $c, $d, $a, $x[$i + 9], 21, -343485551)

      $a = safeAdd($a, $olda)
      $b = safeAdd($b, $oldb)
      $c = safeAdd($c, $oldc)
      $d = safeAdd($d, $oldd)
    Next

    Local $return = [$a, $b, $c, $d]
    Return $return
EndFunc

Func binl2rstr($input)
    Local $i
    Local $output = ''
    Local $length32 = UBound($input) * 32
    For $i = 0 To $length32 - 1 Step +8
        $output &= Chr(BitAND(UnsignedRightShift(Execute("$input[BitShift($i, 5)]"), Mod($i, 32)), 0xff))
    Next
    Return $output
EndFunc

Func md5cmn($q, $a, $b, $x, $s, $t)
    Return safeAdd(bitRotateLeft(safeAdd(safeAdd($a, $q), safeAdd($x, $t)), $s), $b)
EndFunc

Func md5ff($a, $b, $c, $d, $x, $s, $t)
    return md5cmn(BitOR(BitAND($b, $c), (BitAND(BitNOT($b), $d))), $a, $b, $x, $s, $t)
EndFunc

Func md5gg($a, $b, $c, $d, $x, $s, $t)
    return md5cmn(BitOR(BitAND($b, $d), BitAND($c, BitNOT($d))), $a, $b, $x, $s, $t)
EndFunc

Func md5hh($a, $b, $c, $d, $x, $s, $t)
    return md5cmn(BitXOR($b, $c, $d), $a, $b, $x, $s, $t)
EndFunc

Func md5ii($a, $b, $c, $d, $x, $s, $t)
    return md5cmn(BitXOR($c, BitOR($b, BitNOT($d))), $a, $b, $x, $s, $t)
EndFunc

Func safeAdd($x, $y)
    Local $lsw = BitAND($x, 0xffff) + BitAND($y, 0xffff)
    Local $msw = BitShift($x, 16) + BitShift($y, 16) + BitShift($lsw, 16)
    return BitOR(BitShift($msw, 16 * -1), BitAND($lsw, 0xffff))
EndFunc

Func bitRotateLeft($num, $cnt)
    Return BitOR(BitShift($num, $cnt * -1), UnsignedRightShift($num, (32 - $cnt)))
EndFunc

Func UnsignedRightShift($iNum, $iShift)
    If $iShift < 0 Then Return 0
    If $iShift = 0 And $iNum < 0 Then Return 0x100000000 + $iNum
    Return _BitShift($iNum, $iShift)
EndFunc

#cs
# BitShift as Unsigned Integer.
# @see https://www.autoitscript.com/forum/topic/105894-bitshift-as-unsigned-integer/
#ce
Func _BitShift($iNum, $iShift)
    If ($iShift <= -32) Or ($iShift >= 32) Then Return SetError(1, 0, $iNum)
    If $iShift = 0 Then Return $iNum
    If $iShift < 0 Then
        ; left shifts are not affected
        Return BitShift($iNum, $iShift)
    Else
        ; handle right shift of negative number
        ; the magic: remove sign bit, shift, add back top bit in new position
        ;If $iNum < 0 Then Return BitOR(BitShift(BitAND($iNum, 0x7FFFFFFF), $iShift), 2 ^ (31 - $iShift))  ;<--- orig
        If $iNum < 0 Or $iNum > 2147483647 Then Return BitOR(BitShift(BitAND($iNum, 0x7FFFFFFF), $iShift), 2 ^ (31 - $iShift)) ;<--- modified
    EndIf
    Return BitShift($iNum, $iShift)
EndFunc

#cs
# Combines two arrays return the result, without affecting the originals.
#ce
Func __ArrayConcatenate($array1, $array2)
    Local $iSize1 = UBound($array1)
    Redim $array1[UBound($array1) + UBound($array2)]
    
    For $i = UBound($array1) - UBound($array2) To UBound($array1) - 1 Step +1
        $array1[$i] = $array2[$i - $iSize1]
    Next

    Return $array1
EndFunc
