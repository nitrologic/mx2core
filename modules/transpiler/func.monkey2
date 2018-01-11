
Namespace mx2

'***** FuncDecl *****

Class FuncDecl Extends Decl

	Field genArgs:String[]
	Field type:FuncTypeExpr
	Field whereExpr:Expr
	
	Field stmts:StmtExpr[]
	
	Method ToNode:SNode( scope:Scope ) Override
	
		Local types:=New Type[genArgs.Length]
		For Local i:=0 Until types.Length
			types[i]=New GenArgType( i,genArgs[i] )',Null,Null )
		Next
		
		Return New FuncValue( Self,scope,types,Null )
	End

	Method ToString:String() Override
		Local str:=Super.ToString()
		If genArgs str+="<"+",".Join( genArgs )+">"
		Return str+":"+type.ToString()
	End
	
End

'***** FuncValue *****

Class FuncValue Extends Value

	Field fdecl:FuncDecl
	Field scope:Scope
	Field types:Type[]
	Field instanceOf:FuncValue
	Field pdecls:VarDecl[]
	Field transFile:FileDecl
	Field cscope:ClassScope
	
	Field block:Block
	Field ftype:FuncType
	
	Field overrides:FuncValue
	
	Field params:VarValue[]
	
	Field selfValue:Value
	Field selfType:ClassType
	
	Field instances:Stack<FuncValue>
	
	Field captures:Stack<VarValue>
	
	Field nextLocalId:Int

	Field invokeNew:InvokeNewValue	'call to Super.New or Self.new
	
	Field simpleGetter:Bool
	
	Field used:Bool
	
	Method New( fdecl:FuncDecl,scope:Scope,types:Type[],instanceOf:FuncValue )
	
		Self.pnode=fdecl
		Self.fdecl=fdecl
		Self.scope=scope
		Self.types=types
		Self.instanceOf=instanceOf
		Self.pdecls=fdecl.type.params
		Self.transFile=scope.FindFile().fdecl
		Self.cscope=Cast<ClassScope>( scope )
		
		If IsLambda captures=New Stack<VarValue>
	End
	
	Property GenArgsName:String()
		If Not types Return ""
		Local tys:=""
		For Local ty:=Eachin types
			tys+=","+ty.Name
		Next
		Return "<"+tys.Slice( 1 )+">"
	End
	
	Property Name:String()
	
'		Local name:=scope.Name+"."+fdecl.ident,ps:=""

		Local tys:=""
		For Local ty:=Eachin types
			tys+=","+ty.Name
		Next
		If tys tys="<"+tys.Slice( 1 )+">"

		Local name:=fdecl.ident,ps:=""
		For Local p:=Eachin params
			ps+=","+p.Name
		Next
		
		Return name+tys
