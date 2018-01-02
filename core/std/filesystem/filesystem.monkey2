
Namespace std.filesystem

Using libc

#Import "native/filesystem.h"
#Import "native/filesystem.cpp"

#If __TARGET__="android"
#Import "native/Monkey2FileSystem.java"
#Elseif __TARGET__="ios"
#Import "native/filesystem.mm"
#endif

Extern

#rem monkeydoc Gets application directory.

@return The directory containing the application executable.

#end
Function AppDir:String()="bbFileSystem::appDir"

#rem monkeydoc Gets the application file path.

@return The path of the application executable.

#end
Function AppPath:String()="bbFileSystem::appPath"

#rem monkeydoc Gets application command line arguments.

The first argument is always the application name.

@return The application command line arguments.

#end
Function AppArgs:String[]()="bbFileSystem::appArgs"

#rem monkeydoc Copies a file.

Copies a file from `srcPath` to `dstPath`, overwriting `dstpath` if it alreay exits.

Returns true if successful.

@return True if the file was successfully copied.

#end
Function CopyFile:Bool( srcPath:String,dstPath:String )="bbFileSystem::copyFile"
	
Private

Global _config:=New StringMap<String>

Function FixPath:String( path:String )
	
	Local root:=ExtractRootDir( path )
	If Not root.EndsWith( "::" ) Return path
	
	path=path.Slice( root.Length )
	
	Select root
	Case "asset::" return AssetsDir()+path
	Case "desktop::" Return DesktopDir()+path
	Case "home::" Return HomeDir()+path
#If __MOBILE_TARGET__
	Case "internal::" Return InternalDir()+path
	Case "external::" Return ExternalDir()+path
#endif
	End
	
	Return ""
End

Function FixFilePath:String( path:String )
	
	Return FixPath( StripSlashes( path ) )
End

#If __TARGET__="android"

Function GetSpecialDir:String( name:String )
	
	Global _class:jclass
	Global _getSpecialDir:jmethodID
	
	Local env:=sdl2.Android_JNI_GetEnv()
		
	If Not _getSpecialDir
	
		_class=env.FindClass( "com/monkey2/lib/Monkey2FileSystem" )
		
		_getSpecialDir=env.GetStaticMethodID( _class,"getSpecialDir","(Ljava/lang/String;)Ljava/lang/String;" )
	
	Endif
	
	Local dir:=env.CallStaticStringMethod( _class,_getSpecialDir,New Variant[]( name ) )
	
	Return dir
End

#Elseif __TARGET__="ios"

Extern Private

Function GetSpecialDir:String( name:String )="bbFileSystem::getSpecialDir"
	
Private
	
#else

Function GetSpecialDir:String( name:String )
	
	Return ""
End
	
#Endif

Public

#rem monkeydoc FileType enumeration.

| FileType		| Description
|:--------------|:-----------
| `None`		| File does not exist.
| `File`		| File is a normal file.
| `Directory`	| File is a directory.
| `Unknown`		| File is of unknown type.

#end
Enum FileType
	None=0
	File=1
	Directory=2
	Unknown=3
End

'For backward compatibility - don't use!
'
#rem monkeydoc @hidden
#end
Const FILETYPE_NONE:=FileType.None

#rem monkeydoc @hidden
#end
Const FILETYPE_FILE:=FileType.File

#rem monkeydoc @hidden
#end
Const FILETYPE_DIR:=FileType.Directory

#rem monkeydoc @hidden
#end
Const FILETYPE_UNKNOWN:=FileType.Unknown

#rem monkeydoc Gets an environment variable.

Returns the value of the given environment variable, or `defaultValue` if none was found.

#end
Function GetEnv:String( name:String,defaultValue:String="" )
	
	Local p:=getenv( name )
	
	If p Return String.FromCString( p )
	
	Return defaultValue
End

#rem monkeydoc Sets an environment variable.

Sets the value of a given environment variable.

#end
Function SetEnv( name:String,value:String )
	
	setenv( name,value,1 )
