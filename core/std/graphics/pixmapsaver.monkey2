
Namespace std.graphics

Private

Using stb.image
Using std.stream
Using std.filesystem

Struct WriteContext
	Field stream:Stream
End

Function WriteFunc( context:Void Ptr,data:Void Ptr,size:Int )
	Local stream:=Cast<WriteContext Ptr>( context )->stream
	stream.Write( data,size )
End

Public

#rem monkeydoc @hidden
#end
Function SavePixmap:Bool( pixmap:Pixmap,path:String )

	Local stream:=Stream.Open( path,"w" )
	If Not stream Return False
	
	Local context:WriteContext
	context.stream=stream
	
	Local result:=stbi_write_png_to_func( WriteFunc,Varptr context,pixmap.Width,pixmap.Height,pixmap.Depth,pixmap.Data,pixmap.Pitch )
	
	stream.Close()
	
	Return result
End
