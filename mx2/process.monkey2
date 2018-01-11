
Namespace ted2go

Using std.fiber..
Using std.process..
Using std.collections..

#rem monkeydoc The ProcessReader class.

Allow us to read output from process.
We can reuse this class with any commands.
Each command starts new process.
You should to wait until work is finished - if you run while process already running then nothing happen.

There are 2 usage scenarios: RunAsync and Run.

With RunAsync we get output by PortionRead and Finished events.
This is not blocked method.

With Run we get output as result of this call.
This is blocked method.

Both methods are using Fiber to waiting process finished.
#end
Class ProcessReader
	
	#rem monkeydoc Tag to identify reader.
	#end
	Field Tag:=""
	
	#rem monkeydoc Invoked when a process finishes execution.
	#end
	Field Finished:Void( output:String,exitCode:Int )
	
	#rem monkeydoc Invoked when read portion of output from process.
	#end
	Field PortionRead:Void( output:String )
	
	#rem monkeydoc Invoked when a process finishes execution AND exitCode <> 0.
	#end
	Field Error:Void( exitCode:Int )
	
	#rem monkeydoc Obtain a reader instance.
	#end
	Method New( tag:String="" )
	
		Tag=tag
		_items.Add( Self )
	End
	
	Function StopAll()
	
		For Local r:=Eachin _items
			r.Stop()
		Next
	End
	
	#rem monkeydoc
	#end
	Function WaitingForStopAll( wait:Future<Bool> )
		
		_stopSize=0
		_stopCounter=0
		
		For Local r:=Eachin _items
			If r.IsRunning
				_stopSize+=1
				r.Finished+=Lambda( s:String,c:Int )
					_stopCounter+=1
					If _stopCounter=_stopSize Then wait.Set( True )
				End
			Endif
		Next
		If _stopSize=0
			wait.Set( True )
			Return
		Endif
	End
	
	#rem monkeydoc Async reading of process. You should to subscribe on (at least) Finished event to get result.
	This method can be used without creation of new Fiber.
	If started while process already running - nothing happen.
	#end
	Method RunAsync( command:String )
		
		If _running Return
		
		New Fiber( Lambda()
		
			RunInternal( command )
		End )
	End
	
	#rem monkeydoc Sync reading of process.
	This method must be used with creation of new Fiber, because it uses Future to waiting for process finished.
	Return full output of a process.
	If started while process already running - immediately return an empty string.
	#end
	Method Run:String( command:String )
	
		If _running Return ""
	
		Return RunInternal( command )
	End
	
	#rem monkeydoc Terminate process execution.
	#end
	Method Stop()
		
		If Not _procOpen
'			If _stdoutWaiting
'				_stdoutWaiting.Set( False )
'			Endif
			Return
		Endif
		
		_process.Terminate()
		
		OnStop()
	End
	
	#rem monkeydoc Is reading currently in progress.
	#end
	Property IsRunning:Bool()
	
		Return _running
	End
	
	
	Private
	
	Field _process:Process
	Field _output:String
	Field _running:Bool
	Field _stdoutWaiting:Future<Bool>
	Field _stdoutOpen:Bool,_procOpen:Bool
	Global _items:=New Stack<ProcessReader>
	Global _stopSize:Int,_stopCounter:Int
	
	Method RunInternal:String( cmd:String )
	
		If Not Start( cmd )
			Print "Failed to start process '"+cmd+"'"
			Return ""
		Endif
		
		' waiting for the end
		_stdoutWaiting=New Future<Bool>
		_stdoutWaiting.Get()
		_stdoutWaiting=Null
		
		Return _output
	End
	
	Method Start:Bool( cmd:String )
		
		If _running Return False
		
		Local process:=New Process
	
		process.Finished=Lambda()
			'Print "proc.finished: "+Tag
			_procOpen=False
			UpdateRunning()
		End
		
		process.StdoutReady=Lambda()
			'Print "proc.stdoutReady: "+Tag
			Local stdout:=process.ReadStdout()
			
			If stdout
				stdout=stdout.Replace( "~r~n","~n" ).Replace( "~r","~n" )
				_output+=stdout
				PortionRead( stdout )
			Else
				_stdoutOpen=False
				UpdateRunning()
			Endif
		End
		
		If Not process.Start( cmd ) Return False
		
		_process=process
		_running=True
		_procOpen=True
		_stdoutOpen=True
		_output=""
		
		Return True
	End
	
	Method UpdateRunning()
	
		If Not _running Or _procOpen Or _stdoutOpen Return
	
		OnStop()
		
		Local code:=_process.ExitCode
		
		Finished( _output,code )
		If code<>0 Then Error( code )
		
		If _stdoutWaiting
			_stdoutWaiting.Set( True )
		Endif
	End
	
	Method OnStop()
		
		_running=False
		_items.Remove( Self )
	End
	
End
