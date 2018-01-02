
#rem monkeydoc

JSON (JavaScript Object Notation) is a lightweight data-interchange format.

To load a json object from a file, use the [[JsonObject.Load]] function.

To convert a string to a json object, use the [[JsonObject.Parse]] function.

To convert a json object to a string, use the [[JsonObject.ToString]] method.

You can inspect the members of a json object using methods such as [[JsonObject.GetString]], [[JsonObject.GetNumber]] etc.

You can modify the members of a json object using methods such as [[JsonObject.SetString]], [[JsonObject.SetNumber]] etc.

#end
Namespace std.json

#rem monkeydoc JsonError class.
#end
Class JsonError Extends Throwable
	
End

#rem monkeydoc JsonValue class.

This is base class of all JsonValue types.

#end
Class JsonValue

	Const NullValue:=New JsonValue

	#rem monkeydoc True if value is null.
	#end
	Property IsNull:Bool()
		Return Self=NullValue
	End

	#rem monkeydoc True if value is a bool.
	#end
	Property IsBool:Bool() Virtual
		Return False
	End
	
	#rem monkeydoc True if value is a number.
	#end
	Property IsNumber:Bool() Virtual
		Return False
	End
	
	#rem monkeydoc True if value is a string.
	#end
	Property IsString:Bool() Virtual
		Return False
	End
	
	#rem monkeydoc True if value is an array.
	#end
	Property IsArray:Bool() Virtual
		Return False
	End
	
	#rem monkeydoc True if value is an object.
	#end
	Property IsObject:Bool() Virtual
		Return False
	End

	#rem monkeydoc Gets bool value.
	
	If the value is a bool, returns its actual value.
	
	If the value is not a bool, false is returned by default.
	
	#end	
	Method ToBool:Bool() Virtual
		Return False
	End
	
	#rem monkeydoc Gets number value.
	
	If the value is a number, returns its actual value.
	
	If the value is not a number, 0 is returned by default.
	
	#end	
	Method ToNumber:Double() Virtual
		Return 0
	End
	
	#rem monkeydoc Gets string value.
	
	If the value is a string, returns its actual value.
	
	If the value is not a string, "" is returned by default.
	
	#end	
	Method ToString:String() Virtual
		Return ""
	End
	
	#rem monkeydoc Gets array value.
	
	If the value is an array, returns its actual value in the form of a Stack<JsonValue> object.
	
	If the value is not an array, null is returned by default.
	
	#end	
	Method ToArray:Stack<JsonValue>() Virtual
		Return Null
	End
	
	#rem monkeydoc Gets object value.
	
	If the value is an object, returns its actual value in the form of a StringMap<JsonValue> object.
	
	If the value is not an object, null is returned by default.
	
	#end	
	Method ToObject:StringMap<JsonValue>() Virtual
		Return Null
	End
	
	#rem monkeydoc Converts the value to a JSON string.
	#end	
	Method ToJson:String() Virtual
		Local buf:=New StringStack
		PushJson( buf )
		Return buf.Join( "" )
	End
	
	#rem monkeydoc Saves the value as a JSON string to a file.
	#end
	Method Save:Bool( path:String )
	
		Local buf:=New StringStack
		PushJson( buf )
		
		Local src:=buf.Join( "" )
		Return stringio.SaveString( src,path )
	End
	
	#rem monkeydoc Load the value from a JSON string stored in a file.
	#end
	Function Load:JsonValue( path:String,throwex:Bool=False )
	
		Local src:=stringio.LoadString( path )
		If Not src Return Null
		
		Return Parse( src,throwex )
	End
	
	#rem monkeydoc Creates a JSONValue from a JSON string.
	
	Returns null if the json could not be parsed.
	
	#end
	Function Parse:JsonValue( src:String,throwex:Bool=False )
		Try
			Local parser:=New JsonParser( src )
			Return parser.ParseValue()
		Catch ex:JsonError
			If throwex Throw ex
		End
		Return Null
	End
	
	Protected
	
	Global _indent:String
	
	#rem monkeydoc @hidden
	#end
	Method New()
	End
	
	#rem monkeydoc @hidden
	#end
	Method PushJson:Void( buf:StringStack ) Virtual
		buf.Push( ToJson() )
	End
	
