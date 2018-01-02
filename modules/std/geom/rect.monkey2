
Namespace std.geom

#rem monkeydoc Convenience type alias for Rect\<Int\>.
#end
Alias Recti:Rect<Int>

#rem monkeydoc Convenience type alias for Rect\<Int\>.
#end
Alias Rectf:Rect<Float>

#rem monkeydoc The Rect class provides support for manipulating rectangular regions.

#end
Struct Rect<T>

	#rem monkeydoc Minimum rect coordinates.
	#end
	Field min:Vec2<T>
	
	#rem monkeydoc Maximum rect coordinates.
	#end
	Field max:Vec2<T>
	
	#rem monkeydoic Creates a new Rect.
	#end
	Method New()
	End
	
	Method New( min:Vec2<T>,max:Vec2<T> )
		Self.min=min
		Self.max=max
	End
	
	Method New( x0:T,y0:T,x1:T,y1:T )
		min=New Vec2<T>( x0,y0 )
		max=New Vec2<T>( x1,y1 )
	End
	
	Method New( x0:T,y0:T,max:Vec2<T> )
		Self.min=New Vec2<T>( x0,y0 )
		Self.max=max
	End
	
	Method New( min:Vec2<T>,x1:T,y1:T )
		Self.min=min
		Self.max=New Vec2<T>( x1,y1 )
	End
	
	#rem monkeydoc Converts the rect to a rect of a different type
	#end
	Operator To<C>:Rect<C>()
		Return New Rect<C>( min.x,min.y,max.x,max.y )
	End
	
	#rem  monkeydoc Converts the rect to a printable string.
	#end
	Operator To:String()
		Return "Rect("+min.x+","+min.y+","+max.x+","+max.y+")"
	End
	
	#rem monkeydoc The minimum X coordinate.
	#end
	Property X:T()
		Return min.x
	Setter( x:T )
		min.x=x
	End
	
	#rem monkeydoc The minimum Y coordinate.
	#end
	Property Y:T()
		Return min.y
	Setter( y:T )
		min.y=y
	End
	
	#rem monkeydoc The width of the rect.

'	Writing to this property modifies the maximum Y coordinate only.
	
	#end
	Property Width:T()
		Return max.x-min.x
'	Setter( width:T )
'		max.x=min.x+width
	End
	
	#rem monkeydoc The height of the rect.

'	Writing to this property modifies the maximum Y coordinate only.
	
	#end
	Property Height:T()
		Return max.y-min.y
'	Setter( height:T )
'		max.y=min.y+height
	End
	
	#rem monkeydoc The minimum X coordinate.
	#end
	Property Left:T()
		Return min.x
	Setter( left:T )
		min.x=left
	End
	
	#rem monkeydoc The minimum Y coordinate.
	#end
	Property Top:T()
		Return min.y
	Setter( top:T )
		min.y=top
	End
	
	#rem monkeydoc The maximum X coordinate.
	#end
	Property Right:T()
		Return max.x
	Setter( right:T )
		max.x=right
	End
	
	#rem monkeydoc The maximum X coordinate.
	#end
	Property Bottom:T()
		Return max.y
	Setter( bottom:T )
		max.y=bottom
	End
	
	#rem monkeydoc The top-left of the rect.
	#end
	Property Origin:Vec2<T>()
		Return min
	Setter( origin:Vec2<T> )
		min=origin
	End
	
	#rem monkeydoc The width and height of the rect.
	#end
	Property Size:Vec2<T>()
		Return max-min
	Setter( size:Vec2<T> )
		max=min+size
	End

	#rem monkeydoc The center of the rect.
	#end	
	Property Center:Vec2<T>()
		Return (min+max)/2
