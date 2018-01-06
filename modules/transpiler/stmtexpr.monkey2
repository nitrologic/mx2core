
Namespace mx2

Class StmtExpr Extends PNode
	
	Method New( srcpos:Int,endpos:Int )
		Super.New( srcpos,endpos )
	End
	
	Method Emit( buf:StringStack,spc:String ) Virtual
		buf.Push( spc+ToString() )
	End
	
	Method OnSemant:Stmt( block:Block ) Virtual
		Print "????? StmtExpr.OnSemant ?????"	' "+String.FromCString( typeName() )+"?????"
		Return Null
	End
	
	Method Semant:Stmt( block:Block )
	
		Try
		
			PNode.semanting.Push( Self )
			
			Local stmt:=OnSemant( block )
			
			PNode.semanting.Pop()
			
			Return stmt
			
		Catch ex:SemantEx
		
			PNode.semanting.Pop()
		
			Throw ex
		End
		
		Return Null

	End
	
End

Function EmitStmts( stmts:StmtExpr[],buf:StringStack,spc:String )
	spc+="  "
	For Local stmt:=Eachin stmts
		stmt.Emit( buf,spc )
	Next
End

Function StmtsToString:String( stmts:StmtExpr[] )
	Local buf:=New StringStack
	For Local stmt:=Eachin stmts
		buf.Push( stmt.ToString() )
	Next
	Return buf.Join( "~n" )
End

Class AssignStmtExpr Extends StmtExpr

	Field op:String
	Field lhs:Expr
	Field rhs:Expr

	Method New( op:String,lhs:Expr,rhs:Expr,srcpos:Int,endpos:Int )
		Super.New( srcpos,endpos )
		Self.op=op
		Self.lhs=lhs
		Self.rhs=rhs
	End
	
	Method ToString:String() Override
		Return lhs.ToString()+op+rhs.ToString()
	End
	
	'special case for SafeMemberExpr on lhs of assignment...
	'
	Method OnSemant:Stmt( smexpr:SafeMemberExpr,block:Block )
		
		Local value:=smexpr.expr.SemantRValue( block ).RemoveSideEffects( block )
		
		Local mexpr:=New MemberExpr( New ValueExpr( value,0,0 ),smexpr.ident,smexpr.srcpos,smexpr.endpos )
		
		Local asexpr:=New AssignStmtExpr( Self.op,mexpr,Self.rhs,srcpos,endpos )
		
		Local tblock:=New Block( block )
		
		tblock.Semant( New StmtExpr[]( asexpr ) )
		
		Return New IfStmt( self,value.UpCast( Type.BoolType ),tblock )
	End
	
	Method OnSemant:Stmt( block:Block ) Override
		
		Local smexpr:=Cast<SafeMemberExpr>( lhs )
		
		If smexpr Return OnSemant( smexpr,block )
		
		Local op:=Self.op
		Local lhs:=Self.lhs.Semant( block )
		Local rhs:Value=Null
		
		If op<>"="
			Local etype:=TCast<EnumType>( lhs.type )
			If etype
				lhs=lhs.RemoveSideEffects( block )
				Local t:=New BinaryopExpr( op.Slice( 0,-1 ),New ValueExpr( lhs,srcpos,endpos ),Self.rhs,srcpos,endpos )
				t.srcfile=srcfile
				rhs=t.Semant( block )
				op="="
			Endif
		Endif
		
		If Not rhs rhs=Self.rhs.Semant( block )
		
		If op<>"=" And lhs.IsLValue
		
			Local node:=lhs.FindValue( op )
			If node
				Local args:=New Value[1]
				args[0]=rhs
				Local value:=node.Invoke( args )
				Return New EvalStmt( Self,value )
			Endif
			
			node=lhs.FindValue( op.Slice( 0,-1 ) )
			If node
				Local args:=New Value[1]
				args[0]=rhs
				rhs=node.Invoke( args )
				op="="
			Endif
			
		Endif
		
		If Not lhs.IsAssignable Throw New SemantEx( "Value '"+lhs.ToString()+"' is not assignable" )
		
		Return lhs.Assign( Self,op,rhs,block )
	End
End

