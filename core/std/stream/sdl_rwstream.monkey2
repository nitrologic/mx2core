
Namespace std.stream

Using sdl2

Class SDL_RWStream Extends Stream

	#rem monkeydoc True if no more data can be read from the stream.
	
	You can still write to a filestream even if `Eof` is true - disk space permitting!
	
	#end
	Property Eof:Bool() Override
		Return _pos>=_end
	End

	#rem monkeydoc Current filestream position.
	
	The current file read/write position.
	
	#end
	Property Position:Int() Override
		Return _pos
	End

	#rem monkeydoc Current filestream length.
	
	The length of the filestream. This is the same as the length of the file.
	
	The file length can increase if you write past the end of the file.
	
	#end	
	Property Length:Int() Override
		Return _end
	End
	
	#rem monkeydoc Closes the filestream.
	
	Closing the filestream also sets its position and length to 0.
	
	#end
	Method OnClose() Override
		If Not _rwops Return
		SDL_RWclose( _rwops )
		_rwops=Null
		_pos=0
		_end=0
	End
	
	#rem monkeydoc Seeks to a position in the filestream.
	
	@param offset The position to seek to.
	
	#end
	Method Seek( position:Int ) Override

		DebugAssert( position>=0 And position<=_end )
		
		SDL_RWseek( _rwops,position,RW_SEEK_SET )
		
		DebugAssert( SDL_RWtell( _rwops )=position )
		
		_pos=position
	End
	
	#rem monkeydoc Reads data from the filestream.
	
	@param buf A pointer to the memory to read the data into.
	
	@param count The number of bytes to read.
	
	@return The number of bytes actually read.
	
	#end
	Method Read:Int( buf:Void Ptr,count:Int ) Override
	
		count=Clamp( count,0,_end-_pos )
		
		count=SDL_RWread( _rwops,buf,1,count )
		
		DebugAssert( SDL_RWtell( _rwops )=_pos+count )
		
		_pos+=count
		
		Return count
	End
	
	#rem monkeydoc Writes data to the filestream.
	
	Writing past the end of the file will increase the length of a filestream.
	
	@param buf A pointer to the memory to write the data from.
	
	@param count The number of bytes to write.
	
	@return The number of bytes actually written.
	
	#end
	Method Write:Int( buf:Void Ptr,count:Int ) Override
	
		If count<=0 Return 0
		
		count=SDL_RWwrite( _rwops,buf,1,count )
		
		DebugAssert( SDL_RWtell( _rwops )=_pos+count )
		
		_pos+=count
		
		Return count
	End
	
	#rem monkeydoc Opens a file and returns a new filestream.
	
	@param path The path of the file to open.
	
	@param mode The mode to open the file in: "r", "w" or "rw".
	
	@return A new filestream, or null if the file could not be opened.
	
	#end
	Function Open:SDL_RWStream( path:String,mode:String )
	
		Select mode
		Case "r"
			mode="rb"
		Case "w"
			mode="wb"
		Case "rw"
			mode="W+b"
		Default
			Return Null
		End
		
		Local rwops:=SDL_RWFromFile( path,mode )
		If Not rwops Return Null
		
		Return New SDL_RWStream( rwops )
	End
	
	Private
	
	Field _rwops:SDL_RWops Ptr
	Field _pos:Int
	Field _end:Int
	
	Method New( rwops:SDL_RWops Ptr )
		_rwops=rwops
		_pos=SDL_RWtell( _rwops )
		_end=SDL_RWsize( _rwops )
	End

End
