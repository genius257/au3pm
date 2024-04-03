#include "md5.au3"

#Region MD5 Hex-encoding
; should create a hex-encoded MD5 hash of an ASCII value
$expected = "2063c1608d6e0baf80249c42e2be5804"
$time = TimerInit()
$actual = md5('value')
If Not ($expected == $actual) Then ConsoleWrite(StringFormat("%s:\n\t%s\n\t%s\n", @ScriptLineNumber, $expected, $actual))

; should create a hex-encoded MD5 hash of an UTF-8 value
$expected = "4dbed2e657457884e67137d3514119b3"
$actual = md5('日本')
If Not ($expected == $actual) Then ConsoleWrite(StringFormat("%s:\n\t%s\n\t%s\n", @ScriptLineNumber, $expected, $actual))
#EndRegion

#Region HMAC-MD5 Hex-encoding
; should create a hex-encoded HMAC-MD5 hash of an ASCII value and key
$expected = "01433efd5f16327ea4b31144572c67f6"
$actual = md5('value', 'key')
If Not ($expected == $actual) Then ConsoleWrite(StringFormat("%s:\n\t%s\n\t%s\n", @ScriptLineNumber, $expected, $actual))

; should create a hex-encoded HMAC-MD5 hash of an UTF-8 value and key
$expected = "c78b8c7357926981cc04740bd3e9d015"
$actual = md5('日本', '日本')
If Not ($expected == $actual) Then ConsoleWrite(StringFormat("%s:\n\t%s\n\t%s\n", @ScriptLineNumber, $expected, $actual))
#EndRegion

#Region MD5 raw encoding
; should create a raw MD5 hash of an ASCII value
$expected = BinaryToString(Binary("0x2063C1608D6E0BAF80249C42E2BE5804"), 1) ; ' c\xc1`\x8dn\x0b\xaf\x80$\x9cB\xe2\xbeX\x04'
$actual = md5('value', null, true)
If Not ($expected == $actual) Then ConsoleWrite(StringFormat("%s:\n\t%s\n\t%s\n", @ScriptLineNumber, $expected, $actual))

; should create a raw MD5 hash of an UTF-8 value
$expected = BinaryToString(Binary("0x4DBED2E657457884E67137D3514119B3"), 1) ; 'M\xbe\xd2\xe6WEx\x84\xe6q7\xd3QA\x19\xb3'
$actual = md5('日本', null, true)
If Not ($expected == $actual) Then ConsoleWrite(StringFormat("%s:\n\t%s\n\t%s\n", @ScriptLineNumber, $expected, $actual))
#EndRegion

#Region HMAC-MD5 raw encoding
; should create a raw HMAC-MD5 hash of an ASCII value and key
$expected = BinaryToString(Binary('0x01433EFD5F16327EA4B31144572C67F6'), 1) ; '\x01C>\xfd_\x162~\xa4\xb3\x11DW,g\xf6'
$actual = md5('value', 'key', true)
If Not ($expected == $actual) Then ConsoleWrite(StringFormat("%s:\n\t%s\n\t%s\n", @ScriptLineNumber, $expected, $actual))

; should create a raw HMAC-MD5 hash of an UTF-8 value and key
$expected = BinaryToString(Binary('0xC78B8C7357926981CC04740BD3E9D015')) ; '\xc7\x8b\x8csW\x92i\x81\xcc\x04t\x0b\xd3\xe9\xd0\x15'
$actual = md5('日本', '日本', true)
If Not ($expected == $actual) Then ConsoleWrite(StringFormat("%s:\n\t%s\n\t%s\n", @ScriptLineNumber, $expected, $actual))
#EndRegion