Class VarDeclStmtExpr Extends StmtExpr

	Field decl:VarDecl
	
	Method New( decl:VarDecl,srcpos:Int,endpos:Int )
		Super.New( srcpos,endpos )
		Self.decl=decl
	End
	
	Method ToString:String() Override
		Return decl.ToString()
	End
	
	Method OnSemant:Stmt( block:Block ) Override
	
		Local value:=New VarValue( decl,block )
		
		value.Semant()
		
		block.Insert( decl.ident,value )
		
		Return New VarDeclStmt( Self,value )
	End

End

Class EvalStmtExpr Extends StmtExpr

	Field expr:Expr
	
	Method New( expr:Expr,srcpos:Int,endpos:Int )
		Super.New( srcpos,endpos )
		Self.expr=expr
	End
	
	Method ToString:String() Override
		Return expr.ToString()
	End
	
	Method OnSemant:Stmt( block:Block ) Override
	
		Local value:=expr.SemantRValue( block )
		
		If Not value.HasSideEffects Throw New SemantEx( "Statement has no effect" )
		
		Return New EvalStmt( Self,value )
	End

End

Class InvokeNewStmtExpr Extends StmtExpr

	Field expr:Expr
	Field args:Expr[]
	
	Method New( expr:Expr,args:Expr[],srcpos:Int,endpos:Int )
		Super.New( srcpos,endpos )
		Self.expr=expr
		Self.args=args
	End
	
	Method OnSemant:Stmt( block:Block ) Override
	
		Local value:=expr.SemantRValue( block )
		If Not Cast<SelfValue>( value ) And Not Cast<SuperValue>( value ) Throw New SemantEx( "'New' cannot be directly invoked" )

		Local ctype:=TCast<ClassType>( value.type )
		
		Local func:=block.func

		Try
		
			If block<>func.block Or block.stmts.Length Or func.fdecl.ident<>"new" Or func.invokeNew
				 Throw New SemantEx( "Call to 'Self.New' or 'Super.New' must be the first statement of a constructor" )
			Endif
	
			Local args:=SemantArgs( Self.args,block )
			
			Local ctor:=ctype.FindNode( "new" )
			If Not ctor Throw New SemantEx( "Class '"+ctype.ToString()+"' has no constructors" )
			
			Local invoke:=Cast<InvokeValue>( ctor.ToValue( Null ).Invoke( args ) )
			If Not invoke Throw New SemantEx( "Can't invoke '"+ctype.ToString()+"' constuctor with arguments '"+Join( args )+"'" )
			
			Local ivalue:=New InvokeNewValue( ctype,invoke.args )
			func.invokeNew=ivalue
		
		Catch ex:SemantEx
		
			Local noargs:Value[]
			If Not func.invokeNew func.invokeNew=New InvokeNewValue( ctype,noargs ) 
			
			Throw ex
		End
		
		Return Null
	End

End

Class PrintStmtExpr Extends StmtExpr

	Field expr:Expr

	Method New( expr:Expr,srcpos:Int,endpos:Int )
		Super.New( srcpos,endpos )
		Self.expr=expr
	End
	
	Method ToString:String() Override
		Return "Print "+expr.ToString()
	End
	
	Method OnSemant:Stmt( block:Block ) Override
	
		Local value:=expr.SemantRValue( block,Type.StringType )
		
		Return New PrintStmt( Self,value )
	End

End

Class ReturnStmtExpr Extends StmtExpr

	Field expr:Expr

	Method New( expr:Expr,srcpos:Int,endpos:Int )
		Super.New( srcpos,endpos )
		Self.expr=expr
	End
	
	Method ToString:String() Override
		Return "Return "+expr.ToString()
	End
	
	Method OnSemant:Stmt( block:Block ) Override
	
		Try
	
			Local value:Value
		
			Local rtype:=block.func.ftype.retType
	
			If rtype=Type.VoidType
				If expr Throw New SemantEx( "Return statement cannot return a value" )
			Else
				If Not expr Throw New SemantEx( "Return statement must return a value" )
				value=expr.SemantRValue( block,rtype )
			Endif
			
			block.Emit( New ReturnStmt( Self,value ) )
		
		Catch ex:SemantEx
		End

		block.reachable=False
		
		Return Null
	End

