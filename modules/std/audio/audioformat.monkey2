
Namespace std.audio

#rem monkeydoc Audio formats.

| AudioFormat	| Description
|:--------------|:-----------
| `Unknown`		| Unknown format.
| `Mono8`		| 8 bit mono.
| `Mono16`		| 16 bit mono.
| `Stereo8`		| 8 bit stereo.
| `Stereo16`	| 16 bit stereo.
#end
Enum AudioFormat
	Unknown=0
	Mono8=1
	Mono16=2
	Stereo8=3
	Stereo16=4
End

#rem monkeydoc Number of bytes per audio sample.

Returns the number of bytes per audio sample for the given audio format.

@param format The audio format.

#end
Function BytesPerSample:Int( format:AudioFormat )
	Select format
	Case AudioFormat.Mono8 Return 1
	Case AudioFormat.Mono16 Return 2
	Case AudioFormat.Stereo8 Return 2
	Case AudioFormat.Stereo16 Return 4
	End
	Return 0
End
