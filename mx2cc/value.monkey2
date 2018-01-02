
Namespace mx2

Const VALUE_LVALUE:=1
Const VALUE_ASSIGNABLE:=2

Class Value Extends SNode

	Field type:Type
	Field flags:Int
	
	Method ToString:String() Override
'		Return "????? VALUE ????? "+String.FromCString( typeName() )
		Return "????? VALUE ????? "
	End
	
	Method ToValue:Value( instance:Value ) Override
		Return Self
	End
	
	Property IsLValue:Bool()
		Return (flags & VALUE_LVALUE)<>0
	End
	
	Property IsAssignable:Bool()
		Return (flags & VALUE_ASSIGNABLE)<>0
	End
	
	Property HasSideEffects:Bool() Virtual
		Return False
	End
	
	Method RemoveSideEffects:Value( block:Block ) Virtual
		Return Self
	End

	Method ToRValue:Value() Virtual
		Return Self
	End
	
	Method UpCast:Value( type:Type ) Virtual
		Local rvalue:=ToRValue()
		Return rvalue.type.UpCast( rvalue,type )
	End
	
	Method FindValue:Value( ident:String ) Virtual
		Local rvalue:=ToRValue()
		Local node:=rvalue.type.FindNode( ident )
		If node Return node.ToValue( rvalue )
		Return Null
	End

	Method Invoke:Value( args:Value[] ) Virtual
		Local rvalue:=ToRValue()
		Return rvalue.type.Invoke( args,rvalue )
	End
	
	Method Index:Value( args:Value[] ) Virtual
		Local rvalue:=ToRValue()
		Return rvalue.type.Index( args,rvalue )
	End
	
	Method GenInstance:Value( types:Type[] ) Virtual
		Throw New SemantEx( "Value '"+ToString()+"' is Not generic" )
	End
	
	Method Assign:Stmt( pnode:PNode,op:String,value:Value,block:Block ) Virtual
		If Not IsAssignable SemantError( "Value.Assign()" )
		
		Local rtype:=BalanceAssignTypes( op,type,value.type )
		Return New AssignStmt( pnode,op,Self,value.UpCast( rtype ) )
	End
	
	Method Compare:Value( op:String,rhs:Value )
		
		Local rvalue:=ToRValue()
		rhs=rhs.ToRValue()
		
		If Not type.Equals( rhs.type ) SemantError( "Value.Compare" )
			
		Local ctype:=TCast<ClassType>( rvalue.type )
		
		If ctype And ctype.IsStruct
			Local node:=rvalue.FindValue( op )
			If node
				Return node.Invoke( New Value[]( rhs ) )
			Endif
			node=rvalue.FindValue( "<=>" )
			If node
				Local cmp:=node.Invoke( New Value[]( rhs ) )
				Return New BinaryopValue( Type.BoolType,op,cmp,LiteralValue.NullValue( cmp.type ) )
			Endif
		Endif
		
		Return New BinaryopValue( Type.BoolType,op,rvalue,rhs )
	End
	
	Method CheckAccess( tscope:Scope ) Virtual
	End
	
	Function CheckAccess( decl:Decl,scope:Scope,tscope:Scope )
	
		If decl.IsInternal
			If scope.FindFile().fdecl.module=tscope.FindFile().fdecl.module Return

			Throw New SemantEx( "Internal declaration '"+decl.ident+"' cannot be accessed from here." )
		Endif
			
		If decl.IsPublic Return

		Local cscope:=Cast<ClassScope>( scope )
		If cscope
			
			If scope.FindFile()=tscope.FindFile() Return

			Local ctype:=cscope.ctype
			Local ctype2:=tscope.FindClass()
			
			If decl.IsPrivate
			
				If ctype=ctype2 Return
				
				Throw New SemantEx( "Private member '"+decl.ident+"' cannot be accessed from here." )
				
			Else If decl.IsProtected
			
				While ctype2
					If ctype=ctype2 Return
					ctype2=ctype2.superType
				Wend
				
				Throw New SemantEx( "Protected member '"+decl.ident+"' cannot be accessed from here." )

			Endif

		Endif
		
	End
	
End

