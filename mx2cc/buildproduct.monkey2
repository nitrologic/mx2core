
Namespace mx2

Class BuildProduct

	Field module:Module
	Field opts:BuildOpts
	Field imports:=New Stack<Module>
	Field outputFile:String
	
	Field CC_OPTS:String
	Field CPP_OPTS:String
	Field AS_OPTS:String
	Field LD_OPTS:String
	
	Field SRC_FILES:=New StringStack	'source code files
	Field JAVA_FILES:=New StringStack	'java files
	Field OBJ_FILES:=New StringStack	'object code files - added to module .a
	Field LIB_FILES:=New StringStack	'library files - passed to linker.
	Field DLL_FILES:=New StringStack	'dll/exe files, copied to app dir.
	
	Field ASSET_FILES:=New StringStack
	
	Field reflects:=New StringStack
	
	Method New( module:Module,opts:BuildOpts )
		Self.module=module
		Self.opts=opts
		
		Local copts:=""
		For Local moddir:=Eachin Module.Dirs
			copts+=" -I~q"+moddir+"~q"
		Next
		copts+=" -I~q"+Module.Dirs[0]+"monkey/native~q"
		
		If APP_DIR copts+=" -I~q"+APP_DIR+"~q"

		CC_OPTS+=copts
		CPP_OPTS+=copts
	End

	Method Build()
		
		If opts.verbose=0 Print "Compiling..."
		
		If Not CreateDir( module.cacheDir ) Throw New BuildEx( "Error creating dir '"+module.cacheDir+"'" )
			
		Local srcs:=New StringStack

		If opts.productType="app" 'And Not reflects.Empty

			CC_OPTS+=" -DBB_NEWREFLECTION"
			CPP_OPTS+=" -DBB_NEWREFLECTION"			
			
			CC_OPTS+=" -I~q"+module.cacheDir+"~q"
			CPP_OPTS+=" -I~q"+module.cacheDir+"~q"
			
			Local rhead:="//REFLECT:~n"+reflects.Join( "~n" )
			
			CSaveString( rhead,module.cacheDir+"_r.h" )
			
			srcs.Push( module.rfile )
			
			For Local imp:=Eachin imports
			
				srcs.Push( imp.rfile )
			Next
		Endif
		
		For Local fdecl:=Eachin module.fileDecls
		
			srcs.Push( fdecl.cfile )
		Next
		
		srcs.AddAll( SRC_FILES )
		
		Build( srcs )
	End
	
	Method Build( srcs:StringStack ) Virtual
	End
	
	Method Run() Virtual
	End

	Protected
	
	Method AllocTmpFile:String( kind:String )
	
		CreateDir( "tmp" )

		For Local i:=1 Until 10
			Local file:="tmp/"+kind+i+".txt"
			DeleteFile( file )
			If GetFileType( file )=FileType.None Return file
		Next
		
		Throw New BuildEx( "Can't allocate tmp file" )
		
		Return ""
	End
	
	Method Exec:Bool( cmd:String,eatstdout:Bool=False )
		
		If opts.verbose>2 Print cmd
			
		Local fstdout:=eatstdout ? AllocTmpFile( "stdout" ) Else ""
		
		If eatstdout cmd+=" >"+fstdout
			
		Local fstderr:=AllocTmpFile( "stderr" )
		
		If Not system( cmd+" 2>"+fstderr ) Return True
		
		Local err:="System command failed:~n~n"+cmd+"~n~n"
		
		If eatstdout err+=LoadString( fstdout )+"~n"
		
		err+=LoadString( fstderr )
		
		Throw New BuildEx( err )
		
		Return False
	End
	
	Method CopyAssets( assetsDir:String )
	
		If Not assetsDir.EndsWith( "/" ) assetsDir+="/"
		
		Local assetFiles:=New StringMap<String>
		
		For Local src:=Eachin ASSET_FILES
		
			Local dst:=assetsDir
		
			Local i:=src.Find( "@/" )
			If i<>-1
				dst+=src.Slice( i+2 )
				src=src.Slice( 0,i )
				If Not dst.EndsWith( "/" ) dst+="/"
			Endif
			
			Select GetFileType( src )
			
			Case FileType.File
			
				dst+=StripDir( src )
				EnumAssetFiles( src,dst,assetFiles )
				
			Case FileType.Directory
			
				EnumAssetFiles( src,dst,assetFiles )
			End
			
		Next
		
		If assetFiles.Empty Return
		
		DeleteDir( assetsDir,True )
		
		CreateDir( assetsDir )
		
		CopyAssetFiles( assetFiles )
	End

	Method CopyDlls( dllsDir:String )
	
		If Not dllsDir.EndsWith( "/" ) dllsDir+="/"
	
		For Local src:=Eachin DLL_FILES
		
			Local dir:=dllsDir
			
			Local ext:=ExtractExt( src )
			If ext
				Local rdir:=GetEnv( "MX2_APP_DIR_"+ext.Slice( 1 ).ToUpper() )
				If rdir 
					dir=RealPath( dir+rdir )
					If Not dir.EndsWith( "/" ) dir+="/"
				Endif
			Endif
			
			Local dst:=dir+StripDir( src )
			
			'FIXME! Hack for copying frameworks on macos!
			'		