'		Return name+":"+ftype.retType.Name+"("+ps.Slice( 1 )+")"
	End
	
	Property ParamNames:String()
		Local ps:=""
		For Local p:=Eachin params
			ps+=","+p.Name
		Next
		Return ps.Slice( 1 )
	End
	
	Property IsGeneric:Bool()
		Return types And Not instanceOf
	End
	
	Property IsCtor:Bool()
		Return fdecl.ident="new"
	End
	
	Property IsMethod:Bool()
		Return fdecl.kind="method" And fdecl.ident<>"new"
	End
	
	Property IsVirtual:Bool()
		Return IsMethod And (cscope.ctype.IsVirtual Or fdecl.IsVirtual Or fdecl.IsOverride)
	End
	
	Property IsFunction:Bool()
		Return fdecl.kind="function"
	End
	
	Property IsStatic:Bool()
		Return fdecl.kind<>"method" Or types Or fdecl.IsExtension
	End
	
	Property IsMember:Bool()
		Return Not IsStatic
	End
	
	Property IsExtension:Bool()
		Return (fdecl.kind="method" And types) Or fdecl.IsExtension
	End
	
	Property IsLambda:Bool()
		Return fdecl.kind="lambda"
	End
	
	Method ToString:String() Override
	
		Local args:=Join( types )
		If args args="<"+args+">"
		
		Return fdecl.ident+args+":"+ftype.retType.ToString()+"("+Join( ftype.argTypes )+")"
	End
	
	Method OnSemant:SNode() Override
	
		'Create top level func block
		'
		block=New FuncBlock( Self )
		
		'Checks for generic funcs
		'
		If types
			If fdecl.IsAbstract Or fdecl.IsVirtual Or fdecl.IsOverride Throw New SemantEx( "Generic methods cannot be virtual" )
			If IsCtor Throw New SemantEx( "Constructors cannot be generic" )	'TODO
		Endif

		'Semant func type
		'
		type=fdecl.type.SemantType( block )
		ftype=TCast<FuncType>( type )
		
		'Semant selfType and selfValue
		'
		If IsCtor Or IsMethod
		
			selfType=cscope.ctype

			If selfType.cdecl.IsExtension And selfType.superType selfType=selfType.superType
			
			selfValue=New SelfValue( selfType,Self )
			
		Else If IsLambda
		
			selfValue=Cast<Block>( scope ).func.selfValue
			
			If selfValue
			
				Local selfVar:=New VarValue( "capture","self",selfValue,block )
				captures.Push( selfVar )
				
				selfValue=selfVar
				selfType=Cast<ClassType>( selfValue.type )
				
			Endif
		
		Endif
		
		'That's it for generic funcs
		'
		If block.IsGeneric
			used=True
			Return Self
		Endif
		
		'Sanity checks!
		'
		If IsCtor
		
			If cscope.ctype.cdecl.kind="class"
			
				Local isdefault:=True
				
				For Local p:=Eachin pdecls
					If p.init Continue
					isdefault=False
					Exit
				Next
				
				If isdefault cscope.ctype.defaultCtor=Self
		
			Else If cscope.ctype.cdecl.kind="struct"
			
				If ftype.argTypes.Length And ftype.argTypes[0].Equals( cscope.ctype )
					Local ok:=False
					For Local i:=1 Until ftype.argTypes.Length
						If pdecls[i].init Continue
						ok=True
						Exit
					Next
					If Not ok Throw New SemantEx( "Illegal struct constructor - 'copy constructors' are automatically generated and cannot be redefined" )
				Endif
						
			Endif
		
		Else If IsMethod
		
			Local ctype:=cscope.ctype
			
			If fdecl.IsOperator
				Local op:=fdecl.ident
				Select op
				Case "=","<>","<",">","<=",">="
					If ftype.retType<>Type.BoolType Throw New SemantEx( "Comparison operator '"+op+"' must return Bool" )
					If ftype.argTypes.Length<>1 Throw New SemantEx( "Comparison operator '"+op+"' must have 1 parameter" )
				Case "<=>"
					Local ptype:=TCast<PrimType>( ftype.retType )
					If Not ptype Or Not ptype.IsNumeric Throw New SemantEx( "Comparison operator '<=>' must return a numeric type" )
					If ftype.argTypes.Length<>1 Throw New SemantEx( "Comparison operator '"+op+"' must have 1 parameter" )
				End
			Endif
			
			If ctype.IsVirtual And (fdecl.IsVirtual Or fdecl.IsOverride)
				Throw New SemantEx( "Virtual class methods cannot be declared 'Virtual' or 'Override'" )
			Endif
			
			Local func2:=ctype.FindSuperFunc( fdecl.ident,ftype )
			
			If func2
			
				If Not ctype.IsVirtual And Not fdecl.IsOverride
					Throw New SemantEx( "Method '"+ToString()+"' overrides a superclass method but is not declared 'Override'" )
				Endif

				If func2.fdecl.IsFinal
					Throw New SemantEx( "Method '"+ToString()+"' overrides a final method" )
				Endif
				
				If Not ctype.IsVirtual And Not func2.fdecl.IsVirtual And Not func2.fdecl.IsOverride And Not func2.fdecl.IsAbstract
					 Throw New SemantEx( "Method '"+ToString()+"' overrides a non-virtual superclass method" )
				Endif
					
				If Not ftype.retType.ExtendsType( func2.ftype.retType )
					Throw New SemantEx( "Method '"+ToString()+"' overrides a method with incompatible return type" )
				Endif
				
				overrides=func2

			Else
			
				If fdecl.IsOverride
					Throw New SemantEx( "Method '"+ToString()+"' is declared 'Override' but does not override any method" )
				Endif
				
			Endif
		Endif
		
		'Check 'where' if present
		'		
		If fdecl.whereExpr
			Local t:=fdecl.whereExpr.SemantWhere( block )