Class TypeValue Extends Value

	Field ttype:Type
	
	Method New( ttype:Type )
		Self.type=Type.VoidType
		Self.ttype=ttype
	End
	
	Method ToString:String() Override
		Return "<"+ttype.ToString()+">"
	End
	
	Method FindValue:Value( ident:String ) Override
		Local node:=ttype.FindNode( ident )
		If node Return node.ToValue( Null )
		Return Null
	End
End

Class UpCastValue Extends Value

	Field value:Value

	Method New( type:Type,value:Value )
		Self.type=type
		Self.value=value

	End
	
	Method ToString:String() Override
		Return value.ToString()
	End

	Property HasSideEffects:Bool() Override
		Return value.HasSideEffects
	End
	
	Method RemoveSideEffects:Value( block:Block ) Override
		If Not HasSideEffects Return Self
		Return New UpCastValue( type,value.RemoveSideEffects( block ) )
	End
	
	Method CheckAccess( tscope:Scope ) Override
		value.CheckAccess( tscope )
	End
	
End

Class ExplicitCastValue Extends Value

	Field value:Value
	
	Method New( type:Type,value:Value )
		Self.type=type
		Self.value=value
	End
	
	Method ToString:String() Override
		Return "Cast<"+type.ToString()+">("+value.ToString()+")"
	End

	Property HasSideEffects:Bool() Override
		Return value.HasSideEffects
	End
	
	Method RemoveSideEffects:Value( block:Block ) Override
		If Not HasSideEffects Return Self
		Return New ExplicitCastValue( type,value.RemoveSideEffects( block ) )
	End
	
End

Class SelfValue Extends Value

	Field ctype:ClassType
	Field func:FuncValue
	
	Method New( ctype:ClassType,func:FuncValue )
		Self.type=ctype
		Self.ctype=ctype
		Self.func=func
		
		If ctype.IsStruct flags|=VALUE_LVALUE
'		If ctype.IsStruct And Not func.IsExtension flags|=VALUE_LVALUE
	End
	
	Method ToString:String() Override
		Return "Self"
	End
	
End

Class SuperValue Extends Value

	Field ctype:ClassType

	Method New( ctype:ClassType )
		Self.type=ctype
		Self.ctype=ctype
	End
	
	Method ToString:String() Override
		Return "Super"
	End

End

Class LiteralValue Extends Value

	Field value:String
	
	Method New( type:Type,value:String )
		Self.type=type
		
		Local ptype:=TCast<PrimType>( type )
		If ptype And ptype.IsNumeric
			
			If ptype.IsIntegral And value.StartsWith( "-" )
				value="-"+String( ULong( value.Slice(1) ) )
			Else If ptype.IsIntegral
				value=String( ULong( value ) )
			Else If ptype.IsReal
				value=String( Double( value ))
			Else
				SemantError( "LiteralValue.New() type="+ptype.ToString() )
			End
			
		Endif
		
		Self.value=value
	End
	
	Method ToString:String() Override
		If value Return value
		Return "Null"
	End
	
	Method UpCast:Value( type:Type ) Override
	
		Local d:=Self.type.DistanceToType( type )
		If d<0 Throw New UpCastEx( Self,type )
		If d=0 Return Self
		
		'upcast to...
		Local ptype:=TCast<PrimType>( type )
		If Not ptype Return New UpCastValue( type,Self )
		
		Local ptype2:=TCast<PrimType>( Self.type )
		If Not ptype2 Return New UpCastValue( type,Self )
		
		Local result:=""
		
		If ptype=Type.BoolType
			If ptype2.IsIntegral And value.StartsWith( "-" )
				result=ULong( value.Slice(1) ) ? "true" Else "false"
			Else If ptype2.IsIntegral
				result=ULong( value ) ? "true" Else "false"
			Else If ptype2.IsReal
				result=Double( value ) ? "true" Else "false"
			Else If ptype2=Type.StringType
				result=Bool( value ) ? "true" Else "false"
			Else
				SemantError( "LiteralValue.UpCast()" )
			Endif
		Else If ptype.IsIntegral
			If ptype2=Type.BoolType
				result=value="true" ? "1" Else "0"
			Else If ptype2.IsNumeric Or ptype2=Type.StringType
				result=value
			Else
				SemantError( "LiteralValue.UpCast()" )
			Endif
		Else If ptype.IsReal
			If ptype2=Type.BoolType
				result=value="true" ? "1.0" Else "0.0"
			Else If ptype2.IsNumeric Or ptype2=Type.StringType
				result=value
			Else
				SemantError( "LiteralValue.UpCast()" )
			Endif
		Else If ptype=Type.StringType
			result=value
		Else If ptype=Type.VariantType
			Return New UpCastValue( Type.VariantType,Self )
		Else
			SemantError( "LiteralValue.UpCast()" )
		End
		
		Return New LiteralValue( type,result )
	End
	
	Property HasSideEffects:Bool() Override
		Return type=Type.StringType
	End
	
	Method RemoveSideEffects:Value( block:Block ) Override
		If HasSideEffects Return block.AllocLocal( Self )
		Return Self
	End
	
	Function BoolValue:LiteralValue( value:Bool )
		If value Return New LiteralValue( Type.BoolType,"true" )
		Return New LiteralValue( Type.BoolType,"false" )
	End

	Function IntValue:LiteralValue( value:Int )
		Return New LiteralValue( Type.IntType,String( value ) )
	End
	
	Function NullValue:LiteralValue( type:Type )
		If type.Equals( Type.VoidType ) Throw New SemantEx( "Null value cannot have void type" )
		Return New LiteralValue( type,"" )
	end