End

#rem monkeydoc Gets a global config setting.

See also [[SetConfig]] for a list of possible config settings.

#end
Function GetConfig:String( name:String,defaultValue:String="" )
	
	Return _config.Contains( name ) ? _config[name] Else defaultValue
End

#rem monkeydoc Sets a global config setting.

Currently known built-in config settings:

| Name									| More information
|:--------------------------------------|:----------------
| "MOJO\_OPENGL\_PROFILE"				| [[mojo:mojo.app.AppInstance.New|AppInstance.New]]
| "MOJO\_OPENGL\_VERSION\_MAJOR"		| [[mojo:mojo.app.AppInstance.New|AppInstance.New]]
| "MOJO\_OPENGL\_VERSION\_MINOR"		| [[mojo:mojo.app.AppInstance.New|AppInstance.New]]
| "MOJO\_COLOR\_BUFFER\_BITS"			| [[mojo:mojo.app.AppInstance.New|AppInstance.New]]
| "MOJO\_DEPTH\_BUFFER\_BITS"			| [[mojo:mojo.app.AppInstance.New|AppInstance.New]]
| "MOJO\_STENCIL\_BUFFER\_BITS"			| [[mojo:mojo.app.AppInstance.New|AppInstance.New]]
| "MOJO\_TEXTURE\_MAX\_ANISOTROPY"		| [[mojo:mojo.graphics.Texture.New|Texture.New]]
| "MOJO3D\_DEFAULT\_RENDERER"			| [[mojo3d:mojo3d.Renderer.GetCurrent|Renderer.GetCurrent]]
| "MOJO3D\_FORWARD\_RENDERER\_DIRECT"	| [[mojo3d:mojo3d.ForwardRenderer.New|ForwardRenderer.New]]

See also: [[GetConfig]].

#end
Function SetConfig( name:String,value:String )
	
	If value _config[name]=value Else _config.Remove( name )
End

#rem monkeydoc Gets the filesystem directory of the app's assets directory.

Note that only the desktop and web targets have an assets directory. Other targets will return an empty string.

@return The directory app assets are stored in.

#end
Function AssetsDir:String()
#If __TARGET__="macos"
	Return AppDir()+"../Resources/"
	'Return ExtractDir( AppDir() )+"/Resources/"	'enable me!
#Else If __DESKTOP_TARGET__ Or __WEB_TARGET__
	Return AppDir()+"assets/"
#Else If __TARGET__="ios"
	Return GetSpecialDir( "assets" )
#Else
	Return "asset::"
#Endif
End

#rem monkeydoc Gets the filesystem directory of the user's desktop directory.

Note that only the desktop targets have a desktop directory. Other targets will return an empty string.

@return The desktop directory.