'			Print "Semanted where for "+Name+" -> "+Int(t)
			If Not t Return Null
		Endif
		
		If IsLambda
		
			used=True
			semanted=Self
			SemantStmts()
			
		Else If fdecl.IsExtern 
		
			used=True
			
		Else If Not types
		
			Used()

		Endif
		
		Return Self
	End
	
	Method Used()
	
		If used Return
		used=True

		Builder.semantStmts.Push( Self )
	End
	
	Method ToValue:Value( instance:Value ) Override
	
		Local value:Value=Self
		
		If IsCtor
		
			If instance Throw New SemantEx( "'New' cannot be directly invoked" )
			
		Else If IsMethod
		
			If Not selfValue Throw New SemantEx( "Self has no type" )
			
			If Not instance Throw New SemantEx( "Method '"+ToString()+"' cannot be accessed without an instance" )
				
			If Not instance.type.ExtendsType( selfValue.type )
				Throw New SemantEx( "Method '"+ToString()+"' cannot be accessed from an instance of a different class" )
			Endif
			
			value=New MemberFuncValue( instance,Self )

		Endif
		
		Used()
		
		Return value
	End
	
	Method GenInstance:Value( types:Type[] ) Override
		If AnyTypeGeneric( types ) SemantError( "FuncValue.GenInstance()" )
		
		If Not IsGeneric Return Super.GenInstance( types )
		
		Local value:=TryGenInstance( types )
		
		If Not value Throw New SemantEx( "Failed to create generic instance of '"+ToString()+"' with types '<"+Join( types )+">'" )
		
		Return value
	End
	
	Method Invoke:Value( args:Value[] ) Override
	
		Return Super.Invoke( FixArgs( args ) )
	End
	
	Method CheckAccess( tscope:Scope ) Override

		CheckAccess( fdecl,scope,tscope )
	End
	
	Method SemantParams()

		params=New VarValue[pdecls.Length]

		For Local i:=0 Until pdecls.Length
		
			Local param:=New VarValue( pdecls[i],block )
			
			Try
			
				param.Semant()
				
				block.Insert( pdecls[i].ident,param )
				
				params[i]=param
				
			Catch ex:SemantEx
			End
		Next
		
	End
	
	Method SemantStmts()

		If block.IsGeneric SemantError( "FuncValue.SemantStmts(1)" )
	
		SemantParams()
		
		If Not fdecl.IsAbstract
			
			block.Semant( fdecl.stmts )
			
			If fdecl.ident="new" And Not invokeNew
			
				Local superType:=cscope.ctype.superType
				If superType
					If superType.cdecl.hasDefaultCtor
						Local ctor:=superType.FindNode( "new" )
						If ctor
							Local invoke:=Cast<InvokeValue>( ctor.ToValue( Null ).Invoke( null ) )
							invokeNew=New InvokeNewValue( superType,invoke.args )
						Endif
					Else
						New SemantEx( "Super class '"+superType.Name+"' has no default constructor!!!!",pnode )
					Endif
				Endif
			
			Endif
			
			If block.reachable And ftype.retType<>Type.VoidType Throw New SemantEx( "Missing return statement" )
			
			If IsMethod And Not ftype.argTypes And block.stmts.Length=1
				Local retstmt:=Cast<ReturnStmt>( block.stmts[0] )
				If retstmt
					Local mvar:=Cast<MemberVarValue>( retstmt.value )
					If mvar And mvar.instance=selfValue
						simpleGetter=True
'						Print "Return Self."+mvar.member.ToString()
					Endif
				Endif
			Endif

		Endif
		
		If fdecl.kind="function" Or IsExtension
		
			If fdecl.kind="function" And Not cscope And fdecl.ident="Main"
			
				If Not TCast<VoidType>( ftype.retType ) Or ftype.argTypes
					Throw New SemantEx( "Function 'Main' must be of type Void()" )
				Endif

				Local module:=transFile.module'.FindFile().fdecl.module
				
				If module.main Throw New SemantEx( "Duplicate declaration of 'Main'" )
				
				module.main=Self
			Endif
			
			If instanceOf Or IsExtension Or (cscope And cscope.ctype.instanceOf)
			
				Builder.semantingModule.genInstances.Push( Self )
				
			Endif

			transFile.functions.Push( Self )
			
		Else
			
			If IsCtor
				cscope.ctype.ctors.Push( Self )
			Elseif IsMethod
				cscope.ctype.methods.Push( Self )
			Endif
		