End

Class ContinueStmtExpr Extends StmtExpr

	Method New( srcpos:Int,endpos:Int )
		Super.New( srcpos,endpos )
	End
	
	Method ToString:String() Override
		Return "Continue"
	End
	
	Method OnSemant:Stmt( block:Block ) Override
	
		If Not block.loop Throw New SemantEx( "'Continue' must appear inside a loop" )
		
		If Not block.reachable Return Null
		
		block.Emit( New ContinueStmt( Self ) )
		
		block.reachable=False
		
		Return Null
	End

End

Class ExitStmtExpr Extends StmtExpr

	Method New( srcpos:Int,endpos:Int )
		Super.New( srcpos,endpos )
	End

	Method ToString:String() Override
		Return "Exit"
	End
	
	Method OnSemant:Stmt( block:Block ) Override
	
		If Not block.loop Throw New SemantEx( "'Exit' must appear inside a loop" )
		
		If Not block.reachable Return Null
		
		block.Emit( New ExitStmt( Self ) )
		
		block.reachable=False
		
		Return Null
	End
End


Class IfStmtExpr Extends StmtExpr

	Field cond:Expr
	Field stmts:StmtExpr[]
	Field succ:IfStmtExpr
	
	Method New( cond:Expr,stmts:StmtExpr[],succ:IfStmtExpr,srcpos:Int,endpos:Int )
		Super.New( srcpos,endpos )
		Self.cond=cond
		Self.stmts=stmts
		Self.succ=succ
	End
	
	Method ToString:String() Override
		Return "if"
	End
	
	Method Emit( buf:StringStack,spc:String ) Override
		buf.Push( spc+"If "+cond.ToString() )
		EmitStmts( stmts,buf,spc )
		Local stmt:=succ
		While stmt
			If stmt.cond 
				buf.Push( spc+"else If "+stmt.cond.ToString() )
			Else
				buf.Push( spc+"else" )
			Endif
			EmitStmts( stmt.stmts,buf,spc )
			stmt=stmt.succ
		Wend
		buf.Push( spc+"end" )
	End
	
	Method OnSemant:Stmt( block:Block ) Override
	
		Local expr:=Self
		Local head:IfStmt,prev:IfStmt
		
		Local reachable:=False
		
		While expr
		
			Local cond:Value
			If expr.cond cond=expr.cond.TrySemantRValue( block,Type.BoolType )
			
			Local tblock:=New Block( block )
			tblock.Semant( expr.stmts )
			
			If expr.succ Or Not cond
				If tblock.reachable reachable=True
			Else
				reachable=True
			Endif
			
			Local curr:=New IfStmt( expr,cond,tblock )
			If prev prev.succ=curr Else head=curr
			prev=curr
			
			expr=expr.succ
			
		Wend
		
		If Not block.reachable Return Null
		
		block.Emit( head )
		
		block.reachable=reachable
		
		Return Null
	End
	
End

Class WhileStmtExpr Extends StmtExpr

	Field expr:Expr
	Field stmts:StmtExpr[]
	
	Method New( expr:Expr,stmts:StmtExpr[],srcpos:Int,endpos:Int )
		Super.New( srcpos,endpos )
		Self.expr=expr
		Self.stmts=stmts
	End
	
	Method ToString:String() Override
		Return "while"
	End
	
	Method Emit( buf:StringStack,spc:String ) Override
		buf.Push( spc+"while "+expr.ToString() )
		EmitStmts( stmts,buf,spc )
		buf.Push( spc+"wend" )
	End
	
	Method OnSemant:Stmt( block:Block ) Override
	
		Local cond:Value
		If expr cond=expr.TrySemantRValue( block,Type.BoolType )
		
		Local iblock:=New Block( block )
		iblock.loop=True
		
		iblock.Semant( stmts )
		
		return New WhileStmt( Self,cond,iblock )
	End
End

