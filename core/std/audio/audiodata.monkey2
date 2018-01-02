
Namespace std.audio

#rem monkeydoc The AudioData class.
#end
Class AudioData Extends Resource

	#rem monkeydoc Creates a new AudioData object
	#end
	Method New( length:Int,format:AudioFormat,hertz:Int )
		_length=length
		_format=format
		_hertz=hertz
		_owned=True
		_data=Cast<UByte Ptr>( GCMalloc( BytesPerSample( format )*length ) )
	End

	Method New( length:Int,format:AudioFormat,hertz:Int,data:Void Ptr )
		_length=length
		_format=format
		_hertz=hertz
		_owned=false
		_data=Cast<UByte Ptr>( data )
	End
	
	#rem monkeydoc The length, in samples, of the audio.
	#end
	Property Length:Int()
		Return _length
	End
	
	#rem monkeydoc The format of the audio.
	#end
	Property Format:AudioFormat()
		Return _format
	End
	
	#rem monkeydoc The playback rate of the audio.
	#end
	Property Hertz:Int()
		Return _hertz
	End

	#rem monkeydoc The duration, in seconds, of the audio.
	#end
	Property Duration:Double()
		Return Double(_length)/Double(_hertz)
	End

	#rem monkeydoc The actual audio data.
	#end	
	Property Data:UByte Ptr()
		Return _data
	End

	#rem monkeydoc The size, in bytes of the audio data.
	#end	
	Property Size:Int()
		Return BytesPerSample( _format ) * _length
	End
	
	#rem monkeydoc Sets a sample at a given sample index.

	`index` must be in the range [0,Length).
	
	#end
	Method SetSample( index:Int,sample:Float,channel:Int=0 )
		DebugAssert( index>=0 And index<_length )
		Select _format
		Case AudioFormat.Mono8
			_data[index]=Clamp( sample * 128.0 + 128.0,0.0,255.0 )
		Case AudioFormat.Stereo8
			_data[index*2+(channel&1)]=Clamp( sample * 128.0 + 128.0,0.0,255.0 )
		Case AudioFormat.Mono16
			Cast<Short Ptr>( _data )[index]=Clamp( sample * 32768.0,-32768.0,32767.0 )
		Case AudioFormat.Stereo16
			Cast<Short Ptr>( _data )[index*2+(channel&1)]=Clamp( sample * 32768.0,-32768.0,32767.0 )
		End
	End
	
	#rem monkeydoc Gets a sample at a given sample index.
	
	`index` must be in the range [0,Length).
	
	#end
	Method GetSample:Float( index:Int,channel:Int=0 )
		
		'Ok, note that this never returns quite +1.0 as there is one less int above 0 than below
		'eg: range of signed ints is [-128,+127]
		'
		DebugAssert( index>=0 And index<_length )
		Select _format
		Case AudioFormat.Mono8
			Return ( _data[index] - 128.0 ) / 128.0
		Case AudioFormat.Stereo8
			Return ( _data[index*2+(channel&1)] - 128.0 ) / 128.0
		Case AudioFormat.Mono16
			Return Cast<Short Ptr>( _data )[index]/32768.0
		Case AudioFormat.Stereo16
			Return Cast<Short Ptr>( _data )[index*2+(channel&1)]/32768.0
		End
		Return 0
	End
	
	#rem monkeydoc Loads audio data from a file.
	
	The file must be in "wav" or ".ogg" format.
	
	#end
	Function Load:AudioData( path:String )
	
		Select ExtractExt( path ).ToLower()
		Case ".wav" Return LoadAudioData_WAV( path )
		Case ".ogg" Return LoadAudioData_OGG( path )
		End
		
		Return Null
	End
	
	Protected
	
	#rem monkeydoc @hidden
	#end
	Method OnDiscard() Override
		
		If _owned GCFree( _data )
			
		_data=Null
	End
	
	#rem monkeydoc @hidden
	#end
	Method OnFinalize() Override
		
		If _owned GCFree( _data )
	End
	
	Private
	
	Field _length:Int
	Field _format:AudioFormat
	Field _hertz:Int
	Field _owned:Bool

	Field _data:UByte Ptr
	
End
