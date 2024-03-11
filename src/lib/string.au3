#include-once

Func levenshtein($a, $b); source: https://www.autoitscript.com/forum/topic/179886-comparing-strings/
    Local $i, $j, $cost, $d[1], $min1, $min2, $min3

    If StringLen($a) = 0 Then Return StringLen($b)
    If StringLen($b) = 0 Then Return StringLen($a)

    ReDim $d[StringLen($a) + 1][StringLen($b) + 1]

    For $i = 0 To StringLen($a)
        $d[$i][0] = $i
    Next

    For $j = 0 To StringLen($b)
        $d[ 0][$j] = $j
    Next

    For $i = 1 To StringLen($a)
        For $j = 1 To StringLen($b)
            $cost = (StringMid($a, $i, 1) = StringMid($b, $j, 1) ? 0 : 1)

            $min1 = $d[$i - 1][$j] + 1
            $min2 = $d[$i][$j - 1] + 1
            $min3 = $d[$i - 1][$j - 1] + $cost

            If $min1 <= $min2 And $min1 <= $min3 Then
                $d[$i][$j] = $min1
            ElseIf $min2 <= $min1 And $min2 <= $min3 Then
                $d[$i][$j] = $min2
            Else
                $d[$i][$j] = $min3
            EndIf
        Next
    Next

    Return $d[StringLen($a)][StringLen($b)]
EndFunc
