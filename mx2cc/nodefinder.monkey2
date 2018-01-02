
Namespace mx2

Class NodeFinder

	Field ident:String
	Field node:SNode
	Field flist:FuncList
	
	Method New( ident:String )
		Self.ident=ident
	End
	
	Property Found:SNode()
		Return node
	End
	
	Method Add( node:SNode )
		
		If Not node Or node=Self.node Return
		
		If Not Self.node
			Self.node=node
			Return
		Endif
		
		Local flist:FuncList
		If Not Cast<PropertyList>( node ) flist=Cast<FuncList>( node )
			
		If Self.flist
			
			If Not flist Throw New SemantEx( "Duplicate identifier '"+ident+"'" )
				
			AddFuncs( flist,Self.flist )
				
		Else If flist
			
			Local src:FuncList
			If Not Cast<PropertyList>( Self.node ) src=Cast<FuncList>( Self.node )
			
			If Not src Throw New SemantEx( "Duplicate identifier '"+ident+"'" )
				
			Local dst:=New FuncList( ident,Null )
				
			AddFuncs( src,dst )
			AddFuncs( flist,dst )
				
			Self.flist=dst
			Self.node=dst
				
		Else
	
			Throw New SemantEx( "Duplicate identifier '"+ident+"'" )
		End
	End

	Method AddFuncs( src:FuncList,dst:FuncList )
	
		For Local func:=Eachin src.funcs
		
			Local func2:=dst.FindFunc( func.ftype )

			If func2
				If func2=func Continue	'bit of a hack for extensions...
				Throw New SemantEx( "Multiple overloads found for '"+func.ToString()+"'" )
			Endif
			
			dst.funcs.Push( func )
		Next
	End
	
End
