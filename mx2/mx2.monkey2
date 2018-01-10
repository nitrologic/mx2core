#Import "<transpiler>"

#if __TARGET__="windows"
Global TempPath:=std.filesystem.GetEnv("TEMP")
Global VS140Path:=std.filesystem.GetEnv("VS140COMNTOOLS")
#else
Global TempPath:="/tmp"
Global VS140Path:="."
#endif

Class VisualStudio Implements mx2.Toolchain

	Method New()
'		std.filesystem.SetEnv("AMD64Path",VS140Path+"..\..\VC\bin\amd64\")
		std.filesystem.SetEnv("MX2_CPP_OPTS_MSVC","-EHsc -W0 -MT -utf-8")
		std.filesystem.SetEnv("MX2_CPP_OPTS_MSVC_DEBUG","-O1")
		std.filesystem.SetEnv("MX2_CPP_OPTS_MSVC_RELEASE","-O2 -DNDEBUG")
	End
		
	Method Invoke:Int(command:String)
'		Local vsdevcmd:=VS140Path+"VsDevCmd.bat"
		Local vsdevcmd:=VS140Path+"..\..\VC\vcvarsall.bat"
		Local cmd:="call ~q"+vsdevcmd+"~q x64 && ("+command+")"
		Local result:=libc.system(cmd)
		If result Print "MX2 ERROR "+cmd+" returned "+result		
		Return result
	End	
			
	Method About:String()
		Local temp:=TempPath + "\getcl.txt"
		Local result:=Invoke("cl > ~q"+temp+"~q 2>&1")
		If result Return ""
		Local about:=std.stringio.LoadString(temp.Replace("\","/"))
		about=about.Replace("~r~n","~n")
		Return about
	End

	Method Help:String()
		Local temp:=TempPath + "\getcl.txt"
		Local result:=Invoke("cl -help > ~q"+temp+"~q 2>&1")
		If result Return ""
		Local about:=std.stringio.LoadString(temp.Replace("\","/"))
		about=about.Replace("~r~n","~n")
		Return about
	End

	Method Assemble:Int(cmd:String)	
		Local temp:=TempPath + "\as.txt"
		Local result:=Invoke(cmd+" > ~q"+temp+"~q 2>&1")
		If result
			Local about:=std.stringio.LoadString(temp.Replace("\","/"))
			about=about.Replace("~r~n","~n")
			Print about
		Endif
		Return result
	End

	Method Compile:Int(cmd:String)
		Local temp:=TempPath + "\cl.txt"
		Local result:=Invoke(cmd+" > ~q"+temp+"~q 2>&1")
		If result
			Local about:=std.stringio.LoadString(temp.Replace("\","/"))
			about=about.Replace("~r~n","~n")
			Print about
		Endif
		Return result
	End
	
	Method Link:Int(cmd:String)
		Local temp:=TempPath + "\ln.txt"
		Local result:=Invoke(cmd+" > ~q"+temp+"~q 2>&1")
		If result
			Local about:=std.stringio.LoadString(temp.Replace("\","/"))
			about=about.Replace("~r~n","~n")
			Print about
		Endif
		Return result
	End

	Method Archive:Int(cmd:String)
		Print "ARCHIVING:"+cmd
		Return Invoke(cmd)
	End

'		Local result:=system( cmd+" 2>"+fstderr )			
'		Return result
	
End


Class GCC Implements mx2.Toolchain

	Method Invoke:Int(command:String)
		Local result:=libc.system(command)
		If result Print command + " returned " + result
		Return result
	End	

	method Help:String()
		Local temp:=TempPath + "/g++help.txt"
		Local cmd:="g++ --help > ~q"+temp+"~q 2>&1"
		Local result:=Invoke(cmd)
		If result
			return ""
		endif
		Return std.stringio.LoadString(temp)
	End
	
	Method Assemble:Int(cmd:String)	
		Return Invoke(cmd)
	End

	Method Compile:Int(cmd:String)
		Return Invoke(cmd)
	End

	Method Archive:Int(cmd:String)
		Return Invoke(cmd)
	End

	Method Link:Int(cmd:String)
		Return Invoke(cmd)
	End
End

Function ModulePaths:String[](path:String)
	Local result:=New std.collections.List<String>
	result.Add(path+"modules/")
	Return result.ToArray()
End

Function MonkeyPath:String(path:String)
	While path
		Local filepath:=path+"/modules.json"
		If std.filesystem.GetFileType(filepath)=1
			Exit
		Endif
		path=std.filesystem.RealPath(path+"/../")
	Wend
	Return path
End


Function Main()

#if __TARGET__="windows"	
	Local cl:=New VisualStudio()
#else
	Local cl:=New GCC()
#endif

'	Print "Toolchain:"+cl.About()
'	Print "Toolchain:"+cl.Compiler
'	Print "Toolchain:"+cl.Help()
	BuildAll(cl)
End

Function BuildAll(cl:mx2.Toolchain)
	Local mx2:=New mx2cc.Transpiler(cl,TempPath)
	Local mx2Path:=MonkeyPath(std.filesystem.AppDir())	
	Local modulePaths:=ModulePaths(mx2Path)

	Print "AppDir="+std.filesystem.AppDir()
	Print "CurrentDir="+std.filesystem.CurrentDir()
		
	Local modules:=New String[]("monkey","libc","std","transpiler")

	Local src:=mx2Path+"mx2/mx2.monkey2"
	Local appargs:=New String[](src)

	mx2.MakeMods(modulePaths,modules)
	mx2.MakeApp(modulePaths,appargs)	
End
