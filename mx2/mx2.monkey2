#Import "<transpiler>"



Global TempPath:="/tmp"
Global ToolPath:="/tmp"

Class VisualStudio Implements mx2.Toolchain
		
	Property Compiler:String()
		Local vsdevcmd:=ToolPath+"VsDevCmd.bat"
		Local temp:=TempPath + "\getcl.txt"
		Local cmd:="call ~q"+vsdevcmd+"~q && (cl > ~q"+temp+"~q 2>&1)"
		Local result:=libc.system(cmd)
		If result Return ""
		Return std.stringio.LoadString(temp.Replace("\","/"))
	End

	Method About:String()		
		Return 0
	End
	Method Assemble:Int(cmd:String,fstderr:String)	
		Return 0
	End
	Method Compile:Int(cmd:String,fstderr:String)
		Return 0
	End
	Method Archive:Int(cmd:String)
		Return 0
	End

'		Local result:=system( cmd+" 2>"+fstderr )			
'		Return result
	
End
	
Class Xcode Implements mx2.Toolchain
		
	Property Compiler:String()
		Local temp:=TempPath + "\getcl.txt"
		Local cmd:="call ~q"+ToolPath+"VsDevCmd.bat~q && (cl > ~q"+temp+"~q 2>&1)"
		Local result:=libc.system(cmd)
		If result Return ""
		Return std.stringio.LoadString(temp.Replace("\","/"))
	End
	
	Method About:String()		
		Return 0
	End
	Method Assemble:Int(cmd:String,fstderr:String)	
		Return 0
	End
	Method Compile:Int(cmd:String,fstderr:String)
		Return 0
	End
	Method Archive:Int(cmd:String)
		Return 0
	End
End

Function Main()
	
	Print std.filesystem.AppDir()
	Print std.filesystem.CurrentDir()

	Local cl:=New Xcode()

	Local mx2:=New mx2cc.Transpiler(cl,TempPath)
	
'	Local home:="/Users/simon/monkey2/modules/"
	Local home:=std.filesystem.AppDir()+"../../../modules/"	
		
	Local dirs:=New String[](home)
	Local args:=New String[]("std","libc","monkey","transpiler")

	mx2.MakeMods(dirs,args)
End
