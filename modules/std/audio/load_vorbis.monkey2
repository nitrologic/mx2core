
Namespace std.audio

#rem monkeydoc @hidden
#end
Class StbAudioData Extends AudioData
	
	Method New( length:Int,format:AudioFormat,hertz:Int,data:Void Ptr )
		Super.New( length,format,hertz,data )
		
		_data=data
	End
	
	Private
	
	Field _data:Void Ptr
	
	Method OnDiscard() Override
		
		libc.free( _data )
		
		_data=Null
	End
	
	Method OnFinalize() Override
		
		libc.free( _data )
	End
	
End

Internal

Function LoadAudioData_OGG:AudioData( path:String )

	Local buf:=std.memory.DataBuffer.Load( path )
	If Not buf Return Null
	
	Local channels:Int
	Local hertz:Int
	Local samples:Short Ptr
	
	Local length:=stb.vorbis.stb_vorbis_decode_memory( buf.Data,buf.Length,Varptr channels,Varptr hertz,Varptr samples )
	
	If length=-1 Return Null
	
	Local format:AudioFormat
	Select channels
	Case 1 
		format=AudioFormat.Mono16
	Case 2 
		format=AudioFormat.Stereo16
	Default
		libc.free( samples )
		Return Null
	End
	
	Local data:=New AudioData( length,format,hertz,samples )
	
	Return data

End



