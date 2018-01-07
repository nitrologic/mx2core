#Import "<transpiler>"

Function Main()
	
	Print std.filesystem.AppDir()
	Print std.filesystem.CurrentDir()

	Local mx2:=New mx2cc.Transpiler("/tmp","")
	
	Local home:=std.filesystem.RealPath(std.filesystem.AppDir()+"../../modules")
	
	Print home

	Local dirs:=New String[](home)
	Local args:=New String[]("std")

	mx2.MakeMods(dirs,args)
End
