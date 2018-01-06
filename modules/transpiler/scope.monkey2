
Namespace mx2

Class Scope

	'nesting
	Field outer:Scope
	Field inner:=New Stack<Scope>
	
	'symbol table
	Field nodes:=New StringMap<SNode>
	
	'what translator needs to emit
	Field transMembers:=New Stack<SNode>
	
	'easier than passing classes around!
	Global semanting:=New Stack<Scope>
	
	Method New( outer:Scope )
		Self.outer=outer
		If outer outer.inner.Push( Self )
	End
	
	Property Name:String() Virtual
		If outer Return outer.Name
		Return ""
	End
	
	Property TypeId:String() Virtual
		If outer Return outer.Name
		Return ""
	End
	
	Method ToString:String() Virtual
		If outer Return outer.ToString()
		Return ""
	End
	
	Property IsInstanceOf:Bool() Virtual
	
		If outer Return outer.IsInstanceOf
		
		Return False
	End
	
	'Is generic scope? ie: does scope have access to any generic types?
	'
	Property IsGeneric:Bool() Virtual
	
		If outer Return outer.IsGeneric
		
		Return False
	End
	
	Method Insert:Bool( ident:String,node:SNode )
	
		Try
	
			Local func:=Cast<FuncValue>( node )
			If func
			
				Local flist:=Cast<FuncList>( nodes[ident] )
				If Cast<PropertyList>( flist ) flist=Null
				
				If Not flist
					If nodes.Contains( ident ) Throw New SemantEx( "Duplicate identifier '"+ident+"'",node.pnode )
					flist=New FuncList( ident,Self )
					nodes[ident]=flist
				Endif
				
				flist.PushFunc( func )
				Return True
	
			Endif
		
			If nodes.Contains( ident ) Throw New SemantEx( "Duplicate identifier '"+ident+"'",node.pnode )
			
			nodes[ident]=node
			Return True
		
		Catch ex:SemantEx
		
		End
		
		Return False
	End
	
	Method GetNode:SNode( ident:String )
	
		Local node:=nodes[ident]
		If node Return node.Semant()
		
		Return Null
	End
	
	Method GetType:Type( ident:String )
	
		Local node:=nodes[ident]
		If Not Cast<Type>( node ) Return Null
		
		node=node.Semant()
		If node Return node.ToType()
		
		Return Null
	End
	
	Method FindNode:SNode( ident:String ) Virtual
	
		Local node:=GetNode( ident )
		If node Return node
		
		If outer Return outer.FindNode( ident )
		
		Return Null
	End
	
	Method FindType:Type( ident:String ) Virtual
	
		Local type:=GetType( ident )
		If type Return type
		
		If outer Return outer.FindType( ident )
		
		Return Null
	End
	
	Method FindValue:Value( ident:String ) Virtual
	
		Local node:=FindNode( ident )
		If node Return node.ToValue( Null )
		
		Return Null
	End
	
	Method FindFile:FileScope() Virtual
		If outer Return outer.FindFile()
		
		SemantError( "Scope.FindFile()" )
		Return Null
	End
	
	Method FindClass:ClassType() Virtual
		If outer Return outer.FindClass()
		
		Return Null
	End
	
	Function Semanting:Scope()
		If semanting.Length Return semanting.Top
		Return Null
	End
End
