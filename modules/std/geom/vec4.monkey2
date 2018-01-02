
Namespace std.geom

#rem monkeydoc Convenience type alias for Vec4\<Float\>.
#end
Alias Vec4f:Vec4<Float>

#rem monkeydoc The generic Vec4 type provides support for 4 component vectors.

Unless otherwise noted, methods and operators always return a new vec4 containing the result, without modifying any parameters or 'self'.

This allows you to chain operators together easily just like 'real' expressions.

#end
Struct Vec4<T>

	#rem monkeydoc The vector x coordinate.
	#end
	Field x:T

	#rem monkeydoc The vector y coordinate.
	#end
	Field y:T

	#rem monkeydoc The vector z coordinate.
	#end
	Field z:T

	#rem monkeydoc The vector w coordinate.
	#end
	Field w:T
	
	#rem Creates a new vec4.
	#end
	Method New()
	End
	
	Method New( t:T )
		x=t;y=t;z=t;w=t
	End
	
	Method New( x:T,y:T,z:T,w:T )
		Self.x=x;Self.y=y;Self.z=z;Self.w=w
	End
	
	Method New( xy:Vec2<T>,z:T,w:T )
		Self.x=xy.x;Self.y=xy.y;Self.z=z;Self.w=w
	End
	
	Method New( x:T,yz:Vec2<T>,w:T )
		Self.x=x;Self.y=yz.x;Self.z=yz.y;Self.w=w
	End
	
	Method New( x:T,y:T,zw:Vec2<T> )
		Self.x=x;Self.y=y;Self.z=zw.x;Self.w=zw.y
	End
	
	Method New( xyz:Vec3<T>,w:T )
		Self.x=xyz.x;Self.y=xyz.y;Self.z=xyz.z;Self.w=w
	End
	
	Method new( x:T,yzw:Vec3<T> )
		Self.x=x;Self.y=yzw.x;self.z=yzw.y;Self.w=yzw.z
	End
	
	#Rem monkeydoc Converts the vec4 to a vec4 of a different type or a printable string.
	#end
	Operator To<C>:Vec4<C>()
		Return New Vec4<C>( x,y,z )
	End
	
	Operator To:String()
		Return "Vec4("+x+","+y+","+z+","+w+")"
	End
	
	#rem monkeydoc The X coordinate of the vec4.
	#end
	Property X:T()
		Return x
	Setter( x:T )
		Self.x=x
	End
	
	#rem monkeydoc The Y coordinate of the vec4.
	#end
	Property Y:T()
		Return y
	Setter( y:T )
		Self.y=y
	End
	
	#rem monkeydoc The Y coordinate of the vec4.
	#end
	Property Z:T()
		Return z
	Setter( z:T )
		Self.z=z
	End
	
	#rem monkeydoc The Y coordinate of the vec4.
	#end
	Property W:T()
		Return w
	Setter( w:T )
		Self.w=w
	End
	
	#rem monkeydoc The XY components as a vec2.
	#end
	Property XY:Vec2<T>()
		Return New Vec2<T>( x,y )
	Setter( xy:Vec2<T> )
		x=xy.x;y=xy.y
	End
	
	#rem monkeydoc The XYZ components as a vec3.
	#end
	Property XYZ:Vec3<T>()
		Return New Vec3<T>( x,y,z )
	Setter( xyz:Vec3<T> )
		x=xyz.x;y=xyz.y;z=xyz.z
	End

	#rem monkeydoc Negates the vec4.
	#end
	Operator-:Vec4()
		Return New Vec4( -x,-y,-z,-w )
	End
	
	#rem monkeydoc Multiplies the vec4 by another vec4.
	#end
	Operator*:Vec4( v:Vec4 )
		Return New Vec4( x*v.x,y*v.y,z*v.z,w*v.w )
	End
	
	#rem monkeydoc Divides the vec4 by another vec4.
	#end
	Operator/:Vec4( v:Vec4 )
		Return New Vec4( x/v.x,y/v.y,z/v.z,w/v.w )
	End
	
	#rem monkeydoc Adds the vec4 to another vec4.
	#end
	Operator+:Vec4( v:Vec4 )
		Return New Vec4( x+v.x,y+v.y,z+v.z,w+v.w )
	End
	
	#rem monkeydoc Subtracts another vec4 from the vec4.
	#end
	Operator-:Vec4( v:Vec4 )
		Return New Vec4( x-v.x,y-v.y,z-v.z,w-v.w )
	End
	
	#rem monkeydoc Multiplies the vec4 by a scalar.
	#end
	Operator*:Vec4( s:Double )
		Return New Vec4( x*s,y*s,z*s,w*s )
	End
	
	#rem monkeydoc Divides the vec4 by a scalar.
	#end
	Operator/:Vec4( s:Double )
		Return New Vec4( x/s,y/s,z/s,w/s )
	End
	
	#rem monkeydoc Adds a scalar to each component of the vec4.
	#end
	Operator+:Vec4( s:T )
		Return New Vec4( x+s,y+s,z+s,w+s )
	End
	
	#rem monkeydoc Subtracts a scalar from each component of the vec4.
	#end
	Operator-:Vec4( s:T )
		Return New Vec4( x-s,y-s,z-s,w-s )
	End
	
	#rem monkeydoc Returns the length of the vec4.
	#end
	Property Length:Double()
		Return Sqrt( x*x+y*y+z*z )
	End

	#rem monkeydoc Normalizes the vec4.
	#end
	Method Normalize:Vec4()
		Return Self/Length
	End
	
	#rem monkeydoc Returns the dot product of the vec4 with another vec4.
	#end
	Method Dot:Double( v:Vec4 )
		Return x*v.x+y*v.y+z*v.z+w*v.w
	End
	
	Method Blend:Vec4( v:Vec4,alpha:Double )
		Return New Vec4( (v.x-x)*alpha+x,(v.y-y)*alpha+y,(v.z-z)*alpha+z,(v.w-w)*alpha+w )
	End
	
	Method ToString:String()
		Return "Vec4("+x+","+y+","+z+","+w+")"
	End

End