#If __HOSTOS__="macos"
			If ExtractExt( src ).ToLower()=".framework"
				CreateDir( ExtractDir( dst ) )
				If Not Exec( "rm -f -R "+dst ) Throw New BuildEx( "rm failed" )
				If Not Exec( "cp -f -R "+src+" "+dst ) Throw New BuildEx( "cp failed" )
				Continue
			Endif
#Endif
			
			If Not CopyAll( src,dst ) Throw New BuildEx( "Failed to copy '"+src+"' to '"+dst+"'" )
			
		Next
	
	End
		
	Private
		
	Method CopyAll:Bool( src:String,dst:String )
		
		Select GetFileType( src )

		Case FILETYPE_FILE
		
			If Not CreateDir( ExtractDir( dst ) ) Return False
		
'			If GetFileTime( src )>GetFileTime( dst )
				If Not CopyFile( src,dst ) Return False
'			Endif
			
			Return True
			
		Case FILETYPE_DIR
		
			If Not CreateDir( dst ) Return False
			
			For Local file:=Eachin LoadDir( src )
				If Not CopyAll( src+"/"+file,dst+"/"+file ) Return False
			Next
			
			Return True
		
		End
		
		Return False
		
	End
	
	Method CopyAssetFiles( files:StringMap<String> )
	
		For Local it:=Eachin files
		
			Local src:=it.Value
			Local dst:=it.Key
			
			If CreateDir( ExtractDir( dst ) )
			
				'If GetFileTime( dst )>=GetFileTime( src ) Continue
				
				If CopyFile( src,dst ) Continue

			Endif
			
			Throw New BuildEx( "Error copying asset file '"+src+"' to '"+dst+"'" )
		Next
	End
	
	Method EnumAssetFiles( src:String,dst:String,files:StringMap<String> )

		Select GetFileType( src )

		Case FILETYPE_FILE
		
			If Not files.Contains( dst ) files[dst]=src
			
		Case FILETYPE_DIR
		
			For Local f:=Eachin LoadDir( src )
			
				EnumAssetFiles( src+"/"+f,dst+"/"+f,files )

			Next
		
		End
		
	End
		
End