End

Class NullValue Extends Value

	Method New()
		Self.type=Type.NullType
	End
	
	Method ToString:String() Override
		Return "Null"
	End
	
	Method ToRValue:Value() Override
		Throw New SemantEx( "'Null' has no type!" )
		Return Null
	End
		
	Method UpCast:Value( type:Type ) Override
		Return LiteralValue.NullValue( type )
	End
	
End

Class InvokeValue Extends Value

	Field ftype:FuncType
	Field value:Value
	Field args:Value[]
	
	Method New( value:Value,args:Value[] )
		Self.ftype=TCast<FuncType>( value.type )
		Self.type=ftype.retType
		Self.value=value
		Self.args=args
	End
	
	Method ToString:String() Override
		Return value.ToString()+"("+Join( args )+")!"
	End
	
	Property HasSideEffects:Bool() Override
		Return True
	End
	
	Method RemoveSideEffects:Value( block:Block ) Override
		Return block.AllocLocal( Self )
	End
	
	Method CheckAccess( scope:Scope ) Override
		value.CheckAccess( scope )
		For Local arg:=Eachin args
			arg.CheckAccess( scope )
		Next
	End
	
End

Class InvokeNewValue Extends Value

	Field ctype:ClassType
	Field args:Value[]
	
	Method New( ctype:ClassType,args:Value[] )
		Self.type=Type.VoidType
		Self.ctype=ctype
		Self.args=args
	End
	
	Method ToString:String() Override
		Return "New("+Join( args )+")"
	End
	
End

Class NewObjectValue Extends Value

	Field ctype:ClassType
	Field ctor:FuncValue
	Field args:Value[]
	
	Method New( ctype:ClassType,ctor:FuncValue,args:Value[] )
		Self.type=ctype
		Self.ctype=ctype
		self.ctor=ctor
		Self.args=args
	End
	
	Method ToString:String() Override
		Return "New "+ctype.ToString()+"("+Join( args )+")"
	End

	Property HasSideEffects:Bool() Override
		Return True
	End
	
	Method RemoveSideEffects:Value( block:Block ) Override
		Return block.AllocLocal( Self )
	End
	
End

Class NewArrayValue Extends Value

	Field atype:ArrayType
	Field sizes:Value[]
	Field inits:Value[]
	
	Method New( atype:ArrayType,sizes:Value[],inits:Value[] )
		Self.type=atype
		Self.atype=atype
		Self.sizes=sizes
		Self.inits=inits
	End
	
	Method ToString:String() Override
		If inits Return atype.ToString()+"("+Join( inits )+")"
		Return "New "+atype.elemType.ToString()+"["+Join( sizes )+"]"
	End
	
	Property HasSideEffects:Bool() Override
		Return True
	End
	
	Method RemoveSideEffects:Value( block:Block ) Override
		Return block.AllocLocal( Self )
	End
	
End