'			If IsCtor Or IsMethod
			
'				If fdecl.ident="new"
'					cscope.ctype.ctors.Push( Self )
'				Else
'					cscope.ctype.methods.Push( Self )
'				Endif
'			Endif
		
			scope.transMembers.Push( Self )

		Endif
	End
	
	Method TryGenInstance:FuncValue( types:Type[] )
		If AnyTypeGeneric( types ) SemantError( "FuncValue.GenInstance()" )
		
		If types.Length<>Self.types.Length Return Null
		
		If Not instances instances=New Stack<FuncValue>
	
		For Local inst:=Eachin instances
			If TypesEqual( inst.types,types ) Return Cast<FuncValue>( inst.Semant() )
		Next
		
		Local inst:=New FuncValue( fdecl,scope,types,Self )
		instances.Push( inst )
		
		Return Cast<FuncValue>( inst.Semant() )
	End
	
	Method FixArgs:Value[]( args:Value[] )
	
		Local args2:=New Value[pdecls.Length]
		
		For Local i:=0 Until args2.Length
			If i<args.Length And args[i]
				args2[i]=args[i]
			Else
				If pdecls[i] args2[i]=pdecls[i].init.Semant( scope )
			Endif
		Next
		
		Return args2
	End

End

'***** MemberFuncValue *****

Class MemberFuncValue Extends Value

	Field instance:Value
	Field member:FuncValue
	
	Method New( instance:Value,member:FuncValue )
		Self.type=member.type
		Self.instance=instance
		Self.member=member
	End
	
	Method ToString:String() Override
		Return instance.ToString()+"."+member.ToString()
	End
	
	Property HasSideEffects:Bool() Override
		Return instance.HasSideEffects
	End
	
	Method CheckAccess( tscope:Scope ) Override
		member.CheckAccess( tscope )
	End

End

'***** FuncListValue *****

Class FuncListValue Extends Value

	Field flistType:FuncListType
	Field instance:Value
	
	Method New( flistType:FuncListType,instance:Value )
		Self.type=flistType
		Self.flistType=flistType
		Self.instance=instance
	End
	
	Method ToString:String() Override
	
		Return flistType.ToString()

		Local args:=Join( flistType.types )
		If args args="<"+args+">"
		
'		Return flistType.flist.ident+args+"(...)"
		
		Local funcs:=Join( flistType.funcs.ToArray() )
		Return flistType.flist.ident+args+"["+funcs+"]"
	End
	
	Method GenInstance:Value( types:Type[] ) Override
	
		Local flistType:=Self.flistType.flist.GenFuncListType( types )
		
		If flistType.funcs.Empty Throw New SemantEx( "No overloads found for '"+Self.flistType.flist.ident+"' with type parameters '<"+Join( types )+">'" )
		
		Return New FuncListValue( flistType,instance )
	End
	
	Method Invoke:Value( args:Value[] ) Override
	
		Local func:=flistType.FindOverload( Null,Types( args ) )
		If Not func Throw New OverloadEx( Self,Types( args ) )
		
		Local value:=func.ToValue( instance )
		
		value=value.Invoke( func.FixArgs( args ) )
		
		Return value
	End
	
	Method ToRValue:Value() Override
	
		If flistType.funcs.Length>1 Throw New SemantEx( "Value '"+ToString()+"' is overloaded" )
		
		Local func:=flistType.funcs[0]
		If func.IsGeneric Throw New SemantEx( "Value '"+ToString()+"' is generic" )
		
		Return func.ToValue( instance )
	End
	
	Method UpCast:Value( type:Type ) Override
		DebugAssert( Not type.IsGeneric )
	
		If type.Equals( Type.VariantType ) Return New UpCastValue( Type.VariantType,ToRValue() )
	
		Local ftype:=TCast<FuncType>( type )
		If Not ftype Throw New UpCastEx( Self,type )
		
		Local match:=flistType.FindFunc( ftype )
		If Not match Throw New UpCastEx( Self,type )
		
		Return match.ToValue( instance )
	End
	