Class RepeatStmtExpr Extends StmtExpr

	Field stmts:StmtExpr[]
	Field expr:Expr
	
	Method New( stmts:StmtExpr[],expr:Expr,srcpos:Int,endpos:Int )
		Super.New( srcpos,endpos )
		Self.stmts=stmts
		Self.expr=expr
	End
	
	Method ToString:String() Override
		Return "Repeat"
	End
	
	Method Emit( buf:StringStack,spc:String ) Override
		buf.Push( spc+"repeat" )
		EmitStmts( stmts,buf,spc )
		If expr
			buf.Push( spc+"until "+expr.ToString() )
		Else
			buf.Push( spc+"forever" )
		Endif
	End
	
	Method OnSemant:Stmt( block:Block ) Override

		Local cond:Value
		If expr cond=expr.TrySemantRValue( block,Type.BoolType )
		
		Local iblock:=New Block( block )
		iblock.loop=True
		
		iblock.Semant( stmts )
		
		Return New RepeatStmt( Self,cond,iblock )
	End

End

Class CaseExpr

	Field exprs:Expr[]
	Field stmts:StmtExpr[]
	
	Method New( exprs:Expr[],stmts:StmtExpr[] )
		Self.exprs=exprs
		Self.stmts=stmts
	End
	
End

Class SelectStmtExpr Extends StmtExpr

	Field expr:Expr
	Field cases:CaseExpr[]
	
	Method New( expr:Expr,cases:CaseExpr[],srcpos:Int,endpos:Int )
		Super.New( srcpos,endpos )
		
		Self.expr=expr
		Self.cases=cases
	End
	
	Method ToString:String() Override
		Return "select"
	End
	
	Method Emit( buf:StringStack,spc:String ) Override
	
		buf.Push( spc+"select "+expr.ToString() )
		For Local c:=Eachin cases
			buf.Push( "case "+Join( c.exprs ) )
			EmitStmts( c.stmts,buf,spc )
		Next
		buf.Push( spc+"end" )
	End
	
	Method OnSemant:Stmt( block:Block ) override
	
		Local value:=expr.SemantRValue( block )
		
		value=value.RemoveSideEffects( block )
		
		Local cases:=New Stack<CaseStmt>
		
		For Local cexpr:=Eachin Self.cases
		
			Local values:=New Value[cexpr.exprs.Length]
			
			For Local i:=0 Until values.Length
				values[i]=value.Compare( "=",cexpr.exprs[i].SemantRValue( block,value.type ) )
			Next
			
			Local iblock:=New Block( block )

			iblock.Semant( cexpr.stmts )
			
			cases.Push( New CaseStmt( values,iblock ) )
		
		Next
		
		Return New SelectStmt( Self,value,cases.ToArray() )
	End
	
End

