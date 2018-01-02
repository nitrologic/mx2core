
Namespace mx2

Class FileScope Extends Scope

	Field fdecl:FileDecl
	
	Field nmspace:NamespaceScope
	
	Field usings:Stack<NamespaceScope>
	
	Field toSemant:=New Stack<SNode>

	Method New( fdecl:FileDecl )
		Super.New( Null )
		
		Local module:=fdecl.module

		Self.fdecl=fdecl
		Self.usings=module.usings
		
		nmspace=Builder.GetNamespace( fdecl.nmspace )
		nmspace.inner.Push( Self )
		outer=nmspace
		
		For Local member:=Eachin fdecl.members
		
			Local node:=member.ToNode( Self )
			
			If member.IsExtension
			
				nmspace.classexts.Push( TCast<ClassType>( node ) )
				
			Else If member.IsPublic
			
				If Not nmspace.Insert( member.ident,node ) Continue
				
			Else
			
				If Not Insert( member.ident,node ) Continue
				
			Endif

			toSemant.Push( node )
		Next
	End
	
	Method UsingNamespace:Bool( nmspace:NamespaceScope )
		If usings.Contains( nmspace ) Return True
		usings.Push( nmspace )
		Return False
	End
		
	Method UsingInner( nmspace:NamespaceScope )
		For Local scope:=Eachin nmspace.inner
			Local nmspace:=Cast<NamespaceScope>( scope )
			If nmspace UsingNamespace( nmspace )
		Next
	End
	
	Method UsingAll( nmspace:NamespaceScope )
		If UsingNamespace( nmspace ) Return
		For Local scope:=Eachin nmspace.inner
			Local nmspace:=Cast<NamespaceScope>( scope )
			If nmspace UsingAll( nmspace )
		Next
	End
	
	Method SemantUsings()
	
		If nmspace<>Builder.monkeyNamespace
			UsingAll( Builder.monkeyNamespace )
		Endif

		For Local use:=Eachin fdecl.usings
		
			If use="*"
				UsingAll( Builder.rootNamespace )
				Continue
			Endif
		
			If use.EndsWith( ".." )
				Local nmspace:=Builder.GetNamespace( use.Slice( 0,-2 ),True )
				UsingAll( nmspace )
				Continue
			Endif
		
			If use.EndsWith( ".*" )
				Local nmspace:=Builder.GetNamespace( use.Slice( 0,-2 ),True )
				UsingInner( nmspace )
				Continue
			Endif
			
			Local nmspace:=Builder.GetNamespace( use,True )
			If nmspace UsingNamespace( nmspace )
		Next
	End

	Method Semant()
	
		For Local node:=Eachin toSemant
			Try			
				node.Semant()
			Catch ex:SemantEx
			End
		Next
		
	End
	
	Method FindNode:SNode( ident:String ) Override
	
		'Search in namespace hierarchy
		'
		Local node:=Super.FindNode( ident )
		If node Return node
		
		'Search in usings
		'
		Local finder:=New NodeFinder( ident )
		
		For Local nmspace:=Eachin usings
			finder.Add( nmspace.GetNode( ident ) )
		Next
		
		Return finder.Found
	End
	
	Method FindType:Type( ident:String ) Override

		'Search in namespace hierarchy
		'
		Local type:=Super.FindType( ident )
		If type Return type
		
		'Search in usings
		'
		Local finder:=New NodeFinder( ident )

		For Local nmspace:=Eachin usings
			finder.Add( nmspace.GetType( ident ) )
		Next

		Return Cast<Type>( finder.Found )
	End
	
	Method FindExtensions:SNode( finder:NodeFinder,ctype:ClassType )
	
		'Search nmspace hierarchy
		'		
		nmspace.FindExtensions( finder,ctype )
		
		'Search usings
		'
		For Local nmspace:=Eachin usings
			nmspace.GetExtensions( finder,ctype )
		Next
		
		Return finder.Found
	End
	
	Function FindExtensions:SNode( ident:String,ctype:ClassType,found:SNode )
	
		Local scope:=Scope.Semanting()
		If Not scope Return found
		
		Local fscope:=scope.FindFile()
		If Not fscope Return found
		
		Local finder:=New NodeFinder( ident )
		finder.Add( found )
		
		Return fscope.FindExtensions( finder,ctype )
	End

	Method FindFile:FileScope() Override

		Return Self
	End
	
End
