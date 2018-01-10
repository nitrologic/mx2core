#Import "<transpiler>"

#if __TARGET__="windows"
Global TempPath:=std.filesystem.GetEnv("TEMP")
Global ToolPath:=std.filesystem.GetEnv("VS140COMNTOOLS")
#else
Global TempPath:="/tmp"
Global ToolPath:="."
#endif

Class VisualStudio Implements mx2.Toolchain

	Method New()
		std.filesystem.SetEnv("MX2_CPP_OPTS_MSVC","-EHsc -W0 -MT -utf-8")
		std.filesystem.SetEnv("MX2_CPP_OPTS_MSVC_DEBUG","-O1")
		std.filesystem.SetEnv("MX2_CPP_OPTS_MSVC_RELEASE","-O2 -DNDEBUG")
	End
		
	Method Invoke:Int(command:String)
		Local vsdevcmd:=ToolPath+"VsDevCmd.bat"
		Local cmd:="call ~q"+vsdevcmd+"~q && ("+command+")"
		Local result:=libc.system(cmd)
'		If result Print cmd + " returned " + result
		Return result
	End	
			
	Method CLAbout:String()
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

	Method About:String()
'[]		Local info:=CLAbout()
		Local info:=Help()
'		Local lines:=info.Split("~r~n")
'		If lines.Length Return lines[0]
		Return info
	End

	Method Assemble:Int(cmd:String)	
'		Print "ASSEMBLE"
		Return Invoke(cmd)
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
		Local temp:=TempPath + "\link.txt"
		Local result:=Invoke(cmd+" > ~q"+temp+"~q 2>&1")
		If result
			Local about:=std.stringio.LoadString(temp.Replace("\","/"))
			about=about.Replace("~r~n","~n")
			Print about
		Endif
		Return result
	End

	Method Archive:Int(cmd:String)
'		Print "ARCHIVE"
		Return Invoke(cmd)
	End

'		Local result:=system( cmd+" 2>"+fstderr )			
'		Return result
	
End


Class GCC Implements mx2.Toolchain
		
	method Help:String()
		Local temp:=TempPath + "/g++version.txt"
		Local cmd:="g++ --help > ~q"+temp+"~q 2>&1"
		Local result:=libc.system(cmd)
		If result 
			print cmd+" returned "+result
			return ""
		endif
		Return std.stringio.LoadString(temp)
	End
	
	Method About:String()		
		Return 0
	End
	Method Assemble:Int(cmd:String)	
		Return 0
	End
	Method Compile:Int(cmd:String)
		Return 0
	End
	Method Archive:Int(cmd:String)
		Return 0
	End
	Method Link:Int(cmd:String)
		Return 0
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
	Print "Toolchain:"+cl.Help()
End

Function BuildAll(cl:mx2.Toolchain)
	Local mx2:=New mx2cc.Transpiler(cl,TempPath)

	Local mx2Path:=MonkeyPath(std.filesystem.AppDir())	

	Local modulePaths:=ModulePaths(mx2Path)

'	std.filesystem.ChangeDir(mx2Path)

	Print "AppDir="+std.filesystem.AppDir()
	Print "CurrentDir="+std.filesystem.CurrentDir()

'	Local home:="/Users/simon/monkey2/modules/"
'	Local home:=std.filesystem.AppDir()+"../../../modules/"	
		
	Local modules:=New String[]("monkey","libc","std","transpiler")
'	Local modules:=New String[]("monkey","libc","std")

	Local src:=mx2Path+"mx2/mx2.monkey2"
	Local appargs:=New String[](src)

'	mx2.MakeMods(modulePaths,modules)
	mx2.MakeApp(modulePaths,appargs)	


End


Function MacMain()
	
	Print std.filesystem.AppDir()
	Print std.filesystem.CurrentDir()

	Local cl:=New GCC()
	Local mx2:=New mx2cc.Transpiler(cl,TempPath)
	
'	Local home:="/Users/simon/monkey2/modules/"
	Local home:=std.filesystem.AppDir()+"../../../modules/"	
		
	Local dirs:=New String[](home)
	Local args:=New String[]("std","libc","monkey","transpiler")

	mx2.MakeMods(dirs,args)
End
