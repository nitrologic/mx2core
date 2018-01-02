
Namespace std.geom

#rem monkeydoc Convenience type alias for Mat4\<Float\>.
#end
Alias Mat4f:Mat4<Float>

#rem monkeydoc The generic Mat3 class provides support for 4x4 matrices.
#end
Struct Mat4<T>

	Field i:Vec4<T>
	Field j:Vec4<T>
	Field k:Vec4<T>
	Field t:Vec4<T>
	
	Method New()
		i.x=1;j.y=1;k.z=1;t.w=1
	End
	
	Method New( ix:T,jy:T,kz:T,tw:T )
		i.x=ix;j.y=jy;k.z=kz;t.w=tw
	End
	
	Method New( i:Vec4<T>,j:Vec4<T>,k:Vec4<T>,t:Vec4<T> )
		Self.i=i;Self.j=j;Self.k=k;Self.t=t
	End
	
	Method New( m:Mat3<T> )
		i.XYZ=m.i ; j.XYZ=m.j ; k.XYZ=m.k ; t.w=1
	End
	
	Method New( m:AffineMat3<T> )
		i.XY=m.i ; j.XY=m.j ; k.z=1 ; t.XY=m.t ; t.w=1
	End
	
	Method New( m:AffineMat4<T> )
		i.XYZ=m.m.i ; j.XYZ=m.m.j ; k.XYZ=m.m.k ; t.XYZ=m.t ; t.w=1
	End
	
	Operator To<C>:Mat4<C>()
		Return New Mat4<C>( i,j,k,t )
	End
	
	Operator To:String()
		Return "Mat4("+i+","+j+","+k+","+t+")"
	End
	
	Operator~:Mat4()
		Return New Mat4(
			New Vec4<T>( i.x,j.x,k.x,t.x ),
			New Vec4<T>( i.y,j.y,k.y,t.y ),
			New Vec4<T>( i.z,j.z,k.z,t.z ),
			New Vec4<T>( i.w,j.w,k.w,t.w ) )
	End
	
	Operator-:Mat4()
		Local ii:=New Vec4<T>(
			 j.y * k.z * t.w - j.y * k.w * t.z - k.y * j.z * t.w + k.y * j.w * t.z + t.y * j.z * k.w - t.y * j.w * k.z,
			-i.y * k.z * t.w + i.y * k.w * t.z + k.y * i.z * t.w - k.y * i.w * t.z - t.y * i.z * k.w + t.y * i.w * k.z,
			 i.y * j.z * t.w - i.y * j.w * t.z - j.y * i.z * t.w + j.y * i.w * t.z + t.y * i.z * j.w - t.y * i.w * j.z,
			-i.y * j.z * k.w + i.y * j.w * k.z + j.y * i.z * k.w - j.y * i.w * k.z - k.y * i.z * j.w + k.y * i.w * j.z )
		Local jj:=New Vec4<T>(
			-j.x * k.z * t.w + j.x * k.w * t.z + k.x * j.z * t.w - k.x * j.w * t.z - t.x * j.z * k.w + t.x * j.w * k.z,
			 i.x * k.z * t.w - i.x * k.w * t.z - k.x * i.z * t.w + k.x * i.w * t.z + t.x * i.z * k.w - t.x * i.w * k.z,
			-i.x * j.z * t.w + i.x * j.w * t.z + j.x * i.z * t.w - j.x * i.w * t.z - t.x * i.z * j.w + t.x * i.w * j.z,
			 i.x * j.z * k.w - i.x * j.w * k.z - j.x * i.z * k.w + j.x * i.w * k.z + k.x * i.z * j.w - k.x * i.w * j.z )
		Local kk:=New Vec4<T>(
			 j.x * k.y * t.w - j.x * k.w * t.y - k.x * j.y * t.w + k.x * j.w * t.y + t.x * j.y * k.w - t.x * j.w * k.y,
			-i.x * k.y * t.w + i.x * k.w * t.y + k.x * i.y * t.w - k.x * i.w * t.y - t.x * i.y * k.w + t.x * i.w * k.y,
			 i.x * j.y * t.w - i.x * j.w * t.y - j.x * i.y * t.w + j.x * i.w * t.y + t.x * i.y * j.w - t.x * i.w * j.y,
			-i.x * j.y * k.w + i.x * j.w * k.y + j.x * i.y * k.w - j.x * i.w * k.y - k.x * i.y * j.w + k.x * i.w * j.y )
		Local tt:=New Vec4<T>(
			-j.x * k.y * t.z + j.x * k.z * t.y + k.x * j.y * t.z - k.x * j.z * t.y - t.x * j.y * k.z + t.x * j.z * k.y,
			 i.x * k.y * t.z - i.x * k.z * t.y - k.x * i.y * t.z + k.x * i.z * t.y + t.x * i.y * k.z - t.x * i.z * k.y,
			-i.x * j.y * t.z + i.x * j.z * t.y + j.x * i.y * t.z - j.x * i.z * t.y - t.x * i.y * j.z + t.x * i.z * j.y,
			 i.x * j.y * k.z - i.x * j.z * k.y - j.x * i.y * k.z + j.x * i.z * k.y + k.x * i.y * j.z - k.x * i.z * j.y )
			
		Local c:T=1/(i.x*ii.x + i.y * jj.x + i.z * kk.x + i.w * tt.x)
		
		Return New Mat4( ii*c,jj*c,kk*c,tt*c )
	End
	
	Operator*:Mat4( m:Mat4 )
		Local r:Mat4
		
		r.i.x=i.x*m.i.x + j.x*m.i.y + k.x*m.i.z + t.x*m.i.w 
		r.i.y=i.y*m.i.x + j.y*m.i.y + k.y*m.i.z + t.y*m.i.w
		r.i.z=i.z*m.i.x + j.z*m.i.y + k.z*m.i.z + t.z*m.i.w
		r.i.w=i.w*m.i.x + j.w*m.i.y + k.w*m.i.z + t.w*m.i.w
		
		r.j.x=i.x*m.j.x + j.x*m.j.y + k.x*m.j.z + t.x*m.j.w 
		r.j.y=i.y*m.j.x + j.y*m.j.y + k.y*m.j.z + t.y*m.j.w
		r.j.z=i.z*m.j.x + j.z*m.j.y + k.z*m.j.z + t.z*m.j.w
		r.j.w=i.w*m.j.x + j.w*m.j.y + k.w*m.j.z + t.w*m.j.w
		
		r.k.x=i.x*m.k.x + j.x*m.k.y + k.x*m.k.z + t.x*m.k.w 
		r.k.y=i.y*m.k.x + j.y*m.k.y + k.y*m.k.z + t.y*m.k.w
		r.k.z=i.z*m.k.x + j.z*m.k.y + k.z*m.k.z + t.z*m.k.w
		r.k.w=i.w*m.k.x + j.w*m.k.y + k.w*m.k.z + t.w*m.k.w
		
		r.t.x=i.x*m.t.x + j.x*m.t.y + k.x*m.t.z + t.x*m.t.w 
		r.t.y=i.y*m.t.x + j.y*m.t.y + k.y*m.t.z + t.y*m.t.w
		r.t.z=i.z*m.t.x + j.z*m.t.y + k.z*m.t.z + t.z*m.t.w
		r.t.w=i.w*m.t.x + j.w*m.t.y + k.w*m.t.z + t.w*m.t.w
		
		Return r
	End
	
	Operator*:Mat4( m:AffineMat4<T> )

		Local r:Mat4
		
		r.i.x=i.x*m.m.i.x + j.x*m.m.i.y + k.x*m.m.i.z
		r.i.y=i.y*m.m.i.x + j.y*m.m.i.y + k.y*m.m.i.z
		r.i.z=i.z*m.m.i.x + j.z*m.m.i.y + k.z*m.m.i.z
		r.i.w=i.w*m.m.i.x + j.w*m.m.i.y + k.w*m.m.i.z
		
		r.j.x=i.x*m.m.j.x + j.x*m.m.j.y + k.x*m.m.j.z
		r.j.y=i.y*m.m.j.x + j.y*m.m.j.y + k.y*m.m.j.z
		r.j.z=i.z*m.m.j.x + j.z*m.m.j.y + k.z*m.m.j.z
		r.j.w=i.w*m.m.j.x + j.w*m.m.j.y + k.w*m.m.j.z
		
		r.k.x=i.x*m.m.k.x + j.x*m.m.k.y + k.x*m.m.k.z
		r.k.y=i.y*m.m.k.x + j.y*m.m.k.y + k.y*m.m.k.z
		r.k.z=i.z*m.m.k.x + j.z*m.m.k.y + k.z*m.m.k.z
		r.k.w=i.w*m.m.k.x + j.w*m.m.k.y + k.w*m.m.k.z
		
		r.t.x=i.x*m.t.x   + j.x*m.t.y   + k.x*m.t.z + t.x
		r.t.y=i.y*m.t.x   + j.y*m.t.y   + k.y*m.t.z + t.y
		r.t.z=i.z*m.t.x   + j.z*m.t.y   + k.z*m.t.z + t.z
		r.t.w=i.w*m.t.x   + j.w*m.t.y   + k.w*m.t.z + t.w
		
		Return r
	End
	
	Operator*:Mat4( m:Mat3<T> )

		Local r:Mat4
		
		r.i.x=i.x*m.i.x + j.x*m.i.y + k.x*m.i.z
		r.i.y=i.y*m.i.x + j.y*m.i.y + k.y*m.i.z
		r.i.z=i.z*m.i.x + j.z*m.i.y + k.z*m.i.z
		r.i.w=i.w*m.i.x + j.w*m.i.y + k.w*m.i.z
		
		r.j.x=i.x*m.j.x + j.x*m.j.y + k.x*m.j.z
		r.j.y=i.y*m.j.x + j.y*m.j.y + k.y*m.j.z
		r.j.z=i.z*m.j.x + j.z*m.j.y + k.z*m.j.z
		r.j.w=i.w*m.j.x + j.w*m.j.y + k.w*m.j.z
		
		r.k.x=i.x*m.k.x + j.x*m.k.y + k.x*m.k.z
		r.k.y=i.y*m.k.x + j.y*m.k.y + k.y*m.k.z
		r.k.z=i.z*m.k.x + j.z*m.k.y + k.z*m.k.z
		r.k.w=i.w*m.k.x + j.w*m.k.y + k.w*m.k.z
		
		r.t.x=t.x
		r.t.y=t.y
		r.t.z=t.z
		r.t.w=t.w
		
		Return r
	End
	
	Operator*:Vec4<T>( v:Vec4<T> )
		Return New Vec4<T>( 
			i.x*v.x+j.x*v.y+k.x*v.z+t.x*v.w,
		 	i.y*v.x+j.y*v.y+k.y*v.z+t.y*v.w,
		 	i.z*v.x+j.z*v.y+k.z*v.z+t.z*v.w,
		 	i.w*v.x+j.w*v.y+k.w*v.z+t.w*v.w )
	End
	
	Operator*:Vec3<T>( v:Vec3<T> )
		Return New Vec3<T>(
			i.x*v.x+j.x*v.y+k.x*v.z+t.x,
		 	i.y*v.x+j.y*v.y+k.y*v.z+t.y,
		 	i.z*v.x+j.z*v.y+k.z*v.z+t.z ) / (i.w*v.x+j.w*v.y+k.w*v.z+t.w)
	End
	
	#rem monkeydoc Creates a translation matrix.
	#end
	Function Translation:Mat4( tv:Vec3<T> )
		Return Translation( tv.x,tv.y,tv.z )
	End
	
	Function Translation:Mat4( tx:T,ty:T,tz:T )
		Local r:=New Mat4
		r.t.x=tx;r.t.y=ty;r.t.z=tz;r.t.w=1
		Return r
	End

	#rem monkeydoc Creates a rotation matrix for euler angles or a quat.
	#end
	Function Rotation:Mat4( rv:Vec3<Double> )
		Return Rotation( rv.x,rv.y,rv.z )
	End
	
	Function Rotation:Mat4( rx:Double,ry:Double,rz:Double )
		Return New Mat4( Mat3<T>.Rotation( rx,ry,rz ) )
	End
	
	Function Rotation:Mat4( q:Quat<T> )
		Return New Mat4( q )
	End
	
	#rem monkeydoc Creates a scaling matrix.
	#end
	Function Scaling:Mat4( sx:T,sy:T,sz:T )
		Return New Mat4( sx,sy,sz,1 )
	End
	
	Function Scaling:Mat4( sv:Vec3<T> )
		Return Scaling( sv.x,sv.y,sv.z )
	End
	
	Function Scaling:Mat4( t:T )
		Return Scaling( t,t,t )
	End

	#rem monkeydoc Creates an orthographic projection matrix.
	#End	
	Function Ortho:Mat4( left:T,right:T,bottom:T,top:T,near:T,far:T )

		Local w:=right-left,h:=top-bottom,d:=far-near,r:Mat4

		r.i.x=2/w
		r.j.y=2/h
		r.k.z=2/d
		r.t.x=-(right+left)/w
		r.t.y=-(top+bottom)/h
		r.t.z=-(far+near)/d
		r.t.w=1

		Return r
	End
	
	Function Frustum:Mat4( left:T,right:T,bottom:T,top:T,near:T,far:T )
	
		Local w:=right-left,h:=top-bottom,d:=far-near,near2:=near*2,r:Mat4

		r.i.x=near2/w
		r.j.y=near2/h
		r.k.x=(right+left)/w
		r.k.y=(top+bottom)/h
		r.k.z=(far+near)/d
		r.k.w=1
		r.t.z=-(far*near2)/d
		
		Return r
	End
	
	Function Perspective:Mat4( fovy:Double,aspect:T,znear:T,zfar:T )
		
		Local h:T=Tan(fovy * Pi / 360.0) * znear

		Local w:T=h * aspect
		
		Return Frustum( -w,w,-h,h,znear,zfar )
	End
	
End
