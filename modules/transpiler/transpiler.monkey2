
Namespace mx2cc

#Import "<std>"

#Import "toolchain"
#Import "mx2"

#Import "newdocs/docsnode"
#Import "newdocs/docsbuffer"
#Import "newdocs/docsmaker"
#Import "newdocs/markdown"

Using mx2.newdocs

#Import "geninfo/geninfo"

Using libc..
Using std..
Using mx2..

Const MX2CC_VERSION_EXT:=""

Global opts_time:Bool

Global StartDir:String

'Const TestArgs:="mx2cc makemods -config=debug mojo3d"' -clean -config=debug monkey libc miniz stb-image stb-image-write stb-vorbis std"
 
Const TestArgs:="mx2cc makeapp -clean -config=debug src/mx2cc/test.monkey2"

Class Transpiler
	
	Property Version:String()
		Return MX2CC_VERSION+MX2CC_VERSION_EXT
	End
	
	Property About:String()
		Return "mx2 transpiler version "+Version
	End
	
	Field tempDir:String
	Field compiler:Toolchain

	Function DefaultOpts:BuildOpts()
		Local opts:=New BuildOpts	
#if __TARGET__="windows"
		opts.toolchain="msvc"
		opts.target="windows"
#else
		opts.toolchain="gcc"
		opts.target="macos"
