Namespace mx2

Interface Toolchain	
	Method About:String()		
	Method Assemble:Int(cmd:String,fstderr:String)	
	Method Compile:Int(cmd:String,fstderr:String)
	Method Archive:Int(cmd:String)
End
