
Namespace std.stringio

#rem monkeydoc Checks if a character is whitespace.

Returns true if `char` is 32 or less.

@param chr The character to check.

@return True if `char` is 32 or less.

#end
Function IsSpace:Bool( chr:Int )
	Return chr<=32
End

#rem monkeydoc checks if a character is a decimal digit.

Returns true if `ch` is '0'-'9'.

@param chr The character to check.

@return True if `ch` is '0'-'9'.

#end
Function IsDigit:Bool( chr:Int )
	Return (chr>=48 And chr<58)
End

#rem monkeydoc Checks if a character is alphabetic.

Returns true if `ch` is 'a'-'z' or 'A'-'Z'.

@param chr The character to check.

@return True if `ch` is 'a'-'z' or 'A'-'Z'.

#end
Function IsAlpha:Bool( chr:Int )
	Return (chr>=65 And chr<65+26) Or (chr>=97 And chr<97+26)
End

#rem monkeydoc Checks if a character is an identifier.

Returns true if `ch` is '0'-'9', 'a'-'z', 'A'-'Z' or '_'.

@param chr The character to check.

@return True if `ch` is '0'-'9', 'a'-'z', 'A'-'Z' or '_'.

#end
Function IsIdent:Bool( chr:Int )
	Return (chr>=65 And chr<65+26) Or (chr>=97 And chr<97+26) Or (chr>=48 And chr<58) Or chr=95
End

#rem monkeydoc Checks if a character is a hexadecimal digit.

Returns true if `ch` is '0'-'9', 'a'-'f', or 'A'-'F'.

@param chr The character to check.

@return True if `ch` is '0'-'9', 'a'-'f', or 'A'-'F'.

#end
Function IsHexDigit:Bool( chr:Int )
	Return (chr>=48 And chr<58) Or (chr>=65 And chr<71) Or (chr>=97 And chr<103)
End
