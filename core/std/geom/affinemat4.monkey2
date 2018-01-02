
Namespace std.geom

#rem monkeydoc Convenience type alias for AffineMat4\<Float\>
#end
Alias AffineMat4f:AffineMat4<Float>

#rem monkeydoc The generic AffineMat4f class provides support for affine 4x4 matrices.

An affine 4x4 matrix is a 4x4 matrix whose right hand column is always 0,0,0,1.

Affine 4x4 matrices are often used for 3d transformations such as scaling, rotation and translation.

Unless otherwise noted, methods and operators always return a new vec3 containing the result, without modifying any parameters or 'self'.

This allows you to chain operators together easily just like 'real' expressions.

#end
Struct AffineMat4<T>

	#rem monkeydoc The matrix component of the matrix.
	#end
	Field m:Mat3<T>

	#rem monkeydoc The translation component of the matrix.
	#end
	Field t:Vec3<T>
	
	#rem monkeydoc Creates a new matrix.
	#end
	Method New()
		m.i.x=1; m.j.y=1; m.k.z=1
	End
	
	Method New( m:Mat3<T> )
		Self.m=m
	End
	
	Method New( t:Vec3<T> )
		m.i.x=1; m.j.y=1; m.k.z=1 ; Self.t=t
	End
	
	Method New( m:Mat3<T>,t:Vec3<T> )
		Self.m=m; Self.t=t
	End
	
	Method New( i:Vec3<T>,j:Vec3<T>,k:Vec3<T>,t:Vec3<T> )
		m.i=i; m.j=j; m.k=k; Self.t=t
	End

	Method New( ix:T,iy:T,iz:T,jx:T,jy:T,jz:T,kx:T,ky:T,kz:T,vx:T,vy:T,vz:T )
		m.i.x=ix; m.i.y=iy; m.i.z=iz
		m.j.x=jx; m.j.y=jy; m.j.z=jz
		m.k.x=kx; m.k.y=ky; m.k.z=kz
		t.x=vx; t.y=vy; t.z=vz
	End
	
	Method new( m:AffineMat3<T> )
		Self.m.i=New Vec3<T>( m.i,0 )
		Self.m.j=New Vec3<T>( m.j,0 )
		Self.m.k=New Vec3<T>( 0,0,1 )
		Self.t=  New Vec3<T>( m.t,1 )
	End
	
	Method New( m:Mat4<T> )
		Self.m.i=m.i.XYZ
		Self.m.j=m.j.XYZ
		Self.m.k=m.k.XYZ
		Self.t=m.t.XYZ
	End
	
	#rem monkeydoc Converts the matrix to a matrix of a different type, or a printable string.
	#end
	Operator To<C>:AffineMat4<C>()
		Return New AffineMat4<C>( m,t )
	End
	
	Operator To:String()
		Return "AffineMat4("+m+","+t+")"
	End
	
	#rem monkeydoc Transposes the matrix.
	
	Transposing a matrix swaps rows and columns.
	
	#End
	Operator~:AffineMat4()
		Local i:=~m
		Return New AffineMat4( i,i*-t )
	End
	
	#rem monkeydoc Inverts the matrix.
	#end
	Operator-:AffineMat4()
		Local i:=-m
		Return New AffineMat4( i,i*-t )
	End
	
	#rem monkeydoc Multiplies the matrix by another matrix.
	#end
	Operator*:AffineMat4( q:AffineMat4 )
		Return New AffineMat4( m*q.m,m*q.t+t )
	End
	
	#rem monkeydoc Multiplies a vector by the matrix.
	#end
	Operator*:Vec3<T>( v:Vec3<T> )
		Return New Vec3<T>( 
			m.i.x*v.x+m.j.x*v.y+m.k.x*v.z+t.x,
			m.i.y*v.x+m.j.y*v.y+m.k.y*v.z+t.y,
			m.i.z*v.x+m.j.z*v.y+m.k.z*v.z+t.z )
	End

	#rem monkeydoc Applies a translation transformation to the matrix.
	#end
	Method Translate:AffineMat4( tx:T,ty:T,tz:T )
		Return Self * Translation( tx,ty,tz )
	End
	
	Method Translate:AffineMat4( tv:Vec3<T> )
		Return Self * Translation( tv )
	End

	#rem monkeydoc Applies a rotation transformation to the matrix.
	#end
	Method Rotate:AffineMat4( rx:Double,ry:Double,rz:Double )
		Return Self * Rotation( rx,ry,rz )
	End

	Method Rotate:AffineMat4( rv:Vec3<Double> )
		Return Self * Rotation( rv )
	End
	
	Method Rotate:AffineMat4( q:Quat<T> )
		Return Self * Rotation( q )
	End
	
	#rem monkeydoc Applies a scaling transformation to the matrix.
	#end
	Method Scale:AffineMat4( sx:T,sy:T,sz:T )
		Return Self * Scaling( sx,sy,sz )
	End
	
	Method Scale:AffineMat4( sv:Vec3<T> )
		Return Self * Scaling( sv )
	End
	
	Method Scale:AffineMat4f( scaling:T )
		Return Self * Scaling( scaling )
	End
	
	#rem monkeydoc Creates a matrix representing a translation.
	#end
	Function Translation:AffineMat4( tv:Vec3<T> )
		Return New AffineMat4( tv )
	End
	
	Function Translation:AffineMat4( tx:T,ty:T,tz:T )
		Return New AffineMat4( New Vec3<T>( tx,ty,tz ) )
	End

	#rem monkeydoc Creates a matrix repsenting a rotation form eular angles or a quat.
	
	Order of rotation is Yaw * Pitch * Roll.
	
	The `rotation` angle  is in radians.
	
	#end
	Function Rotation:AffineMat4( rv:Vec3<Double> )
		Return New AffineMat4( Mat3<T>.Rotation( rv ) )
	End
	
	Function Rotation:AffineMat4( rx:Double,ry:Double,rz:Double )
		Return New AffineMat4( Mat3<T>.Rotation( rx,ry,rz ) )
	End
	
	Function Rotation:AffineMat4( q:Quat<T> )
		Return New AffineMat4( q )
	End
	
	#rem monkeydoc Creates a matrix representing a scaling.
	#end
	Function Scaling:AffineMat4( sv:Vec3<T> )
		Return New AffineMat4( Mat3<T>.Scaling( sv ) )
	End
	
	Function Scaling:AffineMat4( sx:T,sy:T,sz:T )
		Return New AffineMat4( Mat3<T>.Scaling( sx,sy,sz ) )
	End
	
	Function Scaling:AffineMat4( t:T )
		Return Scaling( t,t,t )
	End
	
End
