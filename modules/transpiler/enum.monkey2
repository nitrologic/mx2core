
Namespace mx2

Class EnumDecl Extends Decl

	Method ToNode:SNode( scope:Scope ) Override
	
		Return New EnumType( Self,scope )
	End
	
End

Class EnumType Extends Type

	Field edecl:EnumDecl
	Field transFile:FileDecl

	Field scope:EnumScope
	Field nextInit:Int
	
	Method New( edecl:EnumDecl,outer:Scope )
		Self.pnode=edecl
		Self.edecl=edecl
		Self.transFile=outer.FindFile().fdecl
		
		Self.scope=New EnumScope( Self,outer )
	End
	
	Method ToString:String() Override
		Return edecl.ident
	End
	
	Property Name:String() Override
		Return scope.Name
	End
	
	Property TypeId:String() Override
		Return scope.TypeId+"_"+edecl.ident
	End
	
	Method OnSemant:SNode() Override
	
		For Local decl:=Eachin edecl.members
		
			Local vdecl:=Cast<VarDecl>( decl )
			
			If edecl.IsExtern

				Local symbol:=vdecl.symbol
				If Not symbol symbol="@"+vdecl.ident			
				Local value:=New LiteralValue( Self,symbol )
				
				scope.Insert( decl.ident,value )
				
			Else
			
				If vdecl.init
					Try
						Local value:=Cast<LiteralValue>( vdecl.init.SemantRValue( scope ) )
						If Not value Throw New SemantEx( "Enum member '"+vdecl.ToString()+"' initalizer must be constant",vdecl )
						If value.type<>Type.IntType And value.type<>Self Throw New SemantEx( "Enum member '"+vdecl.ToString()+"' type error" )
						nextInit=Int( value.value )
					Catch ex:SemantEx
					End
				Endif
				
				Local value:=New LiteralValue( Self,String( nextInit ) )
				
				scope.Insert( decl.ident,value )
				
				nextInit+=1
				
			Endif
		Next
		
		If Not edecl.IsExtern And Not scope.IsGeneric
			
			If scope.IsInstanceOf Builder.semantingModule.genInstances.Add( Self )
	
			transFile.enums.Push( Self )
		
		Endif
		
		Return Self
	End
	
	Method FindNode:SNode( ident:String ) Override
	
		Local node:=scope.GetNode( ident )
		If node Return node
		
		Return Null
	End
	
	Method DistanceToType:Int( type:Type ) Override
	
		If type=Self Return 0
		
		If type=Type.VariantType Return MAX_DISTANCE

		'enum->integral/bool.		
		Local ptype:=TCast<PrimType>( type )
		If ptype And (ptype=Type.BoolType Or ptype.IsIntegral) Return MAX_DISTANCE
		
		Return -1
	End

End

Class EnumScope Extends Scope

	Field etype:EnumType
	
	Method New( etype:EnumType,outer:Scope )
		Super.New( outer )
		
		Self.etype=etype
	End
	
	Property Name:String() Override
	
		Return outer.Name+"."+etype.edecl.ident
	End

End