Class GccBuildProduct Extends BuildProduct
	
	Field CC_CMD:=""
	Field CXX_CMD:=""
	Field AS_CMD:=""
	Field AR_CMD:=""
	Field LD_CMD:=""
	
	Method New( module:Module,opts:BuildOpts )
		
		Super.New( module,opts )
		
		Local target:="_"+opts.target.ToUpper()
		Local config:="_"+opts.config.ToUpper()
		
		Select opts.toolchain
		Case "msvc"
			
			CC_CMD= "cl -c"
			CXX_CMD="cl -c"
			AS_CMD=opts.arch="x64" ? "ml64 -c" Else "ml -c"
			AR_CMD="lib"
			LD_CMD="link"
			target="_MSVC"
			
		Case "gcc"
			
			Select opts.target
			Case "emscripten"
				
				CC_CMD= "emcc -c"
				CXX_CMD="em++ -c"
				AR_CMD="emar"
				LD_CMD="em++"
				
			Case "raspbian"

				CC_CMD= "arm-linux-gnueabihf-gcc -c"
				CXX_CMD="arm-linux-gnueabihf-g++ -c"
				AS_CMD= "arm-linux-gnueabihf-as"
				AR_CMD= "arm-linux-gnueabihf-ar"
				LD_CMD= "arm-linux-gnueabihf-g++"
				
			Default
				
				Local suffix:=GetEnv( "MX2_GCC_SUFFIX" )
				
				CC_CMD= "gcc"+suffix+" -c "
				CXX_CMD="g++"+suffix+" -c "
				AS_CMD= "as"
				AR_CMD= "ar"
				LD_CMD= "g++"+suffix+" "
				
			End
			
		Default
			
			RuntimeError( "Toolchain error: '"+opts.toolchain+"'" )
			
		End
		
		CC_CMD+=" "+GetEnv( "MX2_CC_OPTS"+target )+" "+GetEnv( "MX2_CC_OPTS"+target+config )
		CXX_CMD+=" "+GetEnv( "MX2_CPP_OPTS"+target )+" "+GetEnv( "MX2_CPP_OPTS"+target+config )
		AS_CMD+=" "+GetEnv( "MX2_AS_OPTS"+target )+" "+GetEnv( "MX2_AS_OPTS"+target+config )
		AR_CMD+=" "+GetEnv( "MX2_AR_OPTS"+target )+" "+GetEnv( "MX2_AR_OPTS"+target+config )
		LD_CMD+=" "+GetEnv( "MX2_LD_OPTS"+target )+" "+GetEnv( "MX2_LD_OPTS"+target+config )
		
	End
	
	Method CompileSource:String( src:String )
		
		Local ext:=ExtractExt( src ).ToLower(),cmd:="",isasm:=False

		Select ext
		Case ".c",".m"
			
			cmd=CC_CMD+CC_OPTS
			
		Case ".cc",".cxx",".cpp",".mm"
			
			cmd=CXX_CMD+CPP_OPTS
			
		Case ".asm",".s"
			
			cmd=AS_CMD+AS_OPTS
			
			If opts.toolchain="msvc"
				
				If opts.arch="x64" 
					src=src.Replace( "_i386_","_x86_64_" )
				Endif
					
				src=src.Replace( "_pe_gas.","_pe_masm." )
				
			Else If opts.target="ios"
				
				If src.Contains( "_arm64_" )
					cmd+=" -arch arm64"
				Else
					cmd+=" -arch armv7"
				Endif
				
			Endif
			
			isasm=True
		End
			
		Local rfile:=src.EndsWith( "/_r.cpp" )

'		Local obj:=module.cacheDir+MungPath( MakeRelativePath( src,module.cacheDir ) )
		Local obj:=module.cacheDir+MungPath( MakeRelativePath( src,module.cfileDir ) )
