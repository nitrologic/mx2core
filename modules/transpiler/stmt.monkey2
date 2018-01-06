
Namespace mx2

Class Stmt
	Field pnode:PNode
	
	Method New()
	End
	
	Method New( pnode:PNode )
		Self.pnode=pnode
	End
End

Class PrintStmt Extends Stmt
	Field value:Value
	
	Method New( pnode:PNode,value:Value )
		Super.New( pnode )
		Self.value=value
	End
	
End

Class ReturnStmt Extends Stmt

	Field value:Value
	
	Method New( pnode:PNode,value:Value )
		Super.New( pnode )
		Self.value=value
	End
End

Class VarDeclStmt Extends Stmt

	Field varValue:VarValue
	
	Method New( pnode:PNode,varValue:VarValue )
		Super.New( pnode )
		Self.varValue=varValue
	End

End

Class AssignStmt Extends Stmt

	Field op:String
	Field lhs:Value
	Field rhs:Value
	
	Method New( pnode:PNode,op:String,lhs:Value,rhs:Value )
		Super.New( pnode )
		Self.op=op
		Self.lhs=lhs
		Self.rhs=rhs
	End
End

Class EvalStmt Extends Stmt

	Field value:Value
	
	Method New( pnode:PNode,value:Value )
		Super.New( pnode )
		Self.value=value
	End
End

Class IfStmt Extends Stmt
	Field cond:Value
	Field block:Block
	Field succ:IfStmt
	
	Method New( pnode:PNode,cond:Value,block:Block )
		Super.New( pnode )
		Self.cond=cond
		Self.block=block
	End
	
End

Class WhileStmt Extends Stmt
	Field cond:Value
	Field block:Block
	
	Method New( pnode:PNode,cond:Value,block:Block )
		Super.New( pnode )
		Self.cond=cond
		Self.block=block
	End
	
End

Class RepeatStmt Extends Stmt
	Field cond:Value
	Field block:Block
	
	Method New( pnode:PNode,cond:Value,block:Block )
		Super.New( pnode )
		Self.cond=cond
		Self.block=block
	End
	
End

Class CaseStmt Extends Stmt
	Field values:Value[]
	Field block:Block
	
	Method New( values:Value[],block:Block )
		Self.values=values
		Self.block=block
	End
End

Class SelectStmt Extends Stmt
	Field value:Value
	Field cases:CaseStmt[]
	
	Method New( pnode:PNode,value:Value,cases:CaseStmt[] )
		Super.New( pnode )
		Self.value=value
		Self.cases=cases
	End

End

Class ForStmt Extends Stmt
	Field iblock:Block
	Field cond:Value
	Field incr:Stmt
	Field block:Block
	
	Method New( pnode:PNode,iblock:Block,cond:Value,incr:Stmt,block:Block )
		Super.New( pnode )
		Self.iblock=iblock
		Self.cond=cond
		Self.incr=incr
		Self.block=block
	End
	
End

Class CatchStmt
	Field vvar:VarValue
	Field block:Block
	
	Method New( vvar:VarValue,block:Block )
		Self.vvar=vvar
		Self.block=block
	End
	
End

Class TryStmt Extends Stmt
	Field block:Block
	Field catches:CatchStmt[]
	
	Method New( pnode:PNode,block:Block,catches:CatchStmt[] )
		Super.New( pnode )
		Self.block=block
		Self.catches=catches
	End
	
End

Class ThrowStmt Extends Stmt
	Field value:Value
	
	Method New( pnode:PNode,value:Value )
		Super.New( pnode )
		Self.value=value
	End
End

Class ContinueStmt Extends Stmt

	Method New( pnode:PNode )
		Super.New( pnode )
	End
End

Class ExitStmt Extends Stmt

	Method New( pnode:PNode )
		Super.New( pnode )
	End
End

'***** StmtVisitor *****

Class StmtVisitor

	Method Visit( block:Block )
		For Local stmt:=Eachin block.stmts
			Visit( stmt )
		Next
	End

	Method Visit( stmt:Stmt ) Virtual

		'Ok, this *could* be done double dispatch style...
		
		Local printStmt:=Cast<PrintStmt>( stmt )
		If printStmt Visit( printStmt ) ; Return
		
		Local returnStmt:=Cast<ReturnStmt>( stmt )
		If returnStmt Visit( returnStmt ) ; Return
		
		Local varDeclStmt:=Cast<VarDeclStmt>( stmt )
		If varDeclStmt Visit( varDeclStmt ) ; Return
		
		Local assignStmt:=Cast<AssignStmt>( stmt )
		If assignStmt Visit( assignStmt ) ; Return
		
		Local evalStmt:=Cast<EvalStmt>( stmt )
		If evalStmt Visit( evalStmt ) ; Return
		
		Local exitStmt:=Cast<ExitStmt>( stmt )
		If exitStmt Visit( exitStmt ) ; Return
		
		Local continueStmt:=Cast<ContinueStmt>( stmt )
		If continueStmt Visit( continueStmt ) ; Return
		
		Local throwStmt:=Cast<ThrowStmt>( stmt )
		If throwStmt Visit( throwStmt ) ; Return
		
		Local ifStmt:=Cast<IfStmt>( stmt )
		If ifStmt Visit( ifStmt ) ; Return
		
		Local whileStmt:=Cast<WhileStmt>( stmt )
		If whileStmt Visit( whileStmt ) ; Return
		
		Local repeatStmt:=Cast<RepeatStmt>( stmt )
		If repeatStmt Visit( repeatStmt ) ; Return
		
		Local selectStmt:=Cast<SelectStmt>( stmt )
		If selectStmt Visit( selectStmt ) ; Return
		
		Local forStmt:=Cast<ForStmt>( stmt )
		If forStmt Visit( forStmt ) ; Return
		
		Local tryStmt:=Cast<TryStmt>( stmt )
		If tryStmt Visit( tryStmt ) ; Return
		
		Print "????? StmtVisitor.VisitStmt() ?????"
	
	End
	
	'leaves
	'
	Method Visit( stmt:PrintStmt ) Virtual
	End
	
	Method Visit( stmt:ReturnStmt ) Virtual
	End
	
	Method Visit( stmt:VarDeclStmt ) Virtual
	End
	
	Method Visit( stmt:AssignStmt ) Virtual
	End
	
	Method Visit( stmt:EvalStmt ) Virtual
	End
	
	Method Visit( stmt:ThrowStmt ) Virtual
	End
	
	Method Visit( stmt:ExitStmt ) Virtual
	End
	
	Method Visit( stmt:ContinueStmt ) Virtual
	End

	'blocks
	'
	Method Visit( stmt:IfStmt ) Virtual
		While stmt
			Visit( stmt.block )
			stmt=stmt.succ
		Wend
	End
	
	Method Visit( stmt:WhileStmt ) Virtual
		Visit( stmt.block )
	End
	
	Method Visit( stmt:RepeatStmt ) Virtual
		Visit( stmt.block )
	End
	
	Method Visit( stmt:SelectStmt ) Virtual
		For Local cstmt:=Eachin stmt.cases
			Visit( cstmt.block )
		Next
	End
	
	Method Visit( stmt:ForStmt ) Virtual
		Visit( stmt.iblock )
		Visit( stmt.block )
	End
	
	Method Visit( stmt:TryStmt ) Virtual
		For Local cstmt:=Eachin stmt.catches
			Visit( cstmt.block )
		Next
	End
	
End