End

'***** FuncListType *****

Class FuncListType Extends Type

	Field flist:FuncList
	Field funcs:Stack<FuncValue>
	Field types:Type[]
	
	Method New( flist:FuncList )
	
		Self.flist=flist
		Self.funcs=flist.funcs
	End
	
	Method New( flist:FuncList,types:Type[] )

		Self.flist=flist
		Self.funcs=New Stack<FuncValue>
		Self.types=types
		
		For Local func:=Eachin flist.funcs
			Local func2:=func.TryGenInstance( types )
			If func2 funcs.Push( func2 )
		Next
	End
	
	Method ToString:String() Override
		Return flist.ident+(types ? "<"+Join( types )+">" Else "")
	End
	
	Property Name:String() Override
		Return flist.scope.Name+"."+ToString()
'		Return "{FuncListType}"
	End
	
	Property TypeId:String() Override
		SemantError( "FuncListType.TypeId()" )
		Return ""
	End
	
	Method ToValue:Value( instance:Value ) Override
		SemantError( "FuncListType.ToValue()" )
		Return Null
	End

	Method DistanceToType:Int( type:Type ) Override
		DebugAssert( Not type.IsGeneric )

		Local ftype:=TCast<FuncType>( type )
		If Not ftype Return -1
		
		Local match:=FindFunc( ftype )
		Return match ? 0 Else -1
	End
	
	Method FindFunc:FuncValue( ftype:FuncType )

		Local match:FuncValue
		
		For Local func:=Eachin funcs
			If Not func.ftype.Equals( ftype ) Continue
			If match Return Null
			match=func
		Next
		
		Return match
	End

	Method FindOverload:FuncValue( ret:Type,args:Type[] )
		Return overload.FindOverload( funcs,ret,args )
	End
	
End

'***** FuncList *****

Class FuncList Extends SNode

	Field ident:String
	Field scope:Scope
	Field funcs:=New Stack<FuncValue>
	Field instances:=New Stack<FuncListType>
	Field instance0:FuncListType
	
	Method New( ident:String,scope:Scope )
		Self.ident=ident
		Self.scope=scope
	End
	
	Method PushFunc( func:FuncValue )
	
		If instances.Length SemantError( "FuncList.PushFunc()" )
		
		funcs.Push( func )
	End
	
	Method FindFunc:FuncValue( ftype:FuncType )

		If AnyTypeGeneric( ftype.argTypes ) SemantError( "FuncList.FindFunc()" )
		
		For Local func:=Eachin funcs
			If func.block.IsGeneric Continue
			If Not TypesEqual( func.ftype.argTypes,ftype.argTypes ) Continue
			If ident<>"to" Return func
			If func.ftype.retType.Equals( ftype.retType ) Return func
			Return Null
		Next
		
		Return Null
	End
	
	Method OnSemant:SNode() Override
	
		If Not funcs.Length Return Self
	
		Local tfuncs:=funcs
		funcs=New Stack<FuncValue>
		
		For Local tfunc:=Eachin tfuncs
		
			Try

				Local func:=Cast<FuncValue>( tfunc.Semant() )
				If Not func Continue
				
				If ident<>"to" And Not func.block.IsGeneric
					Local func2:=FindFunc( func.ftype )'.argTypes )
					If func2 Throw New SemantEx( "Duplicate declaration '"+func.ToString()+"'",tfunc.pnode )
				Endif
				
				funcs.Push( func )

			Catch ex:SemantEx
			End
		Next
		
		Return Self
	End
	
	Method ToString:String() Override
	
		Return "{"+ident+"}"

		Return "{"+funcs[0].fdecl.ident+"}"
	End
	
	Method ToValue:Value( instance:Value ) Override
	
		If Not instance0 instance0=New FuncListType( Self )
		
		Return New FuncListValue( instance0,instance )
	End
	
	Method GenFuncListType:FuncListType( types:Type[] )
	
		For Local inst:=Eachin instances
			If TypesEqual( inst.types,types ) Return inst
		Next
		
		Local inst:=New FuncListType( Self,types )
		instances.Push( inst )
		
		inst.Semant()
		
		Return inst
	End
	
End