Class ArrayIndexValue Extends Value

	Field atype:ArrayType
	Field value:Value
	Field args:Value[]
	
	Method New( atype:ArrayType,value:Value,args:Value[] )
		Self.type=atype.elemType
		Self.atype=atype
		Self.value=value
		Self.args=args
		
		flags|=VALUE_LVALUE|VALUE_ASSIGNABLE
	End
	
	Method ToString:String() Override
		Return value.ToString()+"["+Join( args )+"]"
	End
	
	Property HasSideEffects:Bool() Override
		If value.HasSideEffects Return True
		For Local arg:=Eachin args
			If arg.HasSideEffects Return True
		Next
		Return False
	End
	
	Method RemoveSideEffects:Value( block:Block ) Override
		If Not HasSideEffects Return Self
		Local value:=Self.value.RemoveSideEffects( block )
		Local args:=Self.args.Slice( 0 )
		For Local i:=0 Until args.Length
			args[i]=args[i].RemoveSideEffects( block )
		Next
		Return New ArrayIndexValue( atype,value,args )
	End

End

Class StringIndexValue Extends Value

	Field value:Value
	Field index:Value
	
	Method New( value:Value,index:Value )
		Self.type=Type.IntType
		Self.value=value
		Self.index=index
	End
	
	Method ToString:String() Override
		Return value.ToString()+"["+index.ToString()+"]"
	End
	
	Property HasSideEffects:Bool() Override
		Return value.HasSideEffects Or index.HasSideEffects
	End
	
	Method RemoveSideEffects:Value( block:Block ) Override
		If Not HasSideEffects Return Self
		Local value:=Self.value.RemoveSideEffects( block )
		Local index:=Self.index.RemoveSideEffects( block )
		Return New StringIndexValue( value,index )
	End
	
End

Class PointerIndexValue Extends Value

	Field value:Value
	Field index:Value
	
	Method New( elemType:Type,value:Value,index:Value )
		Self.type=elemType
		Self.value=value
		Self.index=index
		
		flags|=VALUE_LVALUE|VALUE_ASSIGNABLE
	End
	
	Method ToString:String() Override
		Return value.ToString()+"["+index.ToString()+"]"
	End
	
	Property HasSideEffects:Bool() Override
		Return value.HasSideEffects Or index.HasSideEffects
	End
	
	Method RemoveSideEffects:Value( block:Block ) Override
		If Not HasSideEffects Return Self
		Local value:=Self.value.RemoveSideEffects( block )
		Local index:=Self.index.RemoveSideEffects( block )
		Return New StringIndexValue( value,index )
	End

End

Class UnaryopValue Extends Value

	Field op:String
	Field value:Value
	
	Method New( type:Type,op:String,value:Value )
		Self.type=type
		Self.op=op
		Self.value=value
	End
	
	Method ToString:String() Override
		Return op+value.ToString()
	End
	
End

Class BinaryopValue Extends Value

	Field op:String
	Field lhs:Value
	Field rhs:Value
	
	Method New( type:Type,op:String,lhs:Value,rhs:Value )
		Self.type=type
		Self.op=op
		Self.lhs=lhs
		Self.rhs=rhs
	End
	
	Method ToString:String() Override
		Return "("+lhs.ToString()+op+rhs.ToString()+")"
	End
	
End

Class IfThenElseValue Extends Value

	Field value:Value
	Field thenValue:Value
	Field elseValue:Value
	
	Method New( type:Type,value:Value,thenValue:Value,elseValue:Value )
		Self.type=type
		Self.value=value
		Self.thenValue=thenValue
		Self.elseValue=elseValue
	End
	
	Property HasSideEffects:Bool() Override
		Return thenValue.HasSideEffects Or elseValue.HasSideEffects
	End

End

Class PointerValue Extends Value

	Field value:Value

	Method New( value:Value )
		type=New PointerType( value.type )
		Self.value=value
	End
	
	Method ToString:String() Override
		Return value.ToString()+" Ptr"
	End

End

Class TypeofValue Extends Value

	Field value:Value
	
	Method New( value:Value )
		Self.type=Type.TypeInfoClass
		Self.value=value
	End
	
	Method ToString:String() Override
		Return "Typeof("+value.ToString()+")"
	End
	
End

Class TypeofTypeValue Extends Value

	Field ttype:Type
	
	Method New( ttype:Type )
		Self.type=Type.TypeInfoClass
		Self.ttype=ttype
	End

	Method ToString:String() Override
		Return "Typeof<"+ttype.ToString()+">"
	End
		
End

