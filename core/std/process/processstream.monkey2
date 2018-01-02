
Namespace std.process

#If __TARGET__<>"emscripten"

#rem monkeydoc The ProcessStream class.
#end
Class ProcessStream Extends Stream

	#rem monkeydoc The underlying process.
	#end
	Property Process:Process()
	
		Return _process
	End

	#rem monkeydoc True if process has ended.
	#end
	Property Eof:Bool() Override

		Return _finished And _stdoutFinished
	End
	
	#rem monkeydoc Always 0.
	#end
	Property Position:Int() Override
	
		Return 0
	End

	#rem monkeydoc Always -1.
	#end
	Property Length:Int() Override
	
		Return -1
	End

	#rem monkeydoc No operation.
	#end
	Method Seek( position:Int ) Override
	End

	#rem monkeydoc Reads data from process stdout.
	
	Reads at most `count` bytes from the process.
	
	Returns 0 if the process has ended.
	
	Can return less than `count`, in which case you may have to read again if you know there's more data coming.
	
	@param buf The memory buffer to read data into.
	
	@param count The number of bytes to read from the process.
	
	@return The number of bytes actually read.

	#end
	Method Read:Int( buf:Void Ptr,count:Int ) Override
	
		Local avail:=_process.StdoutAvail
		
		If Not avail
		
			If _stdoutFinished Return 0
		
			_stdoutWaiting=New Future<Int>
			
			avail=_stdoutWaiting.Get()
			
			_stdoutWaiting=Null
			
			If Not avail Return 0
		Endif
		
		Local n:=Min( avail,count )
			
		_process.ReadStdout( buf,n )
			
		Return n
	End
	
	#rem monkeydoc Writes data to process stdin.
	
	Writes `count` bytes to the process.
	
	Returns the number of bytes actually written.
	
	Can return less than `count` if the process has ended.
	
	@param buf The memory buffer to read data from.
	
	@param count The number of bytes to write to the process.
	
	@return The number of bytes actually written.

	#end
	Method Write:Int( buf:Void Ptr,count:Int ) Override
	
		Return _process.WriteStdin( buf,count )
	End
	
	#rem monkeydoc Opens a process stream.
	
	Returns null if process stream could not be opened.
	
	@return Null if process stream could not be opened.
	
	#end
	Function Open:ProcessStream( cmd:String,mode:String )
	
		Local stream:=New ProcessStream( cmd )
		If Not stream.Process Return Null
		
		Return stream
	End
	
	Protected
	
	#rem monkeydoc @hidden
	#end
	Method OnClose() Override
	
'		_process.Terminate()
	End

	Private
	
	Field _process:Process
	
	Field _finished:Bool
	
	Field _stdoutFinished:Bool
	
	Field _stdoutWaiting:Future<Int>
	
	Method New( cmd:String )
	
		_process=New Process
		
		_process.Finished+=Lambda()
		
			_finished=True
		End
		
		_process.StdoutReady+=Lambda()
		
			Local avail:=_process.StdoutAvail
			
			If Not avail _stdoutFinished=True
			
			If _stdoutWaiting _stdoutWaiting.Set( avail )
		End
		
		If _process.Start( cmd ) Return
		
		Print "Failed to start process: "+cmd
		
		_process=Null
	End
	
End

#Endif
