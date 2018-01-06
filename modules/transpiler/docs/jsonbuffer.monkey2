
Namespace mx2.docs

Class JsonBuffer

	Method Emit( json:String )
	
		If json.StartsWith( "}" ) Or json.StartsWith( "]" )

			_indent=_indent.Slice( 0,-2 )
			_sep=False

			If _blks.Pop()=_buf.Length
			
				_buf.Resize( _buf.Length-1 )
				
				If _buf.Length
					Local t:=_buf.Top
					If Not (t.EndsWith( "{" ) Or t.EndsWith( "[" )) _sep=True
				Endif
				
				Return
			Endif

		Endif
	
		If _sep json=","+json
		_buf.Push( _indent+json )
		_sep=True
	
		If json.EndsWith( "{" ) Or json.EndsWith( "[" ) 

			_blks.Push( _buf.Length )

			_indent+="  "
			_sep=False
		Endif
	
	End
	
	Method Flush:String()
		Local json:=_buf.Join( "~n" )
		_buf.Clear()
		_blks.Clear()
		_indent=""
		_sep=False
		Return json
	End
	
	Private

	Field _buf:=New StringStack
	Field _blks:=New IntStack
	Field _indent:String
	Field _sep:Bool

End