End

#rem monkeydoc JsonBool class.
#end
Class JsonBool Extends JsonValue

	Const TrueValue:JsonBool=New JsonBool( True )
	
	Const FalseValue:JsonBool=New JsonBool( False )

	Method New( data:Bool=False )
		_data=data
	End
	
	#rem monkeydoc @hidden Deprecated!
	#end
	Property Data:Bool()
		Return _data
	Setter( data:Bool )
		_data=data
	End
	
	Property IsBool:Bool() Override
		Return True
	End
	
	Method ToBool:Bool() Override
		Return _data
	End
	
	#rem monkeydoc @hidden Deprecated!
	#end
	Method ToNumber:Double() Override
		Return _data
	End
	
	#rem monkeydoc @hidden Deprecated!
	#end
	Method ToString:String() Override
		Return _data ? "true" Else "false"
	End
	
	Method ToJson:String() Override
		If _data Return "true"
		Return "false"
	End

	Private
	
	Field _data:Bool
End

#rem monkeydoc JsonNumber class.
#end
Class JsonNumber Extends JsonValue

	Method New( data:Double=0 )
		_data=data
	End
	
	#rem monkeydoc @hidden Deprecated!
	#end
	Property Data:Double()
		Return _data
	Setter( data:Double )
		_data=data
	End
	
	Property IsNumber:Bool() Override
		Return True
	End
	
	Method ToNumber:Double() Override
		Return _data
	End
	
	#rem monkeydoc @hidden Deprecated!
	#end
	Method ToBool:Bool() Override
		Return _data
	End
	
	#rem monkeydoc @hidden Deprecated!
	#end
	Method ToString:String() Override
		Return _data
	End
	
	Method ToJson:String() Override
		Return String( _data )
	End

	Private
	
	Field _data:Double
End