'		If rfile And opts.reflection obj+="_r"
		If rfile obj+="_r"
			
		obj+=opts.toolchain="msvc" ? ".obj" Else ".o"
	
		'Check dependancies
		'			
		Local objTime:=GetFileTime( obj )

		'create deps file name
		'			
		Local deps:=StripExt( obj )+".deps"
		
		If opts.fast And objTime>=GetFileTime( src )	'source file up to date?
		
			If isasm Return obj
			
			Local uptodate:=GetFileType( deps )=FileType.File
			
			If Not uptodate And opts.toolchain="gcc"

				If opts.verbose>0 Print "Scanning "+src
					
				Local tmp:=cmd
				
				'A bit dodgy - rip out -arch's from ios
				If opts.target="ios"
					
					Repeat
						Local i0:=tmp.Find( " -arch "  )
						If i0=-1 Exit
						Local i1:=tmp.Find( " ",i0+7 )
						If i1=-1 Exit
						tmp=tmp.Slice( 0,i0+1 )+tmp.Slice( i1+1 )
					Forever
					tmp+=" -arch armv7"
					
				Endif
				
				tmp+=" -MM ~q"+src+"~q >~q"+deps+"~q"
				
				Exec( tmp )
				
				uptodate=True
				
			Endif
			
			If uptodate
			
				Local srcs:=LoadString( deps ).Split( " \" )
						
				For Local i:=1 Until srcs.Length
						
					Local src:=srcs[i].Trim()
					If Not src Continue
					
					Local time:=GetFileTime( src )
					If Not time Or time>objTime
						uptodate=False
						Exit
					Endif
							
				Next
				
				If uptodate Return obj
				
			Endif
				
		Else
			
			DeleteFile( deps )

		Endif
			
		If opts.verbose>0 Print StripDir( src )
				
		If opts.toolchain="msvc"

			If isasm
				cmd+=" -Fo~q"+obj+"~q ~q"+src+"~q"
				Exec( cmd,opts.toolchain="msvc" )
				Return obj
			Endif
			
			Local fstdout:=AllocTmpFile( "stdout" )
			
			cmd+=" -showIncludes -Fo~q"+obj+"~q ~q"+src+"~q >"+fstdout
			
			If opts.verbose>2 Print cmd
				
			Local fstderr:=AllocTmpFile( "stderr" )
			
			If system( cmd+" 2>"+fstderr )

				Local buf:=New StringStack
				For Local line:=Eachin LoadString( fstdout,True ).Split( "~n" )
					If Not line.StartsWith( "Note: including file:" ) buf.Add( line )
				Next
				
				Local err:="System command failed:~n~n"+cmd+"~n~n"+buf.Join( "~n" )+"~n"
				
				err+=LoadString( fstderr,True )
				
				Throw New BuildEx( err )
				
			Endif
			
			Local tincs:=LoadString( fstdout )
			
			Local buf:=New StringStack
			buf.Push( StripDir( obj )+": "+src+" \" )

			For Local line:=Eachin tincs.Split( "~n" )
				
				line=line.Trim()
				
				If Not line.StartsWith( "Note: including file:" ) Continue
				
				line=line.Slice( 21 ).Trim()
				
				If line.ToLower().Contains( "\program files (x86)\" ) Continue
				
				line=line.Replace( "\","/" )
				
				buf.Add( line+" \" )
			Next
			
			Local str:=buf.Join( "~n" )
			
'			Print "deps="+str
			
			SaveString( str,deps )
			
			Return obj
		Endif

		cmd+=" -o ~q"+obj+"~q ~q"+src+"~q"
				
		Exec( cmd )
			
		Return obj
	End
	
	Method Build( srcs:StringStack ) Override
		
		Local objs:=New StringStack
		
		For Local src:=Eachin srcs
		
			objs.Push( CompileSource( src ) )
		Next
		
		objs.AddAll( OBJ_FILES )
		
		If opts.productType="module"
		
			BuildModule( objs )
		
		Else
		
			BuildApp( objs )
		End
	End
	
	Method BuildModule( objs:StringStack )

		Local output:=module.afile
		If opts.toolchain="msvc" output=StripExt(output)+".lib"

		Local maxObjTime:Long
		For Local obj:=Eachin objs
			maxObjTime=Max( maxObjTime,GetFileTime( obj ) )
		Next
		If GetFileTime( output )>maxObjTime Return
		
		If opts.verbose>=0 Print "Archiving "+output+"..."
		
		DeleteFile( output )
		
		Local cmd:="",args:=""
		For Local i:=0 Until objs.Length
			args+=" ~q"+objs.Get( i )+"~q"
		Next
		
		If opts.target="ios"
		
			cmd="libtool -o ~q"+output+"~q"+args
			
		Else If opts.toolchain="msvc"
			
			Local tmp:=AllocTmpFile( "libFiles" )
			SaveString( args,tmp )
			
			cmd="lib -out:~q"+output+"~q @~q"+tmp+"~q"

		Else

#If __TARGET__="windows"			

			Local tmp:=AllocTmpFile( "libFiles" )
			SaveString( args,tmp )
			
			cmd=AR_CMD+" q ~q"+output+"~q @~q"+tmp+"~q"
			
#Else
			cmd=AR_CMD+" q ~q"+output+"~q"+args
#Endif
		Endif
		
		Exec( cmd,opts.toolchain="msvc" )
			
	End
	
	Method BuildApp( objs:StringStack ) Virtual
		
		outputFile=opts.product
		If Not outputFile outputFile=module.outputDir+module.name
		
		Local productDir:=ExtractDir( outputFile )
		
		Local assetsDir:=productDir+"assets/"
		
		Local dllsDir:=productDir

		Local cmd:=LD_CMD+LD_OPTS
		
		Select opts.target
		Case "windows"
		
			If ExtractExt( outputFile ).ToLower()<>".exe" outputFile+=".exe"
				
			If opts.toolchain="msvc"
'				cmd+=" -entry:main"
				If opts.appType="gui" cmd+=" -subsystem:windows" Else cmd+=" -subsystem:console"
			Else
				If opts.appType="gui" cmd+=" -mwindows"
			Endif
			
		Case "macos"
		
			If opts.appType="gui"
			
				Local appDir:=outputFile
				If ExtractExt( appDir ).ToLower()<>".app" appDir+=".app"
				appDir+="/"
				
				Local appName:=StripExt( StripDir( outputFile ) )
				
				outputFile=appDir+"Contents/MacOS/"+appName
				assetsDir=appDir+"Contents/Resources/"
				dllsDir=ExtractDir( outputFile )
				
				If GetFileType( appDir )=FileType.None

					CreateDir( appDir )
					CreateDir( appDir+"Contents" )
					CreateDir( appDir+"Contents/MacOS" )
					CreateDir( appDir+"Contents/Resources" )
					
					Local plist:=""
					plist+="<?xml version=~q1.0~q encoding=~qUTF-8~q?>~n"
					plist+="<!DOCTYPE plist PUBLIC ~q-//Apple Computer//DTD PLIST 1.0//EN~q ~qhttp://www.apple.com/DTDs/PropertyList-1.0.dtd~q>~n"
					plist+="<plist version=~q1.0~q>~n"
					plist+="<dict>~n"
					plist+="~t<key>CFBundleExecutable</key>~n"
					plist+="~t<string>"+appName+"</string>~n"
					plist+="~t<key>CFBundleIconFile</key>~n"
					plist+="~t<string>"+appName+"</string>~n"
					plist+="~t<key>CFBundlePackageType</key>~n"
					plist+="~t<string>APPL</string>~n"
					plist+="~t<key>NSHighResolutionCapable</key> <true/>~n"
					plist+="</dict>~n"
					plist+="</plist>~n"
					
					SaveString( plist,appDir+"Contents/Info.plist" )
				
				Endif
			
			Endif
		
		Case "emscripten"

			assetsDir=module.outputDir+"assets/"
			
			If ExtractExt( outputFile ).ToLower()<>".js" And ExtractExt( outputFile ).ToLower()<>".html" outputFile+=".html"
			
			cmd+=" --preload-file ~q"+assetsDir+"@/assets~q"
			
'			If opts.appType.StartsWith( "wasm" ) cmd+=" -s BINARYEN=1 -s BINARYEN_TRAP_MODE='allow'"

			If opts.appType.StartsWith( "wasm" )
				Local wopts:=GetEnv( "MX2_LD_OPTS_EMSCRIPTEN_WASM" )
				If Not wopts wopts="-s BINARYEN=1 -s BINARYEN_TRAP_MODE='allow'"
				cmd+=" "+wopts
			Endif
		End
		
		If opts.verbose>=0 Print "Linking "+outputFile+"..."
			
		If opts.toolchain="msvc"
			cmd+=" -entry:mainCRTStartup -out:~q"+outputFile+"~q"
		Else
			cmd+=" -o ~q"+outputFile+"~q"
		Endif
		
		Local lnkFiles:=""
		
		For Local obj:=Eachin objs
			lnkFiles+=" ~q"+obj+"~q"
		Next
		
		For Local imp:=Eachin imports
			Local afile:=imp.afile
			If opts.toolchain="msvc" afile=StripExt(afile)+".lib"
			lnkFiles+=" ~q"+afile+"~q"
		Next

		lnkFiles+=" "+LIB_FILES.Join( " " )
		
#If __TARGET__="windows"
		lnkFiles=lnkFiles.Replace( " -Wl,"," " )
		Local tmp:=AllocTmpFile( "lnkFiles" )
		SaveString( lnkFiles,tmp )
		cmd+=" @"+tmp
#Else
		cmd+=lnkFiles
#Endif
		CreateDir( productDir,True )
		
		CopyAssets( assetsDir )
		
		CopyDlls( dllsDir )
		
		Exec( cmd,opts.toolchain="msvc" )
		
		If opts.target="emscripten"
			If opts.appType="wasm"
				DeleteFile( StripExt( outputFile )+".asm.js" )
			Endif
		Endif

	End
	
	Method Run() Override
	
		Local run:=""
		Select opts.target
		Case "emscripten"
			Local mserver:=GetEnv( "MX2_MSERVER" )
			run=mserver+" ~q"+outputFile+"~q"
		Default
			run="~q"+outputFile+"~q"
		End
		
		If opts.verbose>=0 Print "Running "+outputFile
			
		Exec( run )
	End
	
End

Class IosBuildProduct Extends GccBuildProduct

	Method New( module:Module,opts:BuildOpts )
	
		Super.New( module,opts )
	End
	
	Method BuildApp( objs:StringStack ) Override
	
		BuildModule( objs )
		
		Local arc:=module.afile

		Local outputFile:=opts.product+"libmx2_main.a"
		
		Local cmd:="libtool -static -o ~q"+outputFile+"~q ~q"+arc+"~q"
		
		If opts.wholeArchive cmd+=" -Wl,--whole-archive"
		
		For Local imp:=Eachin imports
			cmd+=" ~q"+imp.afile+"~q"
		Next

		If opts.wholeArchive cmd+=" -Wl,--no-whole-archive"
		
		For Local lib:=Eachin LIB_FILES
			If lib.ToLower().EndsWith( ".a~q" ) cmd+=" "+lib
		Next
		
		Exec( cmd )
		
		CopyAssets( opts.product+"assets/" )
	End
	
	Method Run() Override
	End
	
End

Function SplitOpts:String[]( opts:String )

	Local out:=New StringStack

	Local i0:=0
	Repeat
	
		While i0<opts.Length And opts[i0]<=32
			i0+=1
		Wend
		If i0>=opts.Length Exit

		Local i1:=opts.Find( " ",i0 )
		If i1=-1 i1=opts.Length

		Local i2:=opts.Find( "~q",i0 )
		If i2<>-1 And i2<i1
			i1=opts.Find( "~q",i2+1 )+1
			If Not i1 i1=opts.Length
		Endif

		out.Push( opts.Slice( i0,i1 ) )
		i0=i1+1
	
	Forever
	
	Return out.ToArray()
End

Class AndroidBuildProduct Extends BuildProduct

	Method New( module:Module,opts:BuildOpts )

		Super.New( module,opts )
	End
	
	Method Build( srcs:StringStack ) Override
	
		Local jniDir:=module.outputDir+"jni/"
		
		If Not CreateDir( jniDir ) Throw New BuildEx( "Failed to create dir '"+jniDir+"'" )
	
		Local buf:=New StringStack
		
		buf.Push( "APP_OPTIM := "+opts.config )
		
		buf.Push( "APP_ABI := "+GetEnv( "MX2_ANDROID_APP_ABI","armeabi-v7a" ) )
		
		buf.Push( "APP_PLATFORM := "+GetEnv( "MX2_ANDROID_APP_PLATFORM","android-14" ) )
		
		buf.Push( "APP_CFLAGS := "+GetEnv( "MX2_ANDROID_APP_CFLAGS","-std=gnu99 -fno-stack-protector" ) )
		
		buf.Push( "APP_CPPFLAGS := "+GetEnv( "MX2_ANDROID_APP_CPPFLAGS","-std=c++11 -fno-stack-protector -frtti -fexceptions" ) )
		
		buf.Push( "APP_STL := "+GetEnv( "MX2_ANDROID_APP_STL","c++_static" ) )
		
		#rem
		buf.Push( "APP_CFLAGS += -std=gnu99" )
		buf.Push( "APP_CFLAGS += -fno-stack-protector" )
		
		buf.Push( "APP_CPPFLAGS += -std=c++11" )
		buf.Push( "APP_CPPFLAGS += -frtti" )
		buf.Push( "APP_CPPFLAGS += -fexceptions" )
		buf.Push( "APP_CPPFLAGS += -fno-stack-protector" )
		
		buf.Push( "APP_STL := c++_static" )
		
		#end
		
		CSaveString( buf.Join( "~n" ),jniDir+"Application.mk" )
		
		buf.Clear()

		buf.Push( "LOCAL_PATH := $(call my-dir)" )
		
		If opts.productType="app"
		
			For Local imp:=Eachin imports
			
				Local src:=imp.outputDir+"obj/local/$(TARGET_ARCH_ABI)/libmx2_"+imp.name+".a"
					
				buf.Push( "include $(CLEAR_VARS)" )
				buf.Push( "LOCAL_MODULE := mx2_"+imp.name )
				buf.Push( "LOCAL_SRC_FILES := "+src )
				buf.Push( "include $(PREBUILT_STATIC_LIBRARY)" )
			Next
			
			For Local dll:=Eachin DLL_FILES
			
				buf.Push( "include $(CLEAR_VARS)" )
				buf.Push( "LOCAL_MODULE := "+StripDir( dll ) )
				buf.Push( "LOCAL_SRC_FILES := "+dll )
				buf.Push( "include $(PREBUILT_SHARED_LIBRARY)" )
			
			Next
			
		Endif
		
		buf.Push( "include $(CLEAR_VARS)" )
		
		If opts.productType="app"
			buf.Push( "LOCAL_MODULE := mx2_main" )
		Else
			buf.Push( "LOCAL_MODULE := mx2_"+module.name )
		Endif
		
		Local cc_opts:=SplitOpts( CC_OPTS )
		
		For Local opt:=Eachin cc_opts
			If opt.StartsWith( "-I" ) Or opt.StartsWith( "-D" ) buf.Push( "LOCAL_CFLAGS += "+opt )
		Next
		
		buf.Push( "LOCAL_SRC_FILES := \" )
		
		For Local src:=Eachin srcs
			buf.Push( MakeRelativePath( src,jniDir )+" \" )
'			buf.Push( MakeRelativePath( src,module.cfileDir )+" \" )
		Next
		
		buf.Push( "" )

		buf.Push( "LOCAL_CFLAGS += -DGL_GLEXT_PROTOTYPES" )
		
		If opts.productType="app"
		
			Local whole_libs:=""
		
			buf.Push( "LOCAL_STATIC_LIBRARIES := \" )
			For Local imp:=Eachin imports
				If imp=module Continue
				
				If imp.name="sdl2" 'Or imp.name="admob" 'Or imp.name="std"
					whole_libs+=" mx2_"+imp.name
					Continue
				Endif
				
				buf.Push( "mx2_"+imp.name+" \" )
			Next
			buf.Push( "" )
			
			If whole_libs
				'
				'This keeps the JNI functions in sdl2 and admob alive: ugly, ugly stuff but that's the joys of modern coding for ya...
				'
				buf.Push( "LOCAL_WHOLE_STATIC_LIBRARIES :="+whole_libs )
			Endif

			buf.Push( "LOCAL_SHARED_LIBRARIES := \" )
			For Local dll:=Eachin DLL_FILES
				buf.Push( StripDir( dll )+" \" )
			Next
			buf.Push( "" )
			
			buf.Push( "LOCAL_LDLIBS += -ldl" )
			
			For Local lib:=Eachin LIB_FILES
				If lib.StartsWith( "-l" ) buf.Push( "LOCAL_LDLIBS += "+lib )
			Next
			
			buf.Push( "LOCAL_LDLIBS += -llog -landroid" )

			buf.Push( "include $(BUILD_SHARED_LIBRARY)" )
		Else

			buf.Push( "include $(BUILD_STATIC_LIBRARY)" )
		Endif
		
		CSaveString( buf.Join( "~n" ),jniDir+"Android.mk" )
		buf.Clear()
		
		Local cd:=CurrentDir()
		
		ChangeDir( module.outputDir )
		
		Exec( "ndk-build" )
		
		ChangeDir( cd )
		
		If opts.productType="app" And opts.product
		
			For Local jfile:=Eachin JAVA_FILES
			
				Local src:=LoadString( jfile )
				If Not src Continue
				
				Local i0:=src.Find( "package " )
				If i0=-1 Continue
				
				Local i1:=src.Find( ";",i0+8 )
				If i1=-1 Continue
				
				Local pkg:=src.Slice( i0+8,i1 ).Trim()
				If Not pkg Continue
				
				Local dstDir:=opts.product+"app/src/main/java/"+pkg.Replace( ".","/" )
				
				CreateDir( dstDir,True )
				
				CopyFile( jfile,dstDir+"/"+StripDir( jfile ) )
			Next
		
			CopyAssets( opts.product+"app/src/main/assets/" )
		
			CopyDir( module.outputDir+"libs",opts.product+"app/src/main/jniLibs" )
		
		Endif
		
	End
	
End
