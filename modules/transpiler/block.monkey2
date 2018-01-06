
Namespace mx2

Class Block Extends Scope

	Field func:FuncValue

	Field stmts:=New Stack<Stmt>
	
	Field reachable:Bool=True
	
	Field loop:Bool
	Field inex:Bool
	
	Method New( func:FuncValue )
		Super.New( func.scope )
		
		Self.func=func
	End
	
	Method New( outer:Block )
		Super.New( outer )
		
		func=outer.func
		loop=outer.loop
		inex=outer.inex
	End
	
'	Property IsGeneric:Bool() Override

'		If func.IsGeneric Return True

'		Return Super.IsGeneric
'	End

	Method FindValue:Value( ident:String ) Override

		Local node:=FindNode( ident )
		If Not node Return Null
		
		Local vvar:=Cast<VarValue>( node )
		If vvar
		
			Select vvar.vdecl.kind
			Case "local","param","capture"
			
				Local vfunc:=Cast<Block>( vvar.scope ).func
				
				If vfunc<>func
				
					If func.fdecl.kind<>"lambda" Return Null
					
					'capture vvar...
					'
					'find all funcs (lambdas) up to vvar func
					'
					Local tfunc:=func,funcs:=New Stack<FuncValue>

					While tfunc<>vfunc
						funcs.Push( tfunc )
						tfunc=Cast<Block>( tfunc.block.outer ).func
					Wend
					
					While Not funcs.Empty
					
						Local tfunc:=funcs.Pop()
						
						'FXIME: this pollutes outer func scope with captured var name.
						'
						vvar=New VarValue( "capture",vvar.vdecl.ident,vvar,tfunc.block )
						tfunc.block.Insert( vvar.vdecl.ident,vvar )
						tfunc.captures.Push( vvar )
					
					Wend
					
					node=vvar
					
				Endif
			End
			
		Endif
		
		Return node.ToValue( func.selfValue )
	End
	
	Method Emit( stmt:Stmt )
	
		If reachable stmts.Push( stmt )
	End
	
	Method Semant( stmts:StmtExpr[] )
	
		Scope.semanting.Push( Self )
	
		For Local expr:=Eachin stmts
			Try

				Local stmt:=expr.Semant( Self )
				If stmt Emit( stmt )
				
			Catch ex:SemantEx
			End
		Next
		
		Scope.semanting.Pop()
	End
	
	Method AllocLocal:VarValue( init:Value )

		Local ident:=""+func.nextLocalId
		func.nextLocalId+=1

		Local varValue:=New VarValue( "local",ident,init,Self )
		
		stmts.Push( New VarDeclStmt( Null,varValue ) )

		Return varValue
	End

	Method AllocLocal:VarValue( ident:String,init:Value )

		Local varValue:=New VarValue( "local",ident,init,Self )
		
		stmts.Push( New VarDeclStmt( Null,varValue ) )

		Insert( ident,varValue )

		Return varValue
	End
	
End

Class FuncBlock Extends Block

	Method New( func:FuncValue )

		Super.New( func )
	End
	
	Property IsGeneric:Bool() Override
	
		If func.IsGeneric Return True
		
		Return Super.IsGeneric
	End
	
	Method FindType:Type( ident:String ) Override
	
		For Local i:=0 Until func.types.Length
			If ident=func.fdecl.genArgs[i] Return func.types[i]
		Next

		Return Super.FindType( ident )
	End

End