#rem monkeydoc JsonString class.
#end
Class JsonString Extends JsonValue

	Method New( data:String="" )
		_data=data
	End
	
	#rem monkeydoc @hidden Deprecated!
	#end
	Property Data:String()
		Return _data
	Setter( data:String )
		_data=data
	End

	Property IsString:Bool() Override
		Return True
	End
		
	Method ToString:String() Override
		Return _data
	End
	
	#rem monkeydoc @hidden Deprecated!
	#end
	Method ToBool:Bool() Override
		Return _data
	End
	
	#rem monkeydoc @hidden Deprecated!
	#end
	Method ToNumber:Double() Override
		Return Double( _data )
	End
	
	Method ToJson:String() Override
		Local data:=_data
		data=data.Replace( "\","\\" )
		data=data.Replace( "~q","\~q" )
		data=data.Replace( "~n","\n" ).Replace( "~r","\r" ).Replace( "~t","\t" )
		Return "~q"+data+"~q"
	End

	Private
	
	Field _data:String
End

#rem monkeydoc JsonArray class.
#end
Class JsonArray Extends JsonValue

	Method New( length:Int=0 )
		_data=New Stack<JsonValue>( length )
	End

	Method New( data:JsonValue[] )
		_data=New Stack<JsonValue>( data )
	End
	
	Method New( data:Stack<JsonValue> )
		_data=data
	End
	
	#rem monkeydoc @hidden Deprecated!
	#end
	Property Data:Stack<JsonValue>()
		Return _data
	Setter( data:Stack<JsonValue> )
		_data=data
	End
	
	#rem monkeydoc Returns true.
	#end
	Property IsArray:Bool() Override
		Return True
	End
	
	#rem monkeydoc Gets the internal stack used to store the array.
	#end
	Method ToArray:Stack<JsonValue>() Override
		Return _data
	End
	
	#rem monkeydoc Gets an array element.
	
	Returns the json value at `index`.
	
	@param index Array index.
	
	#end
	Method GetValue:JsonValue( index:int )
		Assert( index>=0 And index<_data.Length )
		
		Return _data[index]
	End
	
	#rem monkeydoc Gets a bool array element.
	
	Returns the bool value at `index`, or false if `index` is out of range or the value at `index` is not a bool.
	
	@param index Array index.
	
	#end
	Method GetBool:Bool( index:int )
		Local value:=GetValue( index )
		If value Return value.ToBool()
		Return False
	End
	
	#rem monkeydoc Gets a numeric array element.
	
	Returns the numeric value at `index`, or 0 if `index` is out of range or the value at `index` is not numeric.
	
	@param index Array index.
	
	#end
	Method GetNumber:Double( index:int )
		Local value:=GetValue( index )
		If value Return value.ToNumber()
		Return 0
	End
	
	#rem monkeydoc Gets a string array element.

	Returns the string value at `index`, or an empty string if `index` is out of range or the value at `index` is not a string.
	
	@param index Array index.
	
	#end
	Method GetString:String( index:Int )
		Local value:=GetValue( index )
		If value Return value.ToString()
		Return ""
	End
	
	#rem monkeydoc Gets an array array element.
	
	Returns the array at `index`, or null if `index` is out of range or the value at `index` is not an array.
	
	@param index Array index.
	
	#end
	Method GetArray:JsonArray( index:int )
		Return Cast<JsonArray>( GetValue( index ) )
	End
	
	#rem monkeydoc Gets an object array element.

	Returns the object at `index`, or null if `index` is out of range or the value at `index` is not an object.
	
	@param index Array index.
	
	#end
	Method GetObject:JsonObject( index:Int )
		Return Cast<JsonObject>( GetValue( index ) )
	End
	
	#rem monkeydoc Sets an array element.
	
	Sets the json value at `index` to `value`.
	
	@param index Array index.
	
	@param value Value to set.
	
	#end
	Method SetValue( index:Int,value:JsonValue )
		Assert( index>=0 And index<_data.Length )
		
		_data[index]=value
	End
	
	#rem monkeydoc Sets an array element.
	
	Sets the json value at `index` to `value`.
	
	@param index Array index.
	
	@param value Value to set.
	
	#end
	Method SetBool( index:Int,value:Bool )
		SetValue( index,value ? JsonBool.TrueValue Else JsonBool.FalseValue )
	End
	
	#rem monkeydoc Sets an array element.
	
	Sets the json value at `index` to `value`.
	
	@param index Array index.
	
	@param value Value to set.
	
	#end
	Method SetNumber( index:int,value:Double )
		SetValue( index,New JsonNumber( value ) )
	End
	
	#rem monkeydoc Sets an array element.
	
	Sets the json value at `index` to `value`.
	
	@param index Array index.
	
	@param value Value to set.
	
	#end
	Method SetString( index:Int,value:String )
		SetValue( index,New JsonString( value ) )
	End
	
	#rem monkeydoc Sets an array element.
	
	Sets the json value at `index` to `value`.
	
	@param index Array index.
	
	@param value Value to set.
	
	#end
	Method SetArray( index:int,value:JsonValue[] )
		SetValue( index,New JsonArray( value ) )
	End
	
	Method SetArray( index:int,value:Stack<JsonValue> )
		SetValue( index,New JsonArray( value ) )
	End
	
	#rem monkeydoc Sets an array element.
	
	Sets the json value at `index` to `value`.
	
	@param index Array index.
	
	@param value Value to set.
	
	#end
	Method SetObject( index:Int,value:StringMap<JsonValue> )
		SetValue( index,New JsonObject( value ) )
	End
	
	#rem monkeydoc True if array is empty.
	#end
	Property Empty:Bool()
		Return _data.Empty
	End
	
	#rem monkeydoc Length of the array.
	#end
	Property Length:Int()
		Return _data.Length
	End

	#rem monkeydoc Gets the json value at an index.	
	
	Returns the json value at `index`, or null if `index` is out of range.
	
	@param index The index.
	
	@return The json value at `index`.
	
	#end
	Operator[]:JsonValue( index:Int )
		If index<0 Or index>=_data.Length Return null
		Return _data[index]
	End
	
	#rem monkeydoc Sets the json value at an index.	
	
	Sets the json value at `index` to `value`, or does nothing  if `index` is out of range.
	
	@param index The index.
	
	@param value The json value to store at `index`.
	
	#end
	Operator[]=( index:Int,value:JsonValue )
		If index<0 Or index>=_data.Length Return
		DebugAssert( index>=0 )
		
		If index>=_data.Length _data.Resize( index+1 )
		_data[index]=value
	End
	
	#rem monkeydoc Gets an iterator to all json values in the array.
	#end
	Method All:Stack<JsonValue>.Iterator()
		Return _data.All()
	End

	#rem monkeydoc Adds a json value to the array.
	
	@param value The json value to add.
	
	#end
	Method Push( value:JsonValue )
		_data.Push( value )
	End
	
	#rem monkeydoc @hidden
	#end
	Method Add( value:JsonValue )
		_data.Add( value )
	End
	
	Private
	
	Field _data:Stack<JsonValue>
	
	Method PushJson:Void( buf:StringStack ) Override
	
		buf.Push( "[" )
		
		Local indent:=_indent
		
		Local n:=0
		
		For Local value:=Eachin _data
		
			If n 
				buf.Push( "," )
			Endif
			n+=1
			
			If value
				buf.Push( value.ToJson() )
			Else
				buf.Push( "null" )
			Endif
			
		Next
		
		_indent=indent

		buf.Push( "]" )
	End
	
End

#rem monkeydoc JsonObject class.
#end
Class JsonObject Extends JsonValue

	Method New( data:StringMap<JsonValue> =Null )
		If Not data data=New StringMap<JsonValue>
		_data=data
	End
	
	#rem monkeydoc @hidden Deprecated!
	#end
	Property Data:StringMap<JsonValue>()
		Return _data
	Setter( data:StringMap<JsonValue> )
		_data=data
	End
	
	#rem monkeydoc Returns True.
	#end
	Property IsObject:Bool() Override
		Return True
	End
	
	#rem monkeydoc Gets the internal string map used to store the object.
	#end
	Method ToObject:StringMap<JsonValue>() Override
		Return _data
	End
	
	#rem monkeydoc Gets the value associated with a key.
	
	Returns the json value associated with `key`, or null if `key` does not exist.
	
	@param index Object key.
	
	#end
	Method GetValue:JsonValue( key:String )
		Return _data[key]
	End
	
	#rem monkeydoc Gets a bool from an object.
	
	Returns the bool value associated with `key`, or false if `key` does not exist or the value associated with `key` is not a bool.
	
	@param key Object key.
	
	#end
	Method GetBool:Bool( key:String )
		Local value:=GetValue( key )
		If value Return value.ToBool()
		Return False
	End
	
	#rem monkeydoc Gets a number from an object.
	
	Returns the numeric value associated with `key`, or 0 if `key` does not exist or the value associated with `key` is not numeric.
	
	@param key Object key.
	
	#end
	Method GetNumber:Double( key:String )
		Local value:=GetValue( key )
		If value Return value.ToNumber()
		Return 0
	End
	
	#rem monkeydoc Gets a string from an object.
	
	Returns the string value associated with `key`, or an empty string if `key` does not exist or the value associated with `key` is not a string.
	
	@param key Object key.
	
	#end
	Method GetString:String( key:String )
		Local value:=GetValue( key )
		If value Return value.ToString()
		Return ""
	End
	
	#rem monkeydoc Gets an array from an object.
	
	Returns the json array associated with `key`, or null if `key` does not exist or the value associated with `key` is not an array.

	@param key Object key.
	
	#end
	Method GetArray:JsonArray( key:String )
		Return Cast<JsonArray>( GetValue( key ) )
	End
	
	#rem monkeydoc Gets an object from the object.
	
	Returns the json object associated with `key`, or null if `key` does not exist or the value associated with `key` is not an object.
	
	@param key Object key.
	
	@return A json object.

	#end
	Method GetObject:JsonObject( key:String )
		Return Cast<JsonObject>( GetValue( key ) )
	End
	
	#rem monkeydoc Sets a key to a value.
	
	Sets the value associated with `key` in the object.
	
	Any previous value associated with `key` is overwritten.
	
	@param key Object key.
	
	@param value Value to set.

	#end
	Method SetValue( key:String,value:JsonValue )
		_data[key]=value
	End
	
	#rem monkeydoc Sets a key to a value.
	
	Sets the value associated with `key` in the object.
	
	Any previous value associated with `key` is overwritten.
	
	@param key Object key.
	
	@param value Value to set.

	#end
	Method SetBool( key:String,value:Bool )
		_data[key]=value ? JsonBool.TrueValue Else JsonBool.FalseValue
	End
	
	#rem monkeydoc Sets a key to a value.
	
	Sets the value associated with `key` in the object.
	
	Any previous value associated with `key` is overwritten.
	
	@param key Object key.
	
	@param value Value to set.

	#end
	Method SetNumber( key:String,value:Double )
		_data[key]=New JsonNumber( value )
	End
	
	#rem monkeydoc Sets a key to a value.
	
	Sets the value associated with `key` in the object.
	
	Any previous value associated with `key` is overwritten.
	
	@param key Object key.
	
	@param value Value to set.

	#end
	Method SetString( key:String,value:String )
		_data[key]=New JsonString( value )
	End
	
	#rem monkeydoc Sets a key to a value.
	
	Sets the value associated with `key` in the object.
	
	Any previous value associated with `key` is overwritten.
	
	@param key Object key.
	
	@param value Value to set.

	#end
	Method SetArray( key:String,value:JsonValue[] )
		_data[key]=New JsonArray( value )
	End

	Method SetArray( key:String,value:Stack<JsonValue> )
		_data[key]=New JsonArray( value )
	End
	
	#rem monkeydoc Sets a key to a value.
	
	Sets the value associated with `key` in the object.
	
	Any previous value associated with `key` is overwritten.
	
	@param key Object key.
	
	@param value Value to set.

	#end
	Method SetObject( key:String,value:StringMap<JsonValue> )
		_data[key]=New JsonObject( value )
	End
	
	#rem monkeydoc True if object is empty.
	#end
	Property Empty:Bool()
		Return _data.Empty
	End

	#rem monkeydoc Counts the number of keys in the object.
	
	Returns the number of keys contained in the object.
	
	@return The number of keys.
	
	#end
	Method Count:Int()
		Return _data.Count()
	End
	
	#rem monkeydoc Checks if the object contains a key.
	
	Returns true if object contains `key`.
	
	@param key Key to check for.
	
	@return True if object contains `key`.
	
	#end
	Method Contains:Bool( key:String )
		Return _data.Contains( key )
	End
	
	#rem monkeydoc Gets an iterator to all json values in the object.
	#end
	Method All:StringMap<JsonValue>.Iterator()
		Return _data.All()
	End
	
	#rem monkeydoc Gets the json value associated with a key.
	
	Returns the json value associated with `key`, or null if `key` does not exist.
	
	@param key The key.
	
	@return The json value associated with `key`.
	
	#end
	Operator[]:JsonValue( key:String )
		Return _data[key]
	End
	
	#rem monkeydoc Sets the json value in the object.
	
	Sets the json value associated with `key` to `value`.
	
	@param key The key.
	
	@param value The json value to associate with `key`.
	
	#end
	Operator[]=( key:String,value:JsonValue )
		_data[key]=value
	End
	
	Function Load:JsonObject( path:String,throwex:Bool=False )

		Local src:=std.stringio.LoadString( path )
		If Not src Return Null
		
		Return Parse( src,throwex )
	End
	
	Function Parse:JsonObject( json:String,throwex:Bool=False )
		Try
			Local parser:=New JsonParser( json )
			Return New JsonObject( parser.ParseObject() )
		Catch ex:JsonError
			If throwex Throw ex
		End
		Return Null
	End
	
	Private
	
	Field _data:StringMap<JsonValue>

	Method PushJson:Void( buf:StringStack ) Override
		buf.Push( "{~n" )
		_indent+="~t"
		Local t:=False
		For Local it:=Eachin _data
			If t buf.Push( ",~n" )
			buf.Push( _indent+"~q"+it.Key.Replace( "~q","\~q" )+"~q:" )
			If it.Value
				buf.Push( it.Value.ToJson() )
			Else
				buf.Push( "null" )
			Endif
			t=True
		Next
		_indent=_indent.Slice( 0,-1 )
		buf.Push( "~n"+_indent+"}" )
	End
	
End

#rem monkeydoc JsonParser class.
#end
Class JsonParser

	Method New( json:String )
		_text=json
		Bump()
	End
	
	Method ParseValue:JsonValue()
		If TokeType=T_STRING Return New JsonString( ParseString() )
		If TokeType=T_NUMBER Return New JsonNumber( ParseNumber() )
		If Toke="{" Return New JsonObject( ParseObject() )
		If Toke="[" Return New JsonArray( ParseArray() )
		If CParse( "true" ) Return JsonBool.TrueValue
		If CParse( "false" ) Return JsonBool.FalseValue
		If CParse( "null" ) Return JsonValue.NullValue
		Return Null
	End
	
	Private
	
	Const T_EOF:=0
	Const T_STRING:=1
	Const T_NUMBER:=2
	Const T_SYMBOL:=3
	Const T_IDENT:=4
	
	Field _text:String
	Field _toke:String
	Field _type:Int
	Field _pos:Int
	
	Method GetChar:Int()
		If _pos=_text.Length Throw New JsonError()
		_pos+=1
		Return _text[_pos-1]
	End
	
	Method PeekChar:Int()
		If _pos=_text.Length Return 0
		Return _text[_pos]
	End
	
	Method ParseChar:Void( chr:Int )
		If _pos>=_text.Length Or _text[_pos]<>chr Throw New JsonError()
		_pos+=1
	End
	
	Method CParseChar:Bool( chr:Int )
		If _pos>=_text.Length Or _text[_pos]<>chr Return False
		_pos+=1
		Return True
	End
	
	Method CParseDigits:Bool()
		Local p:=_pos
		While _pos<_text.Length And _text[_pos]>=48 And _text[_pos]<=57
			_pos+=1
		Wend
		Return _pos>p
	End
	
	Method Bump:String()
	
		While _pos<_text.Length
			If _text[_pos]=47
				'// comment? - can't live without 'em!
				If _pos+1=_text.Length Or _text[_pos+1]<>47 Exit
				_pos+=2
				While _pos<_text.Length And _text[_pos]<>10
					_pos+=1
				Wend
				If _pos<_text.Length _pos+=1
			Else
				If _text[_pos]>32 Exit
				_pos+=1
			Endif
		Wend
		
		If _pos=_text.Length
			_toke=""
			_type=T_EOF
			Return _toke
		Endif
		
		Local pos:=_pos
		Local chr:=GetChar()
		
		If chr=34
			Repeat
				Local chr:=GetChar()
				If chr=34 Exit
				If chr=92 GetChar()	'\
			Forever
			_type=T_STRING
		Else If chr=39
			Repeat
				Local chr:=GetChar()
				If chr=39 Exit
				If chr=92 GetChar()	'\
			Forever
			_type=T_STRING
		Else If (chr>=48 And chr<=57) Or chr=45
			If chr=45 '-
				chr=GetChar()
				If chr<48 Or chr>57 Throw New JsonError()
			Endif
			If chr<>48 '0
				CParseDigits()
			End
			If CParseChar( 46 )	'.
				CParseDigits()
			Endif
			If CParseChar( 69 ) Or CParseChar( 101 ) 'e E
				If PeekChar()=43 Or PeekChar()=45 GetChar()	'+ -
				If Not CParseDigits() Throw New JsonError()
			Endif
			_type=T_NUMBER
		Else If (chr>=65 And chr<91) Or (chr>=97 And chr<123) Or chr=95
			chr=PeekChar()
			While (chr>=65 And chr<91) Or (chr>=97 And chr<123) Or (chr>=48 And chr<58) Or chr=95
				GetChar()
				chr=PeekChar()
			Wend
			_type=T_IDENT
		Else
			_type=T_SYMBOL
		Endif
		_toke=_text.Slice( pos,_pos )
		Return _toke
	End
	
	Property Toke:String()
		Return _toke
	End
	
	Property TokeType:Int()
		Return _type
	End
	
	Method CParse:Bool( toke:String )
		If toke<>_toke Return False
		Bump()
		Return True
	End
	
	Method Parse:Void( toke:String )
		If Not CParse( toke ) Throw New JsonError()
	End

	Method ParseObject:StringMap<JsonValue>()
		Parse( "{" )
		Local map:=New StringMap<JsonValue>
		If CParse( "}" ) Return map
		Repeat
			Local name:=Toke
			If TokeType=T_IDENT
				Bump()
			Else
				name=ParseString()
			Endif
			Parse( ":" )
			Local value:=ParseValue()
			map.Set( name,value )
		Until Not CParse( "," )
		Parse( "}" )
		Return map
	End
	
	Method ParseArray:Stack<JsonValue>()
		Parse( "[" )
		Local stack:=New Stack<JsonValue>
		If CParse( "]" ) Return stack
		Repeat
			Local value:=ParseValue()
			stack.Add( value )
		Until Not CParse( "," )
		Parse( "]" )
		Return stack
	End
	
	Method ParseString:String()
	
		If TokeType<>T_STRING Throw New JsonError()
		
		Local toke:=Toke.Slice( 1,-1 )
		
		Local i:=toke.Find( "\" )
		If i<>-1
			Local frags:=New StringStack,p:=0,esc:=""
			Repeat
				If i+1>=toke.Length 
					frags.Push( toke.Slice( p ) )
					Exit
				Endif
				frags.Push( toke.Slice( p,i ) )
				Select toke[i+1]
				Case 34  esc="~q"					'\"
				Case 92  esc="\"					'\\
				Case 47  esc="/"					'\/
				Case 98  esc=String.FromChar(  8 )	'\b
				Case 102 esc=String.FromChar( 12 )	'\f
				Case 110 esc=String.FromChar( 10 )	'\n
				Case 114 esc=String.FromChar( 13 )	'\r
				Case 116 esc=String.FromChar(  9 )	'\t
				Case 117							'\uxxxx
					If i+6>toke.Length Throw New JsonError()
					Local val:=0
					For Local j:=2 Until 6
						Local chr:=toke[i+j]
						If chr>=48 And chr<58
							val=val Shl 4 | (chr-48)
						Else If chr>=65 And chr<123
							chr&=31
							If chr<1 Or chr>6 Throw New JsonError()
							val=val Shl 4 | (chr+9)
						Else
							Throw New JsonError()
						Endif
					Next
					esc=String.FromChar( val )
					i+=4
				Default
					esc=toke.Slice( i,i+2 )
				End
				frags.Push( esc )
				p=i+2
				i=toke.Find( "\",p )
				If i<>-1 Continue
				frags.Push( toke.Slice( p ) )
				Exit
			Forever
			toke=frags.Join( "" )
		Endif
		Bump()
		Return toke
	End
	
	Method ParseNumber:Double()
		If TokeType<>T_NUMBER Throw New JsonError()
		Local toke:=Toke
		Bump()
		Return Double( toke )
	End
	
End