Class ForStmtExpr Extends StmtExpr

	Field varIdent:String
	Field varType:Expr
	Field varExpr:Expr
	Field kind:String
	Field init:Expr
	Field cond:Expr
	Field incr:Expr
	
	Field stmts:StmtExpr[]
	
	Method New( varIdent:String,varType:Expr,varExpr:Expr,kind:String,init:Expr,cond:Expr,incr:Expr,stmts:StmtExpr[],srcpos:Int,endpos:Int )
		Super.New( srcpos,endpos )
		
		Self.varIdent=varIdent
		Self.varType=varType
		Self.varExpr=varExpr
		Self.kind=kind
		Self.init=init
		Self.cond=cond
		Self.incr=incr
		
		Self.stmts=stmts
	End
	
	Method ToString:String() Override
		Return "for"
	End
	
	Method Emit( buf:StringStack,spc:String ) Override
		Local str:="for "
		If varIdent
			str+=varIdent
			If varType str+=":"+varType.ToString() Else str+=":="
		Else
			str+=varExpr.ToString()+"="
		Endif
		
		If kind="eachin"
			str+=" eachin "+init.ToString()
		Else
			str+=init.ToString()
			If kind="to" str+=" to " Else str+=" until "
			str+=cond.ToString()
			If incr str+=" step "+incr.ToString()
		Endif
		buf.Push( spc+str )
		EmitStmts( stmts,buf,spc )
		buf.Push( spc+"next" )
	End
	
	Method SemantEachin:Stmt( block:Block )

		Local iblock:=New Block( block )
		block=New Block( iblock )
		block.loop=True
		
		Local cond:Value
		Local incr:Stmt

		Local curr:Value
		Local init:=Self.init.SemantRValue( iblock )
		
		Local atype:=TCast<ArrayType>( init.type )
		If atype And atype.rank<>1 Throw New SemantEx( "'Eachin' can only be used with 1 dimensional arrays" )
		
		If atype Or init.type=Type.StringType
		
			init=init.RemoveSideEffects( iblock )

			Local iter:=iblock.AllocLocal( LiteralValue.IntValue( 0 ) )
			
			'iter<container.Length
			Local len:=init.FindValue( "Length" )
			len=len.ToRValue().RemoveSideEffects( iblock )
			cond=New BinaryopValue( Type.BoolType,"<",iter,len )
			
			'iter+=1			
			incr=iter.Assign( Null,"+=",LiteralValue.IntValue( 1 ),iblock )
			
			If atype
				Local indices:=New Value[1]
				indices[0]=Cast<Value>(iter)
				curr=New ArrayIndexValue( atype,init,indices )
			Else
				curr=New StringIndexValue( init,iter )
			Endif
			
		Else

			'iter=container.All()
			Local iter:=init.FindValue( "All" )
			If Not iter
				iter=init.FindValue( "GetIterator" )
				If Not iter
					iter=init.RemoveSideEffects( iblock )
					'Throw New SemantEx( "Container of type '"+init.type.ToString()+"' has no 'GetIterator' method" )
				Endif
			Else
				iter=iter.Invoke( Null ).RemoveSideEffects( iblock )
			Endif
			
			'iter.AtEnd
			Local atEnd:=iter.FindValue( "AtEnd" )
			If Not atEnd 'Throw New SemantEx( "Iterator has no 'AtEnd' property" )
				Local isValid:=iter.FindValue( "Valid" )
				If Not isValid Throw New SemantEx( "Iterator has no 'AtEnd' property" )
				isValid=isValid.UpCast( Type.BoolType )
				cond=isValid
			Else
				atEnd=atEnd.UpCast( Type.BoolType )
				atEnd=New UnaryopValue( Type.BoolType,"not",atEnd )
				cond=atEnd
			Endif

			'iter.Current			
			curr=iter.FindValue( "Current" )
			If Not curr Throw New SemantEx( "Iterator has no 'Current' property" )
			curr=curr.ToRValue()
			
			'iter.Bump()
			Local bump:=iter.FindValue( "Bump" )
			If Not bump Throw New SemantEx( "Iterator has no 'Bump' method" )
			bump=bump.Invoke( Null )
			incr=New EvalStmt( Null,bump )
			
		Endif
		
		If varIdent
			If varType curr=curr.UpCast( varType.SemantType( block ) )
			block.AllocLocal( varIdent,curr )
		Else
			Local iter:=varExpr.Semant( block ).RemoveSideEffects( block )
			If Not iter.IsAssignable Throw New SemantEx( "For loop index '"+iter.ToString()+"' is not assignable" )
			block.Emit( iter.Assign( Null,"=",curr,block ) )
		Endif
		
		block.Semant( stmts )
		
		Return New ForStmt( Self,iblock,cond,incr,block )
	End
	
	Method OnSemant:Stmt( block:Block ) Override

		If kind="eachin" Return SemantEachin( block )

		Local iblock:=New Block( block )
		block=New Block( iblock )
		block.loop=True

		Local iter:Value
		Local init:=Self.init.SemantRValue( iblock )
		
		If varIdent
			If varType init=init.UpCast( varType.SemantType( iblock ) )
			iter=iblock.AllocLocal( varIdent,init )
		Else
			iter=varExpr.Semant( iblock ).RemoveSideEffects( iblock )
			If Not iter.IsAssignable Throw New SemantEx( "For loop index '"+iter.ToString()+"' is not assignable" )
			iblock.Emit( iter.Assign( Null,"=",init,iblock ) )
		Endif
		
		Local term:=Self.cond.SemantRValue( iblock )
		Local termExpr:=New ValueExpr( term,srcpos,endpos )
		Local iterExpr:=New ValueExpr( iter,srcpos,endpos )
		Local cond:Value
		Local incr:Value
		
		Local opx:="<",opy:=">"
		If kind="to" opx="<=" ; opy=">="
			
		If Self.incr
		
			'step value? Yuck...use 'C' for loop!
			'
			incr=Self.incr.SemantRValue( iblock ).RemoveSideEffects( iblock )
