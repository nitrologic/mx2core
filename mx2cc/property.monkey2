
Namespace mx2

Class PropertyDecl Extends Decl

	Field genArgs:String[]
	Field getFunc:FuncDecl
	Field setFunc:FuncDecl
	
	Method ToNode:SNode( scope:Scope ) Override
		
		Local types:=New Type[genArgs.Length]
		For Local i:=0 Until types.Length
			types[i]=New GenArgType( i,genArgs[i] )
		Next
	
		Return New PropertyList( Self,scope,types,Null )
	End

End

Class PropertyList Extends FuncList
	
	Field pdecl:PropertyDecl
	Field scope:Scope
	Field cscope:ClassScope
	
	Field getFunc:FuncValue
	Field setFunc:FuncValue
	
	Field type:Type
	
	Field types:Type[]
	Field instanceof:PropertyList
	Field instances:Stack<PropertyList>
	
	Method New( pdecl:PropertyDecl,scope:Scope,types:Type[],instanceof:PropertyList )
		Super.New( pdecl.ident,scope )
		Self.pnode=pdecl
		Self.pdecl=pdecl
		Self.scope=scope
		Self.cscope=Cast<ClassScope>( scope )
		Self.types=types
		Self.instanceof=instanceof
	End
	
	Method ToString:String() Override
	
		Return pdecl.ident
	End
	
	Method OnSemant:SNode() Override
	
		type=Null
		
		If pdecl.getFunc
			Try
'				getFunc=New FuncValue( pdecl.getFunc,scope,types,instanceof?.getFunc )
				getFunc=New FuncValue( pdecl.getFunc,scope,types,instanceof ? instanceof.getFunc Else Null )
				getFunc.Semant()
				type=getFunc.ftype.retType
				If type.Equals( Type.VoidType ) Throw New SemantEx( "Property '"+pdecl.ident+"' getter has void type" )
				PushFunc( getFunc )
			Catch ex:SemantEx
			End
		Endif

		If pdecl.setFunc
			Try
'				setFunc=New FuncValue( pdecl.setFunc,scope,types,instanceof?.setFunc )
				setFunc=New FuncValue( pdecl.setFunc,scope,types,instanceof ? instanceof.setFunc Else Null )
				setFunc.Semant()
				If type And Not type.Equals( setFunc.ftype.argTypes[0] ) Throw New SemantEx( "Property '"+pdecl.ident+"' Getter And Setter have different types" )
				If Not type type=setFunc.ftype.argTypes[0]
				PushFunc( setFunc )
			Catch ex:SemantEx
			End
		Endif
		
		If Not type SemantError( "PropertyList.OnSemant()" )
		
		Return Self
	End
	
	Method ToValue:Value( instance:Value ) Override
	
		If Not instance Throw New SemantEx( "Property '"+pdecl.ident+"' cannot be accessed without an instance" )
		
		Local selfType:=cscope.ctype
		If pdecl.IsExtension selfType=selfType.superType
		
		If Not instance.type.ExtendsType( selfType )
			Throw New SemantEx( "Property '"+pdecl.ident+"' cannot be accessed from an instance of a different class" )
		Endif
		
		Return New PropertyValue( Self,instance )
	End
	
	Method GenInstance:PropertyList( types:Type[] )
		
		If instanceof Return instanceof.GenInstance( types )
		
		If types.Length<>Self.types.Length Throw New SemantEx( "Wrong number of generic type parameters" )
		
		If Not instances instances=New Stack<PropertyList>
		
		For Local inst:=Eachin instances
			If TypesEqual( inst.types,types ) Return inst
		Next
		
		Local plist:=New PropertyList( pdecl,scope,types,Self )
		
		instances.Add( plist )
		
		plist.Semant()
		
		Return plist
	End
	
End

Class PropertyValue Extends Value

	Field plist:PropertyList
	Field instance:Value
	
	Method New( plist:PropertyList,instance:Value )
		Self.type=plist.type
		Self.plist=plist
		Self.instance=instance
		
		If plist.setFunc flags|=VALUE_ASSIGNABLE
	End
	
	Method ToString:String() Override

		Return "PropertyValue "+plist.pdecl.ident
	End

	Method ToRValue:Value() Override
	
		If Not plist.getFunc Throw New SemantEx( "Property '"+ToString()+"' is write only" )

		Return plist.getFunc.ToValue( instance ).Invoke( Null )
	End
	
	Method Assign:Stmt( pnode:PNode,op:String,rvalue:Value,block:Block ) Override
	
		Local inst:=instance
		
		If op<>"="
		
			If Not plist.getFunc Throw New SemantEx( "Property '"+ToString()+"' is write only" )
			
			inst=inst.RemoveSideEffects( block )
			
			Local value:=plist.getFunc.ToValue( inst ).Invoke( Null )
			
			Local op2:=op.Slice( 0,-1 )	'strip '='
			Local node:=value.FindValue( op2 )
			If node
				op=op2
				Local args:=New Value[1]
				args[0]=rvalue
				rvalue=node.Invoke( args )
			Else
			
				Local rtype:=BalanceAssignTypes( op,value.type,rvalue.type )
				rvalue=New BinaryopValue( value.type,op2,value,rvalue.UpCast( rtype ) )
				
			Endif
		
		Endif
		
		Local args:=New Value[1]
		args[0]=rvalue
		Local invoke:=plist.setFunc.ToValue( inst ).Invoke( args )
		
		Return New EvalStmt( pnode,invoke )
	End

	'should never be called?
	Property HasSideEffects:Bool() Override

		Return instance.HasSideEffects
	End
	
	Method RemoveSideEffects:Value( block:Block ) Override
	
		Local value:=instance.RemoveSideEffects( block )
		If value=instance Return Self
		
		Return New PropertyValue( plist,value )
	End
	
'	Method GenInstance:Value( types:Type[] ) Override
		
'		Local plist:=Self.plist.GenInstance( types )
		
'		Return New PropertyValue( plist,instance )
'	End
	
End
