
Namespace std.base64

Private

Const CHAR_EQUALS:=61

Const encode:=New Int[](
65, 66, 67, 68, 69, 70, 71, 72,
73, 74, 75, 76, 77, 78, 79, 80,
81, 82, 83, 84, 85, 86, 87, 88,
89, 90, 97, 98, 99, 100,101,102,
103,104,105,106,107,108,109,110,
111,112,113,114,115,116,117,118,
119,120,121,122,48, 49, 50, 51,
52, 53, 54, 55, 56, 57, 43, 47 )

Public

#rem monkeydoc Encode binary data to base64 text.
#end
Function EncodeBase64:String( data:UByte Ptr,length:Int )
	
	Local buf:=New Stack<UByte>,tmp:=New UByte[3],i:=0,j:=0
	
	While i<length
		
		tmp[j]=data[i] ; j+=1 ; i+=1
		
		If j=3
			buf.Add( encode[ (tmp[0] & $fc) Shr 2 ] )
			buf.Add( encode[ (tmp[0] & $03) Shl 4 | (tmp[1] & $f0) Shr 4 ] )
			buf.Add( encode[ (tmp[1] & $0f) Shl 2 | (tmp[2] & $c0) Shr 6 ] )
			buf.Add( encode[  tmp[2] & $3f ] )
			j=0
		Endif
	Wend
	
	If j
		tmp[j]=0
		
		buf.Add( encode[ (tmp[0] & $fc) Shr 2 ] )
		buf.Add( encode[ (tmp[0] & $03) Shl 4 | (tmp[1] & $f0) Shr 4 ] )
		If j=2 buf.Add( encode[ (tmp[1] & $0f) Shl 2 | (tmp[2] & $c0) Shr 6 ] )
			
		If j=1 buf.Add( CHAR_EQUALS )
		buf.Add( CHAR_EQUALS )
	Endif
	
	Return String.FromCString( buf.Data.Data,buf.Length )
End

#rem monkeydoc Encode binary data to base64 text.
#end
Function EncodeBase64:String( data:DataBuffer )
	
	Return EncodeBase64( data.Data,data.Length )
End

#rem monkeydoc Decode base64 text to binary data.
#end
Function DecodeBase64:DataBuffer( str:String )
	
	Global decode:Int[]
	
	If Not decode
		decode=New Int[128]
		For Local i:=0 Until 128
			decode[i]=-1
		Next
		For Local i:=0 Until 64
			decode[encode[i]]=i
		Next
	Endif
	
	Local buf:=New Stack<UByte>,tmp:=New Int[4],i:=0,j:=0
	
	While i<str.Length
		
		Local c:=str[i]
		
		If c=CHAR_EQUALS Or c<0 Or c>=decode.Length Or decode[c]=-1 Exit
		
		tmp[j]=decode[c] ; i+=1 ; j+=1
		
		If j=4
			buf.Add(  tmp[0] Shl 2 | (tmp[1] & $30) Shr 4 )
			buf.Add( (tmp[1] & $0f) Shl 4 | (tmp[2] & $3c) Shr 2)
			buf.Add( (tmp[2] & $03) Shl 6 | tmp[3] )
			j=0
		Endif
	Wend
	
	If j
		If j=1 Print "Base64 decode error"
		If j>1 buf.Add( tmp[0] Shl 2 | (tmp[1] & $30) Shr 4)
		If j>2 buf.Add( (tmp[1] & $0f) Shl 4 | (tmp[2] & $3c) Shr 2)
	Endif
	
	Local data:=New DataBuffer( buf.Length )
	
	libc.memcpy( data.Data,buf.Data.Data,buf.Length)
	
	Return data
End