#end
Function DesktopDir:String()
#If __TARGET__="windows"
	Return GetEnv( "USERPROFILE" ).Replace( "\","/" )+"/Desktop/"
#Else If __DESKTOP_TARGET__
 	Return GetEnv( "HOME" )+"/Desktop/"
 #Else
 	Return "desktop::"
#Endif
End

#rem monkeydoc Gets the filesystem directory of the user's home directory.

Note that only the desktop targets have a home directory. Other targets will return an empty string.

@return The home directory.

#end
Function HomeDir:String()
#If __TARGET__="windows"
	Return GetEnv( "USERPROFILE" ).Replace( "\","/" )+"/"
#Else if __DESKTOP_TARGET__
	Return GetEnv( "HOME" )+"/"
#Else
	Return "home::"
#Endif
End

#rem monkeydoc Gets the filesystem directory of the app's internal storage directory.

Returns the absolute path to the directory on the filesystem where files created with openFileOutput(String, int) are stored.

This directory will be removed when your app is uninstalled.

This function is only available on mobile targets.

@return The app's internal directory.

#End
Function InternalDir:String()

	Return GetSpecialDir( "internal" )
End

#rem monkeydoc Gets the filesystem directory of the app's external storage directory.

Returns the absolute path to the directory on the primary shared/external storage device where the application can place persistent files it owns. These files are internal to the applications, and not typically visible to the user as media.

This directory will be removed when your app is uninstalled.

This function is only available on mobile targets.

@return The app's external storage directory.

#End
Function ExternalDir:String()
	
	Return GetSpecialDir( "external" )
End

#rem monkeydoc Extracts the root directory from a file system path.

A root directory is a directory path that:

* Starts with '//' or '/', or...

* Starts with 'blah:/', 'blah://' or 'blah::'.

@param path The filesystem path.

@return The root directory of `path`, or an empty string if `path` is not an absolute path.
 
#end
Function ExtractRootDir:String( path:String )

	If path.StartsWith( "//" ) Return "//"
	
	Local i:=path.Find( "/" )
	If i=0 Return "/"
	
	If i=-1 i=path.Length
	
	Local j:=path.Find( "://" )
	If j>0 And j<i Return path.Slice( 0,j+3 )
	
	j=path.Find( ":/" )
	If j>0 And j<i Return path.Slice( 0,j+2 )
	
	j=path.Find( "::" )
	If j>0 And j<i Return path.Slice( 0,j+2 )
	
	Return ""
	
End

#rem monkeydoc Checks if a path is a root directory.

@param path The filesystem path to check.

@return True if `path` is a root directory path.

#end
Function IsRootDir:Bool( path:String )

	If path="//" Return True
	
	If path="/" Return True
	
	Local i:=path.Find( "/" )
	If i=-1 i=path.Length
	
	Local j:=path.Find( "://" )
	If j>0 And j<i Return j+3=path.Length
	
	j=path.Find( ":/" )
	If j>0 And j<i Return j+2=path.Length
	
	j=path.Find( "::" )
	If j>0 And j<i Return j+2=path.Length
	
	Return False
End

#rem monkeydoc Gets the process current directory.

@return The current directory for the running process.

#end
Function CurrentDir:String()
	
	Local buf:=New char_t[PATH_MAX]
	
	getcwd( buf.Data,PATH_MAX )
	
	Local path:=String.FromCString( buf.Data )
	
#If __TARGET__="windows"	
	path=path.Replace( "\","/" )
#Endif

	If path.EndsWith( "/" ) Return path

	Return path+"/"
End

#rem monkeydoc Converts a path to a real path.

If `path` is a relative path, it is first converted into an absolute path by prefixing the current directory.

Then, any internal './' or '../' references in the path are collapsed.

@param path The filesystem path.

@return An absolute path with any './', '../' references collapsed.

#end
Function RealPath:String( path:String )
	
	path=FixPath( path )
	
	Local rpath:=ExtractRootDir( path )
	If rpath 
		path=path.Slice( rpath.Length )
	Else
		rpath=CurrentDir()
	Endif
	
	While path
		Local i:=path.Find( "/" )
		If i=-1 Return rpath+path
		Local t:=path.Slice( 0,i )
		path=path.Slice( i+1 )
		Select t
		Case ""
		Case "."
		Case ".."
			If Not rpath rpath=CurrentDir()
			rpath=ExtractDir( rpath )
		Default
			rpath+=t+"/"
		End
	Wend
	
	Return rpath
	
	#rem Not working on macos!
	
	path=FixPath( path )
	
	Local buf:=New char_t[PATH_MAX]
	
	If Not libc.realpath( path,buf.Data ) Return ""
	
	Local rpath:=String.FromCString( buf.Data )
	
#If __TARGET__="windows"
	rpath=rpath.Replace( "\","/" )
#Endif

	Return rpath
	#end
End

#rem monkeydoc Strips any trailing slashes from a filesystem path.

This function will not strip slashes from a root directory path.

@param path The filesystem path.

@return The path stripped of trailing slashes.

#end
Function StripSlashes:String( path:String )
	
	If Not path.EndsWith( "/" ) Return path
	
	Local root:=ExtractRootDir( path )
	
	Repeat
	
		If path=root Return path

		path=path.Slice( 0,-1 )
		
	Until Not path.EndsWith( "/" )
	
	Return path
End

#rem monkeydoc Extracts the directory component from a filesystem path.

If `path` is a root directory it is returned without modification.

If `path` does not contain a directory component, an empty string is returned.

@param path The filesystem path.

@return The directory component of `path`.

#end
Function ExtractDir:String( path:String )

	path=StripSlashes( path )

	If IsRootDir( path ) Return path
	
	Local i:=path.FindLast( "/" )
	If i>=0 Return path.Slice( 0,i+1 )
	
	i=path.Find( "::" )
	If i>=0 Return path.Slice( 0,i+2 )
	
	Return ""
End

#rem monkeydoc Strips the directory component from a filesystem path.

If `path` is a root directory an empty string is returned.

If `path` does not contain a directory component, `path` is returned without modification.

@param path The filesystem path.

@return The path with the directory component stripped.

#end
Function StripDir:String( path:String )

	path=StripSlashes( path )

	If IsRootDir( path ) Return ""

	Local i:=path.FindLast( "/" )
	If i>=0 Return path.Slice( i+1 )
	
	i=path.Find( "::" )
	If i>=0 Return path.Slice( i+2 )
	
	Return path
End

#rem monkeydoc Extracts the extension component from a filesystem path.

@param path The filesystem path.

@return The extension component of `path` including  the '.' if any.

#end
Function ExtractExt:String( path:String )

	Local i:=path.FindLast( "." )
	If i=-1 Return ""
	
	Local j:=path.Find( "/",i+1 )
	If j=-1 Return path.Slice( i )
	
	Return ""
End

#rem monkeydoc Strips the extension component from a filesystem path.

@param path The filesystem path.

@return The path with the extension stripped.

#end
Function StripExt:String( path:String )

	Local i:=path.FindLast( "." )
	If i=-1 Return path
	
	Local j:=path.Find( "/",i+1 )
	If j=-1 Return path.Slice( 0,i )
	
	Return path
End

#rem monkeydoc Gets the type of the file at a filesystem path.

@param path The filesystem path.

@return The file type of the file at `path`, one of: FileType.None, FileType.File or FileType.Directory.

#end
Function GetFileType:FileType( path:String )
	
	path=FixFilePath( path )

	Local st:stat_t
	If stat( path,Varptr st )<0 Return FileType.None
	
	Select st.st_mode & S_IFMT
	Case S_IFREG Return FileType.File
	Case S_IFDIR Return FileType.Directory
	End
	
	Return FileType.Unknown
End

#rem monkeydoc Gets the time a file was most recently modified.

@param path The filesystem path.

@return The time the file at `path` was most recently modified.

#end
Function GetFileTime:Long( path:String )
	
	path=FixFilePath( path )

	Local st:stat_t
	If stat( path,Varptr st )<0 Return 0
	
	Return libc.tolong( st.st_mtime )
End

#rem monkeydoc Gets the size of the file at a filesystem path.

@param path The filesystem path.

@return The size file at `path` in bytes.

#end
Function GetFileSize:Long( path:String )

	path=FixFilePath( path )

	Local st:stat_t
	If stat( path,Varptr st )<0 Return 0

	return st.st_size
End

#rem monkeydoc Changes the process current directory.

@param path The filesystem path of the directory to make current.

#end
Function ChangeDir( path:String )

	path=FixFilePath( path )

	chdir( path )
End

#rem monkeydoc Loads a directory.

Loads the contents of directory into an array.

Does not return any '.' or '..' entries in a directory.

@param path The filesystem path of the directory to load.

@return An array containing all filenames in the `path`, excluding '.' and '..' entries.

#end
Function LoadDir:String[]( path:String )
	
	path=FixFilePath( path )

	Local dir:=opendir( path )
	If Not dir Return Null
	
	Local files:=New StringStack
	
	Repeat
		Local ent:=readdir( dir )
		If Not ent Exit
		
		Local file:=ent[0].d_name	'String.FromCString( ent[0].d_name )
		If file="." Or file=".." Continue
		
		files.Push( file )
	Forever
	
	closedir( dir )
	
	Return files.ToArray()
End

#rem monkeydoc Creates a file at a filesystem path.

Any existing file at the path will be overwritten.

Returns true if successful.

@param path The filesystem path of the file file to create.

@param createDir If true, also creates the file directory if necessary.

@return True if a file at the given path was created.

#end
Function CreateFile:Bool( path:String,createDir:Bool=True )
	
	path=FixFilePath( path )

	If createDir And Not CreateDir( ExtractDir( path ),True ) Return False
	
	Local f:=fopen( path,"wb" )
	If Not f Return False
	
	fclose( f )
	Return True
End

#rem monkeydoc Creates a directory at a filesystem path.

@param path The filesystem path of the directory to create.

@param recursive If true, any required parent directories are also created.

@param clean If true, any existing directory at `dir` is first deleted.

@return True if a directory at `path` was successfully created or already existed.

#end
Function CreateDir:Bool( dir:String,recursive:Bool=True,clean:Bool=False )
	
	dir=FixFilePath( dir )
	
	If recursive
	
		Local parent:=ExtractDir( dir )
	
		If parent And Not IsRootDir( parent )
		
			Select GetFileType( parent )
			Case FileType.None
				If Not CreateDir( parent,True,False ) Return False
			Case FileType.File
				Return False
			End
			
		Endif
		
	Endif
	
	If clean And Not DeleteDir( dir,True ) Return False
	
	mkdir( dir,$1ff )
	
	Return GetFileType( dir )=FileType.Directory
End

#rem monkeydoc Deletes a file at a filesystem path.

Returns true if successful.

@param path The filesystem path.

@return True if the file was successfully deleted.

#end
Function DeleteFile:Bool( path:String )
	
	path=FixFilePath( path )

	remove( path )
	
	Return GetFileType( path )=FileType.None
End

#rem monkeydoc Deletes a directory at a filesystem path.

If `recursive` is true, all subdirectories are also deleted.

Returns true if successful.

@param path The filesystem path.

@param recursive True to delete subdirectories too.

@return True if the directory was successfully deleted or never existed.

#end
Function DeleteDir:Bool( dir:String,recursive:Bool=False )
	
	dir=FixFilePath( dir )

	If GetFileType( dir )=FileType.Directory

		If recursive
			For Local f:=Eachin LoadDir( dir )
				Local p:=dir+"/"+f
				Select GetFileType( p )
				Case FileType.File
					If Not DeleteFile( p ) Return False
				Case FileType.Directory
					If Not DeleteDir( p,True ) Return false
				End
			Next
		Endif
		
		rmdir( dir )
	Endif
	
	Return GetFileType( dir )=FileType.None
End


#rem monkeydoc Copies a directory.

Copies a directory from `srcDir` to `dstDir`.

If `recursive` is true, all subdirectories are also copied.

Returns true if successful.

@param srcDir Source directory.

@param dstDir Destination directory.

@param recursive Recursive flag.

@return True if successful.

#end
Function CopyDir:Bool( srcDir:String,dstDir:String,recursive:Bool=True )
	
	srcDir=FixFilePath( srcDir )
	
	dstDir=FixFilePath( dstDir )

	If GetFileType( srcDir )<>FileType.Directory Return False
	
	If GetFileType( dstDir )<>FileType.Directory And Not CreateDir( dstDir,True ) Return False
	
	For Local f:=Eachin LoadDir( srcDir )
	
		Local src:=srcDir+"/"+f
		Local dst:=dstDir+"/"+f
		
		Select GetFileType( src )
		Case FileType.File
			If Not CopyFile( src,dst ) Return False
		Case FileType.Directory
			If recursive And Not CopyDir( src,dst ) Return False
		End
		
	Next
	
	Return True

End
