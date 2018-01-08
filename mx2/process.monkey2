#Import "native/process.cpp"
#Import "native/process.h"

Extern

Function invoke:Int(cmd:CString)
	
Public

Class Process
	Function Invoke:Int(cmd:String)
		Return invoke(cmd)
	End
End