'	Setter( center:Vec2<T> )
	End
	
	#rem monkeydoc The top-left of the rect.
	#end
	Property TopLeft:Vec2<T>()
		Return min
	Setter( v:Vec2<T> )
		min=v
	End
	
	#rem monkeydoc The top-right of the rect.
	#end
	Property TopRight:Vec2<T>()
		Return New Vec2<T>( max.x,min.y )
	Setter( v:Vec2<T> )
		max.x=v.x
		min.y=v.y
	End
	
	#rem monkeydoc The bottom-right of the rect.
	#end
	Property BottomRight:Vec2<T>()
		Return max
	Setter( v:Vec2<T> )
		max=v
	End
	
	#rem monkeydoc The bottom-left of the rect.
	#end
	Property BottomLeft:Vec2<T>()
		Return New Vec2<T>( min.x,max.y )
	Setter( v:Vec2<T> )
		min.x=v.x
		max.y=v.y
	End
	
	#rem monkeydoc True if Right\<=Left or Bottom\<=Top.
	#end
	Property Empty:Bool()
		Return max.x<=min.x Or max.y<=min.y
	End

	#rem monkeydoc Adds another rect to the rect and returns the result.
	#end
	Operator+:Rect( r:Rect )
		Return New Rect( min+r.min,max+r.max )
	End
	
	#rem monkeydoc Subtracts another rect from the rect and returns the result.
	#end
	Operator-:Rect( r:Rect )
		Return New Rect( min-r.min,max-r.max )
	End
	
	#rem monkeydoc Multiples the rect by a vector and returns the result.
	#end
	Operator*:Rect( v:Vec2<T> )
		Return New Rect( min.x*v.x,min.y*v.y,max.x*v.x,max.y*v.y )
	End
	
	#rem monkeydoc Divides the rect by a vector and returns the result.
	#end
	Operator/:Rect( v:Vec2<T> )
		Return New Rect( min.x/v.x,min.y/v.y,max.x/v.x,max.y/v.y )
	End
	
	#rem monkeydoc Adds a vector to the rect and returns the result.
	#end
	Operator+:Rect( v:Vec2<T> )
		Return New Rect( min+v,max+v )
	End
	
	#rem monkeydoc Subtracts a vector from the rect and returns the result.
	#end
	Operator-:Rect( v:Vec2<T> )
		Return New Rect( min-v,max-v )
	End
	
	#rem monkeydoc Adds another rect to the rect.
	#end
	Operator+=( r:Rect )
		min+=r.min
		max+=r.max
	End
	
	#rem monkeydoc Subtracts another rect from the rect.
	#end
	Operator-=( r:Rect )
		min-=r.min
		max-=r.max
	End

	#rem monkeydoc Multiples the rect by a vector.
	#end
	Operator*=( v:Vec2<T> )
		min*=v
		max*=v
	End
	
	#rem monkeydoc Divides the rect by a vector.
	#end
	Operator/=( v:Vec2<T> )
		min/=v
		max/=v
	End
	
	#rem monkeydoc Adds a vector to the rect.
	#end
	Operator+=( v:Vec2<T> )
		min+=v
		max+=v
	End
	
	#rem monkeydoc Subtracts a vector from the rect.
	#end
	Operator-=( v:Vec2<T> )
		min-=v
		max-=v
	End
	
	#rem monkeydoc Computes the intersection of the rect with another rect and returns the result.
	#end
	Operator&:Rect( r:Rect )
		Local x0:=Max( min.x,r.min.x )
		Local y0:=Max( min.y,r.min.y )
		Local x1:=Min( max.x,r.max.x )
		Local y1:=Min( max.y,r.max.y )
		Return New Rect( x0,y0,x1,y1 )
	End

	#rem monkeydoc Computes the union of the rest with another rect and returns the result.
	#end	
	Operator|:Rect( r:Rect )
		Local x0:=Min( min.x,r.min.x )
		Local y0:=Min( min.y,r.min.y )
		Local x1:=Max( max.x,r.max.x )
		Local y1:=Max( max.y,r.max.y )
		Return New Rect( x0,y0,x1,y1 )
	End
	
	#rem monkeydoc Intersects the rect with another rect.
	#end
	Operator&=( r:Rect )
		min.x=Max( min.x,r.min.x )
		min.y=Max( min.y,r.min.y )
		max.x=Min( max.x,r.max.x )
		max.y=Min( max.y,r.max.y )
	End
	
	#rem monkeydoc Unions the rect with another rect.
	#end
	Operator|=( r:Rect )
		min.x=Min( min.x,r.min.x )
		min.y=Min( min.y,r.min.y )
		max.x=Max( max.x,r.max.x )
		max.y=Max( max.y,r.max.y )
	End
	
	#rem monkeydoc Gets the rect centered within another rect.
	#end 
	Method Centered:Rect( r:Rect )
		Local x:=(r.Width-Width)/2+r.min.x
		Local y:=(r.Height-Height)/2+r.min.y
		Return New Rect( x,y,x+Width,y+Height )
	End
	
	#rem monkeydoc Checks if the rect contains a vector or another rect.
	#end
	Method Contains:Bool( v:Vec2<T> )
		Return v.x>=min.x And v.x<max.x And v.y>=min.y And v.y<max.y
	End
	
	Method Contains:Bool( r:Rect )
		Return min.x<=r.min.x And max.x>=r.max.x And min.y<=r.min.y And max.y>=r.max.y
	End
	
	#rem monkeydoc Checks if the rect intersects another rect.
	#end
	Method Intersects:Bool( r:Rect )
		Return r.max.x>min.x And r.min.x<max.x And r.max.y>min.y And r.min.y<max.y
	End
	
	#rem monkeydoc Gets a string describing the rect.
	
	Deprecated: Use Operator To:String instead.
	
	#end
	Method ToString:String()
		Return Self
	End
	
End

#rem monkeydoc Transforms a Rect\<Int\> by an AffineMat3.
#end
Function TransformRecti<T>:Recti( rect:Recti,matrix:AffineMat3<T> )
	
	Local min:=matrix * New Vec2<T>( rect.min.x,rect.min.y )
	Local max:=matrix * New Vec2<T>( rect.max.x,rect.max.y )
		
	Return New Recti( Round( min.x ),Round( min.y ),Round( max.x ),Round( max.y ) )
End

