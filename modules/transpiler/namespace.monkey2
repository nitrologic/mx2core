
Namespace mx2

Class NamespaceType Extends Type

	Field ident:String
	Field scope:NamespaceScope
	
	Method New( ident:String,outer:NamespaceScope )
		Self.ident=ident
		Self.scope=New NamespaceScope( Self,outer )
	End
	
	Method ToString:String() Override
		Return ident
	End
	
	Property Name:String() Override
		Return scope.Name
	End
	
	Property TypeId:String() Override
		Return scope.TypeId
	End
	
	'***** Type overrides *****

	Method FindNode:SNode( ident:String ) Override
	
		Local node:=scope.GetNode( ident )
		If node Return node
		
		Return Null
	End
	
	Method FindType:Type( ident:String ) Override
	
		Local type:=scope.GetType( ident )
		If type Return type
		
		Return Null
	End
End

Class NamespaceScope Extends Scope

	Field ntype:NamespaceType
	Field classexts:=New Stack<ClassType>
	
	Method New( ntype:NamespaceType,outer:NamespaceScope )
		Super.New( outer )
		
		Self.ntype=ntype
	End
	
	Property Name:String() Override
		If Not ntype Return ""
		If outer
			Local name:=outer.Name
			If name Return name+"."+ntype.ident
		Endif
		Return ntype.ident
	End
	
	Property TypeId:String() Override
		If Not ntype Return ""
		If outer
			Local id:=outer.TypeId
			If id Return id+"_"+ntype.ident
		Endif
		Return ntype.ident
	End
		
	Method ToString:String() Override
	
		If Not ntype Return ""
	
		If outer
			Local str:=outer.ToString()
			If str Return str+"."+ntype.ident
		Endif
		
		Return ntype.ident
	End
	
	Method FindRoot:NamespaceScope()
	
		Local nmspace:=Cast<NamespaceScope>( outer )
		If nmspace And nmspace.ntype Return nmspace.FindRoot()
		
		Return Self
	End
	
	Method GetClassExtensions:Stack<ClassType>( ctype:ClassType )
	
		Local exts:Stack<ClassType>
		
		For Local ext:=Eachin classexts
		
			If ext.IsGeneric
				Local etype:=ctype
				While etype
					If etype.instanceOf And etype.instanceOf.Equals( ext.superType.instanceOf )
						ext=TCast<ClassType>( ext.GenInstance( etype.types ) )
						Exit
					Endif
					etype=etype.superType
				Wend
				If Not etype Continue
			Else
				If Not ctype.ExtendsType( ext.superType ) Continue
			Endif
			
			If Not exts exts=New Stack<ClassType>
			exts.Push( ext )
		Next
		
		Return exts
	End
	
	Method GetExtensions( finder:NodeFinder,ctype:ClassType )
	
		Local exts:=GetClassExtensions( ctype )
		If Not exts Return

		For Local ext:=Eachin exts
			finder.Add( ext.scope.GetNode( finder.ident ) )
		Next

	End
	
	Method FindExtensions( finder:NodeFinder,ctype:ClassType )
	
		Local nmspace:=Self
		
		While nmspace
		
			nmspace.GetExtensions( finder,ctype )
			
			nmspace=Cast<NamespaceScope>( nmspace.outer )
		Wend
		
	End

End