#endif
		opts.arch="x64"
		opts.config="release"
		Return opts
	End

	Method New(toolchain:Toolchain, tempdir:String)
		Self.compiler=toolchain
		Self.tempDir=tempdir
		'Set aside 64M for GC
		GCSetTrigger( 128*1024*1024 )
		ModDirs()
	End
							
	Method ModDirs()
		Local moddirs:=New StringStack
		moddirs.Add( CurrentDir()+"modules/" )
		For Local moddir:=Eachin GetEnv( "MX2_MODULE_DIRS" ).Split( ";" )
			moddir=moddir.Replace( "\","/" )
			If GetFileType( moddir )<>FileType.Directory Continue
			moddir=RealPath( moddir )
			If Not moddir.EndsWith( "/" ) moddir+="/"
			If Not moddirs.Contains( moddir ) moddirs.Add( moddir )
		Next
		Module.Dirs=moddirs.ToArray()
	End

	Property Usage:String()
		Local usage:=New List<String>
		usage.Add("mx2cc usage: mx2cc action options sources")
		usage.Add("")
		usage.Add("Actions:")
		usage.Add("  makeapp      - make an application.")
		usage.Add("  makemods     - make modules.")
		usage.Add("  makedocs     - make docs.")
		usage.Add("")
		usage.Add("Options:")
		usage.Add("  -quiet       - emit less info when building.")
		usage.Add("  -verbose     - emit more info when building.")
		usage.Add("  -parse       - parse only.")
		usage.Add("  -semant      - parse and semant.")
		usage.Add("  -translate   - parse, semant and translate.")
		usage.Add("  -build       - parse, semant, translate and build.")
		usage.Add("  -run         - the works! The default.")
		usage.Add("  -apptype=    - app type to make, one of : gui, console. Defaults to gui.")
		usage.Add("  -target=     - build target, one of: windows, macos, linux, emscripten, wasm, android, ios, desktop. Desktop is an alias for current host. Defaults to desktop.")
		usage.Add("  -config=     - build config, one of: debug, release. Defaults to debug.")
		usage.Add("")
		usage.Add("Sources:")
		usage.Add("  for makeapp  - single monkey2 source file.")
		usage.Add("  for makemods - space separated list of modules, or nothing to make all modules.")
		usage.Add("  for makedocs - space separated list of modules, or nothing to make all docs.")
		Return usage.Join("~n")
	End
	
	Method MakeApp:Bool( dirs:String[], args:String[] )

		Module.Dirs=dirs
	
		Local opts:=DefaultOpts()
		opts.productType="app"
		opts.clean=False
		opts.fast=True
		opts.verbose=0
		opts.passes=4
		
		args=ParseOpts( opts,args )		
		If args.Length<>1 
			Print( "Invalid app source file" )
			Return False
		Endif
		
		Local cd:=CurrentDir()
		ChangeDir( StartDir )
		
		'DebugStop()
		
		Local srcPath:=RealPath( args[0].Replace( "\","/" ) )
		
		ChangeDir( cd )
		
		opts.mainSource=srcPath
		
		Print "Making app "+opts.mainSource+" ("+opts.target+" "+opts.config+" "+opts.arch+" "+opts.toolchain+" "+opts.productType+")"
	
		New BuilderInstance( compiler, opts )
		
		Builder.Parse()
		If opts.passes=1 
			If opts.geninfo
				Local gen:=New ParseInfoGenerator
				Local jobj:=gen.GenParseInfo( Builder.mainModule.fileDecls[0] )
				Print jobj.ToJson()
			Endif
			Return True
		Endif
		If Builder.errors.Length Return False
		
		Builder.Semant()
		If Builder.errors.Length Return False
		If opts.passes=2
			Return True
		Endif
		
		Builder.Translate()
		If Builder.errors.Length Return False
		If opts.passes=3 
			Return True
		Endif
		
		Builder.product.Build()
		If Builder.errors.Length Return False
		If opts.passes=4
			Print "Application built:"+Builder.product.outputFile
			Return True
		Endif
		
		Builder.product.Run()
		Return True
	End
		
	Method MakeMods:Bool( dirs:String[], args:String[] )
		
		Print "MakeMods x " + dirs.Length
		Module.Dirs=dirs
	
		Local opts:=DefaultOpts()
		opts.productType="module"
		opts.clean=True
		opts.fast=True
		opts.verbose=0
		opts.passes=4		

		args=ParseOpts( opts,args )
		
		If Not args args=EnumModules()
		
		Local errs:=0
		
		Local target:=opts.target
		
		For Local modid:=Eachin args
			
			Local path:=""
			For Local moddir:=Eachin Module.Dirs
				path=moddir+modid+"/"+modid+".monkey2"
				If GetFileType( path )=FileType.File Exit
				path=""
			Next

			If Not path 
				Print "Module '"+modid+"' not found"
				Continue
			Endif
		
			Print "Making "+modid+" ("+opts.target+" "+opts.config+" "+opts.arch+" "+opts.toolchain+")"
			
			opts.mainSource=RealPath( path )
			opts.target=target
			
			New BuilderInstance( compiler,opts )
			
			Builder.Parse()
			If Builder.errors.Length errs+=1;Continue
			If opts.passes=1 Continue
	
			Builder.Semant()
			If Builder.errors.Length errs+=1;Continue
			If opts.passes=2 Continue
			
			Builder.Translate()
			If Builder.errors.Length errs+=1;Continue
			If opts.passes=3 Continue
			
			Builder.product.Build()
			If Builder.errors.Length errs+=1;Continue
		Next
		
		Return errs=0
	End
	
	Method MakeDocs:Bool( args:String[] )
	
		Local opts:=DefaultOpts()
		opts.productType="module"
		opts.target="desktop"
		opts.config="debug"
		opts.clean=False
		opts.fast=True
		opts.verbose=0
		opts.passes=2
		opts.makedocs=true
		
		args=ParseOpts( opts,args )
		
		opts.clean=False
		
		If Not args args=EnumModules()
	
		Local docsDir:=RealPath( "docs" )+"/"
		
		Local pageTemplate:=LoadString( "docs/new_docs_page_template.html" )
		
		Local docsMaker:=New DocsMaker( docsDir,pageTemplate )
	
		Local errs:=0
		
		For Local modid:=Eachin args
			
			Local path:=""
			For Local moddir:=Eachin Module.Dirs
				path=moddir+modid+"/"+modid+".monkey2"
				If GetFileType( path )=FileType.File Exit
				path=""
			Next
			If Not path 
				Print( "Module '"+modid+"' not found" )
				Continue
			Endif
		
			Print "Doccing module '"+modid+"'"
			
			opts.mainSource=RealPath( path )
			
			New BuilderInstance( compiler, opts )
	
			Builder.Parse()
			If Builder.errors.Length errs+=1;Continue
			
			Builder.Semant()
			If Builder.errors.Length errs+=1;Continue
	
			Local module:=Builder.modules.Top
			
			docsMaker.CreateModuleDocs( module )
			
		Next
		
		Local buf:=New StringStack
		Local modsbuf:=New StringStack
		
		For Local modid:=Eachin EnumModules()
	
			Local index:=LoadString( "docs/modules/"+modid+"/manual/index.js" )
			If index and Not index.Trim() Print "module OOPS modid="+modid
			If index buf.Push( index )
			
			index=LoadString( "docs/modules/"+modid+"/module/index.js" )
			If index and Not index.Trim() Print "manual OOPS modid="+modid
			If index modsbuf.Push( index )
		Next
		
		buf.Add( "{text:'Modules reference',children:[~n"+modsbuf.Join( "," )+"]}~n" )
		
		Local tree:=buf.Join( "," )
		
		Local page:=LoadString( "docs/new_docs_template.html" )
		page=page.Replace( "${DOCS_TREE}",tree )
		SaveString( page,"docs/newdocs.html" )
		
		Return True
	End
	
	
	Function EnumModules( out:StringStack,cur:String,src:String,deps:StringMap<StringStack> )
		
		If Not deps.Contains( cur )
			Print "Can't find module dependancy '"+cur+"' - check module.json file for '"+src+"'"
			Return
		End
		
		If out.Contains( cur ) Return
		
		For Local dep:=Eachin deps[cur]
			EnumModules( out,dep,cur,deps )
		Next
		
		out.Push( cur )
	End
	
	Function EnumModules:String[]()
	
		Local mods:=New StringMap<StringStack>
		
		For Local moddir:=Eachin Module.Dirs
			
			For Local f:=Eachin LoadDir( moddir )
			
				Local dir:=moddir+f+"/"
				If GetFileType( dir )<>FileType.Directory Continue
				
				Local str:=LoadString( dir+"module.json" )
				If Not str Continue
				
				Local obj:=JsonObject.Parse( str )
				If Not obj 
					Print "Error parsing json:"+dir+"module.json"
					Continue
				Endif
				
				Local name:=obj["module"].ToString()
				If name<>f Continue
				
				Local deps:=New StringStack
				If name<>"monkey" deps.Push( "monkey" )
				
				Local jdeps:=obj["depends"]
				If jdeps
					For Local dep:=Eachin jdeps.ToArray()
						deps.Push( dep.ToString() )
					Next
				Endif
				
				mods[name]=deps
			Next
		
		Next
		
		Local out:=New StringStack
		For Local cur:=Eachin mods.Keys
			EnumModules( out,cur,"",mods )
		Next
		
		Return out.ToArray()
	End


	Function ParseOpts:String[]( opts:BuildOpts,args:String[] )
		Return args
	End

#rem		
	Function ParseOpts:String[]( opts:BuildOpts,args:String[] )
	
		Global done:=False
		Assert( Not done )
		done=True
		
		opts.verbose=Int( GetEnv( "MX2_VERBOSE" ) )
		
		Local i:=0
		
		For i=0 Until args.Length
		
			Local arg:=args[i]
		
			Local j:=arg.Find( "=" )
			If j=-1 
				Select arg
				Case "-run"
					opts.passes=5
				Case "-build"
					opts.passes=4
				Case "-translate"
					opts.passes=3
				Case "-semant"
					opts.passes=2
				Case "-parse"
					opts.passes=1
				Case "-clean"
					opts.clean=True
				Case "-quiet"
					opts.verbose=-1
				Case "-verbose"
					opts.verbose=1
				Case "-geninfo"
					opts.geninfo=True
				Case "-time"
					opts_time=True
				Default
					' simon come here
					Print "FAIL"
'					If arg.StartsWith( "-" ) Fail( "Unrecognized option '"+arg+"'" )
'					Exit
				End
				Continue
			Endif
			
			Local opt:=arg.Slice( 0,j ),val:=arg.Slice( j+1 )
			
			Local path:=val.Replace( "\","/" )
			If path.StartsWith( "~q" ) And path.EndsWith( "~q" ) path=path.Slice( 1,-1 )
			
			val=val.ToLower()
			
			Select opt
			Case "-product"
				opts.product=path
			Case "-apptype"
				opts.appType=val
			Case "-target"
				Select val
				Case "desktop","windows","macos","linux","raspbian","emscripten","android","ios"
					opts.target=val
				Default
					Fail( "Invalid value for 'target' option: '"+val+"' - must be 'desktop', 'raspbian', 'emscripten', 'android' or 'ios'" )
				End
			Case "-config"
				Select val
				Case "debug","release"
					opts.config=val
				Default
					Fail( "Invalid value for 'config' option: '"+val+"' - must be 'debug' or 'release'" )
				End
			Case "-verbose"
				Select val
				Case "0","1","2","3","-1"
					opts.verbose=Int( val )
				Default
					Fail( "Invalid value for 'verbose' option: '"+val+"' - must be '0', '1', '2', '3' or '-1'" )
				End
			Default
				Fail( "Invalid option: '"+opt+"'" )
			End
		
		Next
		args=args.Slice( i )
		
		If Not opts.target Or opts.target="desktop" opts.target=HostOS
			
		opts.wholeArchive=Int( GetEnv( "MX2_WHOLE_ARCHIVE" ) )
			
		opts.toolchain="gcc"
			
		Select opts.target
		Case "windows"
			
			If Not opts.appType opts.appType="gui"
			
			opts.arch=GetEnv( "MX2_ARCH_"+opts.target.ToUpper(),"x86" )
			
			If opts.arch<>"x64" And opts.arch<>"x86"
				Fail( "Unrecognized architecture '"+opts.arch+"'" )
			Endif
			
			If Int( GetEnv( "MX2_USE_MSVC" ) )
				
				opts.toolchain="msvc"
				
				Local arch:=opts.arch.ToUpper()
				
				SetEnv( "PATH",GetEnv( "MX2_MSVC_PATH_"+arch )+";"+GetEnv( "PATH" ) )
				SetEnv( "INCLUDE",GetEnv( "MX2_MSVC_INCLUDE_"+arch ) )
				SetEnv( "LIB",GetEnv( "MX2_MSVC_LIB_"+arch ) )
				
			Endif
		
			If opts.arch="x64" And opts.toolchain<>"msvc"
				Fail( "x64 builds for windows currently only supported for msvc" )
			Endif
			
		Case "macos","linux"
			
			If Not opts.appType opts.appType="gui"
			
			opts.arch="x64"
			
		Case "raspbian"
	
			If Not opts.appType opts.appType="gui"
				
			opts.arch="arm32"
				
			SetEnv( "PATH",GetEnv( "MX2_RASPBIAN_TOOLS" )+";"+GetEnv( "PATH" ) )
			
		Case "emscripten"
			
			If Not opts.appType opts.appType="wasm"
				
			opts.arch="llvm"
			
		Case "android"
			
			opts.arch=GetEnv( "MX2_ANDROID_APP_ABI","armeabi-v7a" )
			
		Case "ios"
			
			opts.arch="arm64"
			
		Default
			
			Fail( "Unrecognized target '"+opts.target+"'" )
		
		End
		
		Select opts.appType
		Case "console","gui"
			
			Select opts.target
			Case "windows","macos","linux","raspbian"
			Default
				Fail( "apptype '"+opts.appType+"' is only valid for desktop targets" )
			End
			
		case "wasm","asmjs","wasm+asmjs"
			
			If opts.target<>"emscripten" Fail( "apptype '"+opts.appType+"' is only valid for emscripten target" )
				
		case ""
		Default
			Fail( "Unrecognized apptype '"+opts.appType+"'" )
		End
			
		Return args
	End

WindowsLibPath=C:\Program Files (x86)\Windows Kits\10\UnionMetadata;C:\Program Files (x86)\Windows Kits\10\References
WindowsSdkDir=C:\Program Files (x86)\Windows Kits\10\
WindowsSDKLibVersion=10.0.16299.0\
WindowsSDKVersion=10.0.16299.0\
WindowsSDK_ExecutablePath_x64=C:\Program Files (x86)\Microsoft SDKs\Windows\v10.0A\bin\NETFX 4.6.1 Tools\x64\
WindowsSDK_ExecutablePath_x86=C:\Program Files (x86)\Microsoft SDKs\Windows\v10.0A\bin\NETFX 4.6.1 Tools\
#end
#rem
	Function Main2()
		
	'	Print "YARGH!"
		
	'	Return
	
		Local vec2i:=New Vec2i
		Local vec3f:=New Vec3f
	
		'Set aside 64M for GC!
		GCSetTrigger( 64*1024*1024 )
		
		Print ""
		Print "Mx2cc version "+MX2CC_VERSION+MX2CC_VERSION_EXT
		
		StartDir=CurrentDir()
		
		ChangeDir( AppDir() )
		
		Local env:="bin/env_"+HostOS+".txt"
		
		While Not IsRootDir( CurrentDir() ) And GetFileType( env )<>FILETYPE_FILE
		
			ChangeDir( ExtractDir( CurrentDir() ) )
		Wend
		
		If GetFileType( env )<>FILETYPE_FILE Fail( "Unable to locate mx2cc 'bin' directory" )
	
		CreateDir( "tmp" )
		
		Local args:String[]
	
	#If __CONFIG__="debug"
	'	Local tenv:="bin/env_"+HostOS+"_dev.txt"
	'	If GetFileType( tenv )=FileType.File env=tenv
		args=TestArgs.Split( " " )
	#else
		args=AppArgs()
	#endif
	
		For Local i:=0 Until args.Length
			If args[i]="-target=ios"
				system( "xcrun --sdk iphoneos --show-sdk-path >tmp/_p.txt" )
				Local p:=LoadString( "tmp/_p.txt" ).Trim()
				SetEnv( "MX2_IOS_SDK",p )
				'Print "MX2_IOS_SDK="+p
				Exit
			Endif
		Next
		
		LoadEnv( env )
		
		Local moddirs:=New StringStack
		moddirs.Add( CurrentDir()+"modules/" )
		For Local moddir:=Eachin GetEnv( "MX2_MODULE_DIRS" ).Split( ";" )
			moddir=moddir.Replace( "\","/" )
			If GetFileType( moddir )<>FileType.Directory Continue
			moddir=RealPath( moddir )
			If Not moddir.EndsWith( "/" ) moddir+="/"
			If Not moddirs.Contains( moddir ) moddirs.Add( moddir )
		Next
		Module.Dirs=moddirs.ToArray()
		
		If args.Length<2
	
			Print ""
			Print "Mx2cc usage: mx2cc action options sources"
			Print ""
			Print "Actions:"
			print "  makeapp      - make an application."
			print "  makemods     - make modules."
			print "  makedocs     - make docs."
			Print ""
			Print "Options:"
			Print "  -quiet       - emit less info when building."
			Print "  -verbose     - emit more info when building."
			Print "  -parse       - parse only."
			Print "  -semant      - parse and semant."
			Print "  -translate   - parse, semant and translate."
			Print "  -build       - parse, semant, translate and build."
			Print "  -run         - the works! The default."
			Print "  -apptype=    - app type to make, one of : gui, console. Defaults to gui."
			print "  -target=     - build target, one of: windows, macos, linux, emscripten, wasm, android, ios, desktop. Desktop is an alias for current host. Defaults to desktop."
			Print "  -config=     - build config, one of: debug, release. Defaults to debug."
			Print ""
			Print "Sources:"
			Print "  for makeapp  - single monkey2 source file."
			Print "  for makemods - space separated list of modules, or nothing to make all modules."
			Print "  for makedocs - space separated list of modules, or nothing to make all docs."
	
	#If __DESKTOP_TARGET__
			If Int( GetEnv( "MX2_USE_MSVC" ) )
				system( "cl > tmp\_v.txt" )		'doesn't work?
				Print ""
				Print "Mx2cc using cl version:"
				Print ""
				Print LoadString( "tmp/_v.txt" )
			Else
				system( "g++ --version >tmp/_v.txt" )
				Print ""
				Print "Mx2cc using g++ version:"
				Print ""
				Print LoadString( "tmp/_v.txt" )
			Endif
	#Endif
	'		exit_( 0 )
			Return
		Endif
	
		Local ok:=False
	
		Try
		
			Local cmd:=args[1]
			args=args.Slice( 2 )
			
			Local start:=std.time.Now()
			
			Select cmd
			Case "makeapp"
				ok=MakeApp( args )
			Case "makemods"
				ok=MakeMods( args )
			Case "makedocs"
				ok=MakeDocs( args )
			Default
				Fail( "Unrecognized mx2cc command: '"+cmd+"'" )
			End
			
			Local elapsed:=std.time.Now()-start
			
			If opts_time Print "Elapsed time="+elapsed
			
		Catch ex:BuildEx
		
			Fail( "Internal mx2cc build error" )
		End
		
		If Not ok libc.exit_( 1 )
	End


	Function LoadEnv:Bool( path:String )
	
		SetEnv( "MX2_HOME",CurrentDir() )
		SetEnv( "MX2_MODULES",CurrentDir()+"modules" )
	
		Local lineid:=0
		
		For Local line:=Eachin stringio.LoadString( path ).Split( "~n" )
			lineid+=1
			
			line=line.Trim()
			If Not line Or line.StartsWith( "'" ) Or line.StartsWith( "#" ) Continue
		
			Local i:=line.Find( "=" )
			If i=-1 Fail( "Env config file error at line "+lineid )
			
			Local name:=line.Slice( 0,i ).Trim()
			Local value:=line.Slice( i+1 ).Trim()
			
			value=ReplaceEnv( value,lineid )
			
			SetEnv( name,value )
	
		Next
		
		Return True
	End



	Function ReplaceEnv:String( str:String,lineid:Int )
		Local i0:=0
		Repeat
			Local i1:=str.Find( "${",i0 )
			If i1=-1 Return str
			
			Local i2:=str.Find( "}",i1+2 )
			If i2=-1 Fail( "Env config file error at line "+lineid )
			
			Local name:=str.Slice( i1+2,i2 ).Trim()
			Local value:=GetEnv( name )
			
			str=str.Slice( 0,i1 )+value+str.Slice( i2+1 )
			i0=i1+value.Length
		Forever
		Return ""
	End
	
	Function Fail( msg:String )
	'	Mx2ccError=msg
	End

#end

End
