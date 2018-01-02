
Namespace std.resource

#Import "native/bbresource.cpp"

#Import "native/bbresource.h"

Extern Private

Class BBResource="bbResource"
	
	Protected
	
	Method OnDiscard() Virtual="onDiscard"
	
	Method OnFinalize() Virtual="onFinalize"
	
	Internal

	Method InternalDiscard()="discard"
	
End

Public

#Rem monkeydoc The Resource class.

The resource class helps with managing finite OS resources in a garbage collected environment.

To implement a resource object, you should extend the Resource class and override the [[OnDiscard]] and/or [[OnFinalize]] methods.

Code to actually discard the resource should be placed in OnDiscard. Discarding a resource might involve closing a file, deleting 
a texture handle or other similar actions. 'Last chance' cleanup code should be placed in OnFinalize.

IMPORTANT! There are a number of restrictions on code that may be placed in OnFinalize, please refer to the documentation for [[OnFinalize]]
for more information.
	
#end
Class Resource Extends BBResource
	
	#rem monkeyoc Discards the resource.
		
	If the resource has not yet been discarded, calling this method will cause any internally managed OS resources to be cleaned up.
	
	If the resource has already been discarded, this method does nothing.
		
	Once discarded, a resource should be consider invalid.
	
	#end
	Method Discard()
		
		InternalDiscard()
	End
	
	Protected
	
	#rem monkeydoc The OnDiscard method.
	
	This is where subclasses should place their actual discard code.
	
	This method will be invoked the first time Resource.Discard() is invoked.
	
	This method will only ever be invoked at most once during the lifetime of a resource.
	
	#end
	Method OnDiscard() Override
	End
	
	#rem monkeydoc The OnFinalize method.
	
	This method will be invoked when a resource object's memory is about to be reclaimed and if the resource's Discard() method has
	never been called during the lifetime of the object.
	
	This method is intended to be used for the 'last chance' cleanup of criticial OS resources, such as file handles, texture objects etc.
	
	***** WARNING *****
	
	Code inside this method executes at a critical point in the garbage collection process, and should be kept short and sweet.
	
	Code inside OnFinalize MUST obey the following rules:
	
	* Code MUST NOT read or write any fields of Self containing objects, arrays, or function pointers as there is no guarantee that such fields
	 are still valid when the finalizer executes.
	
	* Code MUST NOT assign Self to any variable.
	
	Failure to follow these rules *will* lead to eventual disaster!
	
	#end
	Method OnFinalize() Override
	End
	
End

#rem monkeydoc @hidden
#end
Class ResourceManager Extends Resource

	Method New()

		_managers.Push( Self )
	End
	
	Method OpenResource:Resource( slug:String )
	
		For Local manager:=Eachin _managers
		
			Local r:=manager._retained[slug]

			If Not r Continue
			
			If manager<>Self AddResource( slug,r )
			
			Return r
		Next

		Return Null
	End
	
	Method AddResource( slug:String,r:Resource )

		If Not r Or _retained.Contains( slug ) Return
		
		_retained[slug]=r
	End
	
	Protected
	
	Method OnDiscard() Override
	
		_managers.Remove( Self )
		
		_retained=Null
	End
	
	Private
	
	Global _managers:=New Stack<ResourceManager>
	
	Field _retained:=New StringMap<Resource>
End

#rem monkeydoc Safely discards a resource.

Invoke [[Resource.Discard]] on the given resource `r` only if `r` is non-null.

#end
Function SafeDiscard( r:Resource )
	
	If r r.Discard()
End
