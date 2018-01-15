#Import "<transpiler>"
#Import "<std>"

#if __TARGET__="windows"
Global TempPath:=std.filesystem.GetEnv("TEMP")
Global VS140Path:=std.filesystem.GetEnv("VS140COMNTOOLS")
#else
Global TempPath:="/tmp"
Global VS140Path:="."
#endif

'Alias Task:ted2go.ProcessReader

Alias Task:std.process.ProcessStream

Class ProcessStack

	Method Debug()	
		Print "active="+core.Count()
		Print "queue="+commands.Count()
	End

	Field commands:=New std.collections.List<String>
	Field core:=New std.collections.List<Task>

	Method Execute:Int(command:String)
		If core.Count()<12
			New std.fiber.Fiber( Lambda()				
				Local task:=Task.Open(command,"r")
				Local buffer:=New std.memory.DataBuffer(8192)
				While True
					While True
						Local n:=task.Read( buffer.Data,8192 )
						If n=0 Exit
						Print buffer.PeekString(0,n).Trim()
					Wend
					If commands.Count()=0 Exit
					Local cmd:=commands.RemoveFirst()
					Print "ProcessStack: launching "+cmd
					task=Task.Open(cmd,"r")
				Wend
			End)			
		Else
			commands.AddLast(command)
		Endif		
		Return 0
	End

End

Class VisualStudio Extends ProcessStack Implements mx2.Toolchain

	Method New()
'		std.filesystem.SetEnv("AMD64Path",VS140Path+"..\..\VC\bin\amd64\")
		std.filesystem.SetEnv("MX2_CPP_OPTS_MSVC","-EHsc -W0 -MT -utf-8")
		std.filesystem.SetEnv("MX2_CPP_OPTS_MSVC_DEBUG","-O1")
		std.filesystem.SetEnv("MX2_CPP_OPTS_MSVC_RELEASE","-O2 -DNDEBUG")
		std.filesystem.SetEnv("MX2_AS_OPTS_MSVC","/DBOOST_CONTEXT_EXPORT=")
	End
		
	Method Invoke:Int(command:String)
'		Local vsdevcmd:=VS140Path+"VsDevCmd.bat"
		Local vsdevcmd:=VS140Path+"..\..\VC\vcvarsall.bat"
'		Local cmd:="call ~q"+vsdevcmd+"~q x64 && ("+command+")"
'		Local result:=libc.system(cmd)
		Local cmd:="cmd.exe /c call ~q"+vsdevcmd+"~q x64 && ("+command+")"
		Local result:=Execute(cmd)
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
		Return Invoke(cmd)
	End


	Method Compile2:Int(cmd:String)
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
		Local temp:=TempPath + "\ar.txt"
		Local result:=Invoke(cmd+" > ~q"+temp+"~q 2>&1")
		If result
			Local about:=std.stringio.LoadString(temp.Replace("\","/"))
			about=about.Replace("~r~n","~n")
			Print about
		Endif
		Return result
	End	
End

Class GCC Implements mx2.Toolchain

	Method New()
		std.filesystem.SetEnv("MX2_APP_DIR_FRAMEWORK","../Frameworks")
		std.filesystem.SetEnv("MX2_LD_OPTS_MACOS","-mmacosx-version-min=10.9 -Wl,-rpath,@executable_path -Wl,-rpath,@executable_path/../Frameworks")
		std.filesystem.SetEnv("MX2_LD_OPTS_MACOS_RELEASE","-O3")
		std.filesystem.SetEnv("MX2_CPP_OPTS_MACOS","-std=c++14 -mmacosx-version-min=10.9 -Wno-deprecated-declarations -Wno-tautological-pointer-compare -Wno-undefined-bool-conversion -Wno-int-to-void-pointer-cast -Wno-inconsistent-missing-override -Wno-logical-op-parentheses -Wno-parentheses-equality")
		std.filesystem.SetEnv("MX2_CPP_OPTS_MACOS_RELEASE","-O3 -DNDEBUG")
		std.filesystem.SetEnv("MX2_CC_OPTS_MACOS","-std=gnu99 -mmacosx-version-min=10.9 -Wno-deprecated-declarations -Wno-tautological-pointer-compare -Wno-undefined-bool-conversion -Wno-int-to-void-pointer-cast -Wno-inconsistent-missing-override -Wno-logical-op-parentheses -Wno-parentheses-equality")
		std.filesystem.SetEnv("MX2_CC_OPTS_MACOS_RELEASE","-O3 -DNDEBUG")
	End
	
	Method Debug()	
	end

	Method About:String()
		return "GCC"
	end

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
	Local mx2:=New mx2cc.Transpiler(cl,TempPath)

'	Print "AppDir="+std.filesystem.AppDir()
'	Print "CurrentDir="+std.filesystem.CurrentDir()

	Build(mx2,"makemods")
	Build(mx2,"makeapp")

	cl.Debug()

	Local args:=std.filesystem.AppArgs()
	If args.Length<2
		Print "mx2 core version 0.0.01"
		Print mx2.About
		Return
	Endif		
	Local command:=args[1]	

	Build(mx2,command)
	
	Print "Complete"
	
End

Function Build(mx2:mx2cc.Transpiler,command:String)
	Local mx2Path:=MonkeyPath(std.filesystem.AppDir())	
	Local modulePaths:=ModulePaths(mx2Path)

	Select command		
		Case "makemods"
			Local modules:=New String[]("monkey","libc","std","transpiler")
			mx2.MakeMods(modulePaths,modules)

		Case "makeapp"
			Local src:=mx2Path+"mx2/mx2.monkey2"
			Local appargs:=New String[](src)
			mx2.MakeApp(modulePaths,appargs)
	End	
End
