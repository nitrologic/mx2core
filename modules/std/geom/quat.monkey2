
Namespace std.geom

#rem monkeydoc Convenience type alias for Quat\<Float\>.
#end
Alias Quatf:Quat<Float>

#rem monkeydoc The Quat class provides support for quaternions.
#end
Struct Quat<T>

	Field v:Vec3<T>
	Field w:T
	
	Method New()
		w=1
	End
	
	Method New( v:Vec3<T>,w:Float )
		Self.v=v; Self.w=w
	End
	
	Method New( vx:T,vy:T,vz:T,w:T )
		v.x=vx ; v.y=vy ; v.z=vz ; Self.w=w
	End
	
	Method New( m:Mat3<T> )
	
		'Note: assumes m is orthogonalized
		'
		Const EPSILON:=0
	
		Local t:=m.i.x+m.j.y+m.k.z
		
		If t>EPSILON
			t=Sqrt( t+1 )*2
			v.x=(m.k.y-m.j.z)/t
			v.y=(m.i.z-m.k.x)/t
			v.z=(m.j.x-m.i.y)/t
			w=t/4
		Else If m.i.x>m.j.y And m.i.x>m.k.z
			t=Sqrt( m.i.x-m.j.y-m.k.z+1 )*2
			v.x=t/4
			v.y=(m.j.x+m.i.y)/t
			v.z=(m.i.z+m.k.x)/t
			w=(m.k.y-m.j.z)/t
		Else If m.j.y>m.k.z
			t=Sqrt( m.j.y-m.k.z-m.i.x+1 )*2
			v.x=(m.j.x+m.i.y)/t
			v.y=t/4
			v.z=(m.k.y+m.j.z)/t
			w=(m.i.z-m.k.x)/t
		Else
			t=Sqrt( m.k.z-m.j.y-m.i.x+1 )*2
			v.x=(m.i.z+m.k.x)/t
			v.y=(m.k.y+m.j.z)/t
			v.z=t/4
			w=(m.j.x-m.i.y)/t
		Endif
		
	End
	
	Operator To<C>:Quat<C>()
		Return New Quat<C>( v,w )
	End
	
	Operator To:Mat3<T>()
		Return New Mat3<T>( Self )
	End
	
	Method To:String()
		Return "Quat("+v+","+w+")"
	End
	
	Property Length:Double()
		Return Sqrt( v.Dot(v) + w*w )
	End
	
	Property I:Vec3<T>()
		Local xz:=v.x*v.z , wy:=w*v.y
		Local xy:=v.x*v.y , wz:=w*v.z
		Local yy:=v.y*v.y , zz:=v.z*v.z
		Return New Vec3<T>( 1-2*(yy+zz),2*(xy-wz),2*(xz+wy) )
	End

	Property J:Vec3<T>()
		Local yz:=v.y*v.z , wx:=w*v.x
		Local xy:=v.x*v.y , wz:=w*v.z
		Local xx:=v.x*v.x , zz:=v.z*v.z
		Return New Vec3<T>( 2*(xy+wz),1-2*(xx+zz),2*(yz-wx) )
	End
	
	Property K:Vec3<T>()
		Local xz:=v.x*v.z , wy:=w*v.y
		Local yz:=v.y*v.z , wx:=w*v.x
		Local xx:=v.x*v.x , yy:=v.y*v.y
		Return New Vec3<T>( 2*(xz-wy),2*(yz+wx),1-2*(xx+yy) )
	End
	
	Operator-:Quat()
		Return New Quat( -v,w )
	End
	
	Operator+:Quat( q:Quat )
		Return New Quat( v+q.v,w+q.w )
	End
	
	Operator-:Quat( q:Quat )
		Return New Quat( v-q.v,w-q.w )
	End
	
	Operator*:Quat( q:Quat )
		Return New Quat( q.v.Cross( v )+q.v*w+v*q.w, w*q.w-v.Dot( q.v ) )
	End
	
	Operator*:Vec3<T>( v:Vec3<T> )
		Return (Self * New Quat( v,0 ) * -Self).v
	End
	
	Operator*:Quat( t:Double )
		Return New Quat( v*t,w*t )
	End
	
	Operator/:Quat( t:Double )
		Return New Quat( v/t,w/t )
	End
	
	Method GetYaw:Double()
		Return K.Yaw
	End
	
	Method GetPitch:Double()
		Return K.Pitch
	End
	
	Method GetRoll:Double()
		Return ATan2( I.y,J.y )
	End
	
	Method Dot:Double( q:Quat )
		Return v.x*q.v.x + v.y*q.v.y + v.z*q.v.z + w*q.w
	End
	
	Method Normalize:Quat()
		Return Self/Length
	End
	
	Method Slerp:Quat( q:Quat,a:Double )
	
		Const EPSILON:=0
	
		Local t:=q
		Local b:=1-a
		Local d:=Dot( q )
		If d<0 
			t.v=-t.v
			t.w=-t.w
			d=-d
		Endif
		If d<1-EPSILON
			Local om:=ACos( d )
			Local si:=Sin( om )
			a=Sin( a*om )/si
			b=Sin( b*om )/si
		Endif
		Return Self*b + t*a
	End
	
	Function Pitch:Quat( r:Double )
		Return New Quat( Sin( r/2 ),0,0,Cos( r/2 ) )
	End

	Function Yaw:Quat( r:Double )
		Return New Quat( 0,Sin( r/2 ),0,Cos( r/2 ) )
	End

	Function Roll:Quat( r:Double )
		Return New Quat( 0,0,Sin( r/2 ),Cos( r/2 ) )
	End

	Function Rotation:Quat( rv:Vec3<Double> )
		Return Yaw( rv.y ) * Pitch( rv.x ) * Roll( rv.z )
	End
	
	Function Rotation:Quat( rx:Double,ry:Double,rz:Double )
		Return Yaw( ry ) * Pitch( rx ) * Roll( rz )
	End

End
