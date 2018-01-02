
Namespace std.collections

#rem monkeydoc Convenience type alias for Stack\<Int\>.
#end
Alias IntStack:Stack<Int>

#rem monkeydoc Convenience type alias for Stack\<Float\>.
#end
Alias FloatStack:Stack<Float>

#rem monkeydoc Convenience type alias for Stack\<String\>.
#end
Alias StringStack:Stack<String>

#rem monkeydoc The Stack class provides suport for dynamic arrays.

A stack is an 'array like' container that grows dynamically as necessary.

It is very cheap to add values to the end of a stack, but insertion or removal of values requires higher indexed values to be 'shifted' up or down so is slower.

Stacks implement the [[IContainer]] interface so can be used with [[Eachin]] loops.

#end
Class Stack<T> Implements IContainer<T>

	#rem monkeydoc The Stack.Iterator struct.
	#end
	Struct Iterator 'Implements IIterator<T>
	
		Private

		Field _stack:Stack
		Field _index:Int
		
		Method AssertCurrent()
			DebugAssert( _index<_stack._length,"Invalid stack iterator" )
		End
		
		Method New( stack:Stack,index:Int )
			_stack=stack
			_index=index
		End
		
		Public
		
		#rem monkeydoc Checks if the iterator has reached the end of the stack.
		#end
		Property AtEnd:Bool()
			Return _index>=_stack._length
		End
		
		#rem monkeydoc The value currently pointed to by the iterator.
		#end
		Property Current:T()
			AssertCurrent()
			Return _stack._data[_index]
		Setter( current:T )
			AssertCurrent()
			_stack._data[_index]=current
		End
		
		#rem monkeydoc Bumps the iterator so it points to the next value in the stack.
		#end
		Method Bump()
			AssertCurrent()
			_index+=1
		End
		
		#rem monkeydoc Safely erases the value pointed to by the iterator.
		
		After calling this method, the iterator will point to the value after the removed value.
		
		Therefore, if you are manually iterating through a stack you should not call [[Bump]] after calling this method or you will end up skipping a value.
		
		#end
		Method Erase()
			AssertCurrent()
			_stack.Erase( _index )
		End
		
		#rem monkeydoc Safely inserts a value before the value pointed to by the iterator.

		After calling this method, the iterator will point to the newly added value.
		
		#end
		Method Insert( value:T )
			DebugAssert( _index<=_stack._length,"Invalid stack iterator" )
			_stack.Insert( _index,value )
		End
	End
	
	#rem monkeydoc The Stack.BackwardsIterator struct.
	#end
	Struct BackwardsIterator 'Implements IIterator<T>
	
		Private

		Field _stack:Stack
		Field _index:Int
		
		Method AssertCurrent()
			DebugAssert( _index>=0,"Invalid stack iterator" )
		End
		
		Method New( stack:Stack,index:Int )
			_stack=stack
			_index=index
		End
		
		Public
		
		#rem monkeydoc Checks if the iterator has reached the end of the stack.
		#end
		Property AtEnd:Bool()
			Return _index=-1
		End
		
		#rem monkeydoc The value currently pointed to by the iterator.
		#end
		Property Current:T()
			AssertCurrent()
			Return _stack._data[_index]
		Setter( current:T )
			AssertCurrent()
			_stack._data[_index]=current
		End
		
		#rem monkeydoc Bumps the iterator so it points to the next value in the stack.
		#end
		Method Bump()
			AssertCurrent()
			_index-=1
		End
		
		#rem monkeydoc Safely erases the value pointed to by the iterator.
		
		After calling this method, the iterator will point to the value after the removed value.
		
		Therefore, if you are manually iterating through a stack you should not call [[Bump]] after calling this method or you
		will end up skipping a value.
		
		#end
		Method Erase()
			AssertCurrent()
			_stack.Erase( _index )
			_index-=1
		End
		
		#rem monkeydoc Safely inserts a value before the value pointed to by the iterator.

		After calling this method, the iterator will point to the newly added value.
		
		#end
		Method Insert( value:T )
			DebugAssert( _index<_stack._length,"Invalid stack iterator" )
			_index+=1
			_stack.Insert( _index,value )
		End
	End
	
	Private

	Field _data:T[]
	Field _length:Int
	
	Public
	
	#rem monkeydoc Creates a new stack.
	
	New() creates an empty stack.
	
	New( length:Int ) creates a stack that initially contains `length` null values.
	
	New( values:T[] ) creates a stack with the contents of an array.
	
	New( values:List<T> ) creates a stack with the contents of a list.
	
	New( values:Deque<T> ) create a stack with the contents of a deque.
	
	New( values:Stack<T> ) create a stack with the contents of another stack.
	
	@param length The length of the stack.
	
	@param values An array, list or stack.
	
	#end
	Method New()
		_data=New T[10]
	End
	
	Method New( length:Int )
		_length=length
		_data=New T[_length]
	End

	Method New( values:T[] )
		AddAll( values )
	End
	
	Method New( values:List<T> )
		AddAll( values )
	End
	
	Method New( values:Deque<T> )
		_length=values.Length
		_data=New T[_length]
		values.Data.CopyTo( _data,0,0,_length )
	End
	
	Method New( values:Stack<T> )
		_length=values.Length
		_data=New T[_length]
		values.Data.CopyTo( _data,0,0,_length )
	End
	
	#rem monkeydoc Checks if the stack is empty.
	
	@return True if the stack is empty.
	
	#end
	Property Empty:Bool()
		Return _length=0
	End

	#rem monkeydoc Gets an iterator for visiting stack values.
	
	Returns an iterator suitable for use with [[Eachin]], or for manual iteration.
	
	@return A stack iterator.
	
	#end
	Method All:Iterator()
		Return New Iterator( Self,0 )
	End
	
	#rem monkeydoc Gets an iterator for visiting stack values in reverse order.
	
	Returns an iterator suitable for use with [[Eachin]], or for manual iteration.

	@return A backwards stack iterator.
		
	#end	
	Method Backwards:BackwardsIterator()
		Return New BackwardsIterator( Self,_length-1 )
	End

	#rem monkeydoc Converts the stack to an array.
	
	@return An array containing each element of the stack.
	
	#end
	Method ToArray:T[]()
		Return _data.Slice( 0,_length )
	End
	
	#rem monkeydoc Gets the underlying array used by the stack.
	
	Note that the returned array may be longer than the stack length.
	
	@return The array used internally by the stack.
	
	#end
	Property Data:T[]()
		Return _data
	End
	
	#rem monkeydoc Gets the number of values in the stack.
	
	@return The number of values in the stack.
	
	#end
	Property Length:Int()
		Return _length
	End
	
	#rem monkeydoc Gets the storage capacity of the stack.
	
	The capacity of a stack is the number of values it can contain before memory needs to be reallocated to store more values.
	
	If a stack's length equals its capacity, then the next Add or Insert operation will need to allocate more memory to 'grow' the stack.
	
	You don't normally need to worry about stack capacity, but it can be useful to use [[Reserve]] to preallocate stack storage if you know in advance
	how many values a stack is likely to contain, in order to prevent the overhead of excessive memory allocation.
	
	@return The current stack capacity.
	
	#end
	Property Capacity:Int()
		Return _data.Length
	End
	
	#rem monkeydoc Compacts the stack
	#end
	Method Compact()
		If _length<>_data.Length _data=_data.Slice( 0,_length )
	End
	
	#rem monkeydoc Resizes the stack.
	
	If `length` is greater than the current stack length, any extra elements are initialized to null.
	
	If `length` is less than the current stack length, the stack is truncated.
	
	@param length The new length of the stack.
	
	#end	
	Method Resize( length:Int )
		DebugAssert( length>=0 )
		
		For Local i:=length Until _length
			_data[i]=Null
		Next
		
		Reserve( length )
		_length=length
	End
	
	#rem monkeydoc Reserves stack storage capacity.
	
	The capacity of a stack is the number of values it can contain before memory needs to be reallocated to store more values.
	
	If a stack's length equals its capacity, then the next Add, Insert or Push operation will need to allocate more memory to 'grow' the stack.
	
	You don't normally need to worry about stack capacity, but it can be useful to use [[Reserve]] to preallocate stack storage if you know in advance
	how many values a stack is likely to contain, in order to prevent the overhead of excessive memory allocation.
	
	@param capacity The new capacity.
	
	#end
	Method Reserve( capacity:Int )
		DebugAssert( capacity>=0 )
		
		If _data.Length>=capacity Return
		
		capacity=Max( _length*2+_length,capacity )
		Local data:=New T[capacity]
		_data.CopyTo( data,0,0,_length )
		_data=data
	End
	
	#rem monkeydoc Clears the stack.
	#end
	Method Clear()
		Resize( 0 )
	End
	
	#rem monkeydoc Erases an element at an index in the stack.
	
	In debug builds, a runtime error will occur if `index` is less than 0 or greater than the stack length.
	
	if `index` is equal to the stack length, the operation has no effect.
	
	@param index The index of the element to erase.
	
	#end
	Method Erase( index:Int )
		DebugAssert( index>=0 And index<=_length )
		If index=_length Return
		
		_data.CopyTo( _data,index+1,index,_length-index-1 )
		Resize( _length-1 )
	End
	
	#rem monkeydoc Erases a range of elements in the stack.
	
	If debug builds, a runtime error will occur if either index is less than 0 or greater than the stack length, or if index2 is less than index1.
	
	The number of elements actually erased is `index2`-`index1`.
	
	@param index1 The index of the first element to erase.
	
	@param index2 The index of the last+1 element to erase.
	
	#end
	Method Erase( index1:Int,index2:Int )
		DebugAssert( index1>=0 And index1<=_length And index2>=0 And index2<=_length And index1<=index2 )
		
		If index1=_length Return
		_data.CopyTo( _data,index2,index1,_length-index2 )
		Resize( _length-index2+index1 )
	End
	
	#rem monkeydoc Inserts a value at an index in the stack.
	
	In debug builds, a runtime error will occur if `index` is less than 0 or greater than the stack length.
	
	If `index` is equal to the stack length, the value is added to the end of the stack.
	
	@param index The index of the value to insert.
	
	@param value The value to insert.
	
	#end
	Method Insert( index:Int,value:T )
		DebugAssert( index>=0 And index<=_length )
		
		Reserve( _length+1 )
		_data.CopyTo( _data,index,index+1,_length-index )
		_data[index]=value
		_length+=1
	End
	
	#rem monkeydoc Gets the value of a stack element.
	
	In debug builds, a runtime error will occur if `index` is less than 0, or greater than or equal to the length of the stack.
	
	@param index The index of the element to get.
	
	#end
	Method Get:T( index:Int )
		DebugAssert( index>=0 And index<_length,"Stack index out of range" )
		
		Return _data[index]
	End
	
	#rem monkeydoc Sets the value of a stack element.

	In debug builds, a runtime error will occur if `index` is less than 0, or greater than or equal to the length of the stack.
	
	@param index The index of the element to set.
	
	@param value The value to set.
	
	#end
	Method Set( index:Int,value:T )
		DebugAssert( index>=0 And index<_length,"Stack index out of range" )
		
		_data[index]=value
	End
	
	#rem monkeydoc Gets the value of a stack element.
	
	In debug builds, a runtime error will occur if `index` is less than 0, or greater than or equal to the length of the stack.
	
	@param index The index of the element to get.

	#end
	Operator []:T( index:Int )
		DebugAssert( index>=0 And index<_length,"Stack index out of range" )
		
		Return _data[index]
	End
	
	#rem monkeydoc Sets the value of a stack element.
	
	In debug builds, a runtime error will occur if `index` is less than 0, or greater than or equal to the length of the stack.
	
	@param index The index of the element to set.
	
	@param value The value to set.
	
	#end
	Operator []=( index:Int,value:T )
		DebugAssert( index>=0 And index<_length,"Stack index out of range" )
		
		_data[index]=value
	End
	
	#rem monkeydoc Adds a value to the end of the stack.
	
	This method behaves identically to Push( value:T ).
	
	@param value The value to add.
	
	#end
	Method Add( value:T )
		Reserve( _length+1 )
		_data[_length]=value
		_length+=1
	End
	
	#rem monkeydoc Adds the values in an array or container to the end of the stack.
	
	@param values The values to add.
	
	#end
	Method AddAll( values:T[] )
		Reserve( _length+values.Length )
		values.CopyTo( _data,0,_length,values.Length )
		Resize( _length+values.Length )
	End

	Method AddAll<C>( values:C ) Where C Implements IContainer<T>
		For Local value:=Eachin values
			Add( value )
		Next
	End

	#rem monkeydoc @deprecated Use [[AddAll]].
	#End
	Method Append<C>( values:C ) Where C Implements IContainer<T>
		For Local value:=Eachin values
			Add( value )
		Next
	End
	
	#rem monkeydoc Finds the index of the first matching value in the stack.
	
	In debug builds, a runtime error will occur if `start` is less than 0 or greater than the length of the stack.
	
	@param value The value to find.
	
	@param start The starting index for the search.
	
	@return The index of the value in the stack, or -1 if the value was not found.
	
	#end
	Method FindIndex:Int( value:T,start:Int=0 )
		DebugAssert( start>=0 And start<=_length )
		
		Local i:=start
		While i<_length
			If _data[i]=value Return i
			i+=1
		Wend
		Return -1
	End
	
	#rem monkeydoc Finds the index of the last matching value in the stack.
	
	In debug builds, a runtime error will occur if `start` is less than 0 or greater than the length of the stack.
	
	@param value The value to find.
	
	@param start The starting index for the search.
	
	@return The index of the value in the stack, or -1 if the value was not found.
	
	#end
	Method FindLastIndex:Int( value:T,start:Int=0 )
		DebugAssert( start>=0 And start<=_length )
		
		Local i:=_length
		While i>start
			i-=1
			If _data[i]=value Return i
		Wend
		Return -1
	End
	
	#rem monkeydoc Checks if the stack contains a value.
	
	@param value The value to check for.
	
	@return True if the stack contains the value, else false.
	
	#end
	Method Contains:Bool( value:T )
		Return FindIndex( value )<>-1
	End
	
	#rem monkeydoc Finds and removes the first matching value from the stack.
	
	@param start The starting index for the search.
	
	@param value The value to remove.
	
	@return True if the value was removed.
	
	#end
	Method Remove:Bool( value:T,start:Int=0 )
		Local i:=FindIndex( value,start )
		If i=-1 Return False
		Erase( i )
		Return True
	End
	
	#rem monkeydoc Finds and removes the last matching value from the stack.
	
	@param start The starting index for the search.
	
	@param value The value to remove.
	
	@return True if the value was removed.
	
	#end
	Method RemoveLast:Bool( value:T,start:Int=0 )
		Local i:=FindLastIndex( value,start )
		If i=-1 Return False
		Erase( i )
		Return True
	End
	
	#rem monkeydoc Finds and removes each matching value from the stack.
	
	@param value The value to remove.
	
	@return The number of values removed.
	
	#end	
	Method RemoveEach:Int( value:T )
		Local put:=0,n:=0
		For Local get:=0 Until _length
			If _data[get]=value 
				n+=1
				Continue
			Endif
			_data[put]=_data[get]
			put+=1
		Next
		Resize( put )
		Return n
	End
	
	#rem monkeydoc Removes all values int the stack that fulfill a condition.
	
	@param condition The condition to test.
	
	@return The number of values removed.
	
	#end	
	Method RemoveIf:Int( condition:Bool( value:T ) )
		Local put:=0,n:=0
		For Local get:=0 Until _length
			If condition( _data[get] )
				n+=1
				Continue
			Endif
			_data[put]=_data[get]
			put+=1
		Next
		Resize( put )
		Return n
	End
	
	#rem monkeydoc Returns a range of elements from the stack.
	
	Returns a slice of the stack consisting of all elements from `index1` until `index2` or the end of the stack.
	
	If either index is negative, then it represents an offset from the end of the stack.

	Indices are clamped to the length of the stack, so Slice will never cause a runtime error.
	
	@param index1 the index of the first element (inclusive).

	@param index2 the index of the last element (exclusive).
	
	@return A new stack.
	
	#end
	Method Slice:Stack( index:Int )

		Return Slice( index,_length )
	End

	Method Slice:Stack( index1:Int,index2:Int )

		If index1<0
			index1=Max( index1+_length,0 )
		Else If index1>_length
			index1=_length
		Endif
		
		If index2<0
			index2=Max( index2+_length,index1 )
		Else If index2>_length
			index2=_length
		Else If index2<index1
			index2=index1
		Endif
		
		Return New Stack( _data.Slice( index1,index2 ) )
	End
	
	#rem monkeydoc Swaps 2 elements in the stack.
	
	In debug builds, a runtime error will occur if `index1` or `index2` is out of range.
	
	@param index1 The index of the first element.
	
	@param index2 The index of the second element.
	
	#end
	Method Swap( index1:Int,index2:Int )
		DebugAssert( index1>=0 And index1<_length And index2>=0 And index2<_length,"Stack index out of range" )
		
		Local t:=_data[index1]
		_data[index1]=_data[index2]
		_data[index2]=t
	End
	
	#rem monkeydoc Sorts the stack.

	@param ascending True to sort the stack in ascending order, false to sort in descending order.
	
	@param compareFunc Function to be used to compare values when sorting.
	
	@param lo Index of first value to sort.
	
	@param hi Index of last value to sort.

	#end
	Method Sort( ascending:Int=True )
		If ascending
			Sort( Lambda:Int( x:T,y:T )
				Return x<=>y
			End )
		Else
			Sort( Lambda:Int( x:T,y:T )
				Return y<=>x
			End )
		Endif
	End

	Method Sort( compareFunc:Int( x:T,y:T ) )
		Sort( compareFunc,0,_length-1 )
	End

	Method Sort( compareFunc:Int( x:T,y:T ),lo:Int,hi:int )
	
		If hi<=lo Return
		
		If lo+1=hi
			If compareFunc( _data[hi],_data[lo] )<0 Swap( hi,lo )
			Return
		Endif
		
		Local i:=(lo+hi)/2
		
		If compareFunc( _data[i],_data[lo] )<0 Swap( i,lo )

		If compareFunc( _data[hi],_data[i] )<0
			Swap( hi,i )
			If compareFunc( _data[i],_data[lo] )<0 Swap( i,lo )
		Endif
		
		Local x:=lo+1
		Local y:=hi-1
		Repeat
			Local p:=_data[i]
			While compareFunc( _data[x],p )<0
				x+=1
			Wend
			While compareFunc( p,_data[y] )<0
				y-=1
			Wend
			If x>y Exit
			If x<y
				Swap( x,y )
				If i=x i=y Else If i=y i=x
			Endif
			x+=1
			y-=1
		Until x>y

		Sort( compareFunc,lo,y )
		Sort( compareFunc,x,hi )
	End
	
	#rem monkeydoc Gets the top element of the stack
	
	In debug builds, a runtime error will occur if the stack is empty.
	
	@return The top element of the stack.
	
	#end
	Property Top:T()
		DebugAssert( _length,"Stack is empty" )
		
		Return _data[_length-1]
	End
	
	#rem monkeydoc Pops the top element off the stack and returns it.
	
	In debug builds, a runtime error will occur if the stack is empty.
	
	@return The top element of the stack before it was popped.
	#end
	Method Pop:T()
		DebugAssert( _length,"Stack is empty" )
		
		_length-=1
		Local value:=_data[_length]
		_data[_length]=Null
		Return value
	End
	
	#rem monkeydoc Pushes a value on the stack.

	This method behaves identically to Add( value:T ).
	
	@param value The value to push.
	
	#end
	Method Push( value:T )
		Add( value )
	End

	#rem monkeydoc Joins the values in a string stack.
	
	@param sepeator The separator to be used when joining values.
	
	@return The joined values.
	
	#end
	Method Join:String( separator:String ) Where T=String
		Return separator.Join( ToArray() )
	End
	
End
