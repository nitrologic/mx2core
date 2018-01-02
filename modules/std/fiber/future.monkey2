  
Namespace std.fiber

#if __TARGET__<>"emscripten"

#rem monkeydoc Futures provide support for simple fiber synchronization.

A future allows you to synchronize two fibers by providing a way for one fiber to signal to another that an operation has completed.

The general usage pattern of futures is:

* Fiber A creates a future and passes it to fiber B.

* Fiber A then calls [[Get]] on the future. This will suspend Fiber A.

* Fiber B performs some operation, then calls [[Set]] on the future. This will resume Fiber A.

A future can only be set once.

#end
Class Future<T>

	#rem monkeydoc Creates a new future.
	#end
	Method New()
		_fiber=Fiber.Current()
	End

	#rem monkeydoc Sets the future's value.
	#end	
	Method Set( value:T )
		DebugAssert( Not _ready,"Future has already be set" )
		_value=value
		_ready=True
		If _waiting _fiber.Resume()
	End
	
	#rem monkeydoc Gets the future's value.
	#end
	Method Get:T()
		If Not _ready
			_waiting=True
			Fiber.Suspend()
			_waiting=false
		Endif
		Return _value
	End

	Private
		
	Field _fiber:Fiber
	Field _value:T
	Field _ready:Bool
	Field _waiting:Bool
	
End

#endif