'			incr=iblock.AllocLocal( Self.incr.SemantRValue( iblock ) )

			Local incrExpr:=New ValueExpr( incr,srcpos,endpos )
			Local zero:=New LiteralExpr( "0",TOKE_INTLIT,Null,srcpos,endpos )
			
			Local cmp1:=New BinaryopExpr( ">",incrExpr,zero,srcpos,endpos ).SemantRValue( iblock )
			Local cmp2:=New BinaryopExpr( opx,iterExpr,termExpr,srcpos,endpos ).SemantRValue( iblock )
			
			Local cmp3:=New BinaryopExpr( "<",incrExpr,zero,srcpos,endpos ).SemantRValue( iblock )
			Local cmp4:=New BinaryopExpr( opy,iterExpr,termExpr,srcpos,endpos ).SemantRValue( iblock )
			
			Local cmp5:=New BinaryopValue( Type.BoolType,"and",cmp1,cmp2 )
			Local cmp6:=New BinaryopValue( Type.BoolType,"and",cmp3,cmp4 )
			
			cond=New BinaryopValue( Type.BoolType,"or",cmp5,cmp6 )
			
		Else
		
			incr=New LiteralValue( Type.IntType,1 )
			
			cond=New BinaryopExpr( opx,iterExpr,termExpr,srcpos,endpos ).SemantRValue( iblock )
			
		Endif
		
		Local incrStmt:=iter.Assign( Self,"+=",incr,iblock )
		
		block.Semant( stmts )
		
		Return New ForStmt( Self,iblock,cond,incrStmt,block )

	End
	
End

Class CatchExpr

	Field varIdent:String
	Field varType:Expr
	Field stmts:StmtExpr[]

	Method New( varIdent:String,varType:Expr,stmts:StmtExpr[] )
		Self.varIdent=varIdent
		Self.varType=varType
		Self.stmts=stmts
	End

End

Class TryStmtExpr Extends StmtExpr

	Field stmts:StmtExpr[]
	Field catches:CatchExpr[]
	
	Method New( stmts:StmtExpr[],catches:CatchExpr[],srcpos:Int,endpos:Int )
		Super.New( srcpos,endpos )
		Self.stmts=stmts
		Self.catches=catches
	End
	
	Method OnSemant:Stmt( block:Block ) Override
	
		Local iblock:=New Block( block )
		
		iblock.Semant( stmts )
		
		Local catches:=New Stack<CatchStmt>
		
		For Local cexpr:=Eachin Self.catches
		
			Local iblock:=New Block( block )
			iblock.inex=True
			
			Local vvar:VarValue

			If cexpr.varType
				Local type:=cexpr.varType.SemantType( iblock )
				vvar=New VarValue( "local",cexpr.varIdent,New LiteralValue( type,"" ),iblock )
				iblock.Insert( cexpr.varIdent,vvar )
			Endif
			
			iblock.Semant( cexpr.stmts )
			
			catches.Push( New CatchStmt( vvar,iblock ) )
		Next
		
		Return New TryStmt( Self,iblock,catches.ToArray() )
	End
End

Class ThrowStmtExpr Extends StmtExpr

	Field expr:Expr

	Method New( expr:Expr,srcpos:Int,endpos:Int )
		Super.New( srcpos,endpos )
		Self.expr=expr
	End
	
	Method OnSemant:Stmt( block:Block ) Override
	
		If expr
		
			Local value:=expr.SemantRValue( block )
			Local ctype:=TCast<ClassType>( value.type )
			
			If Not ctype Or Not ctype.ExtendsType( Type.ThrowableClass )
				Throw New SemantEx( "Thrown value type must extend 'Throwable'" )
			Endif
			
			block.Emit( New ThrowStmt( Self,value ) )
			block.reachable=False
			
		Else If block.inex

			block.Emit( New ThrowStmt( Self,Null ) )
			block.reachable=False
		
		Else
		
			Throw New SemantEx( "Exceptions can only be rethrown inside 'Catch' blocks" )
			
		Endif
		
		Return Null
	End

End

