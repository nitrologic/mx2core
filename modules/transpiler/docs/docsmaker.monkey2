
'This is a MESS!!!!!

Namespace mx2.docs

Const PAGES_DIR:="docs/__PAGES__/"

Class DocsMaker

	Method New()
	
		_nav=New JsonBuffer
	
		_md=New MarkdownBuffer( "",Lambda:String( link:String,name:String )
		
			Return ResolveLink( link,name,_linkScope )
			
		End )
	End
	
	Method MakeManPages( module:Module )
	
		Local path:=RealPath( module.baseDir+"docs/manual.md" )
		If GetFileType( path )<>FileType.File Return
		
		DeleteDir( module.baseDir+"docs/__MANPAGES__",True )
		CreateDir( module.baseDir+"docs/__MANPAGES__" )
		
		Local pages:=ManPage.MakeManPages( path,module,Lambda:String( link:String,name:String )
		
			Return ResolveLink( link,name,_linkScope )
			
		End )
		
		For Local it:=Eachin pages
		
			Local path:=it.Key		'source path
			Local page:=it.Value	'ManPage
			
			Print "Making manual page:"+path
			
			Local dir:=ExtractDir( path ),cd:=".."
			While dir<>module.baseDir+"docs/" And Not IsRootDir( dir )
				dir=ExtractDir( dir )
				cd="../"+cd
			Wend
			
			Local mod_dir:="../.."
			Local mx2_dir:=mod_dir+"/../.."
			
			Local html:=_pageTemplate.Replace( "${CONTENT}",page.HtmlSource )
			
			html=html.Replace( "${MX2_DIR}",mx2_dir )
			html=html.Replace( "${MOD_DIR}",mod_dir )
			html=html.Replace( "${CD}",cd )
			
			SaveString( html,page.Path )
		
		Next
		
		Local page:=pages[path]
		Local node:=page.RootNode
		Local json:=node.ToJson( RealPath( "modules" ) ).ToJson()
		
		SaveString( json,module.baseDir+"docs/__MANPAGES__/index.js" )
	End
	
	Method MakeModulePage:String( module:Module )
	
		Local mdocs:=module.baseDir+"docs/module.md"
		
		Local md:=stringio.LoadString( mdocs )
		If Not md Return ""
		
		Print "Making module docs:"+mdocs
		
		_md.Emit( md )
		
		Local docs:=_md.Flush()
		
		docs=docs.Replace( "${CD}",".." )
		
		Local page:="module"
		
		SavePage( docs,page )
		
		Return page
	End
	
	Method MakeDocs:String( module:Module )
	
		_module=module
		
		_pagesDir=_module.baseDir+PAGES_DIR
		
		_pageTemplate=stringio.LoadString( "docs/docs_page_template.html" )
		
		DeleteDir( _pagesDir,True )
		CreateDir( _pagesDir,True )

		Local nmspaces:=New StringMap<NamespaceScope>
		
		Local nmspaceDocs:=New StringMap<String>
		
		For Local fscope:=Eachin _module.fileScopes
			
			Local nmspace:=Cast<NamespaceScope>( fscope.outer )
			If Not nmspace Continue
			
			nmspaces[nmspace.Name]=nmspace
			nmspaceDocs[nmspace.Name]+=fscope.fdecl.docs
		Next
		
		_linkScope=Null
		
		MakeManPages( module )
		
		Local page:=MakeModulePage( module )

		BeginNode( _module.name,page )
		
		For Local nmspace:=Eachin nmspaces.Values

			Print "Making namespace docs:"+nmspace.Name
		
			EmitNamespace( nmspace,nmspaceDocs[nmspace.Name] )
		Next
		
		EndNode()
		
		Local tree:=_nav.Flush()
		
		stringio.SaveString( tree,_pagesDir+"index.js" )

		Return tree
	End
	
	Private
	
	Field _nav:JsonBuffer
	
	Field _md:MarkdownBuffer

	Field _module:Module
	
	Field _pagesDir:String			'module/docs
	Field _pageTemplate:String
	
	Field _linkScope:Scope

	Method Esc:String( id:String )
		id=id.Replace( "|","\|" )
		id=id.Replace( "_","\_" )
		id=id.Replace( "<","\<" )
		id=id.Replace( ">","\>" )
		Return id
	End	
	
	Method DeclPath:String( decl:Decl,scope:Scope )
	
		Local ident:=decl.ident.Replace( "@","" )
		If Not IsIdent( ident[0] ) ident=OpSym( ident )
		
		Local slug:=scope.Name+"."+ident
		
		Repeat
			Local i:=slug.Find( "<" )
			If i=-1 Exit
			Local i2:=slug.Find( ">",i+1 )
			If i2=-1 Exit
			slug=slug.Slice( 0,i )+slug.Slice( i2+1 )
		Forever
		
		If decl.IsExtension slug+="+"
		
		Return slug
	End
	
	Method NamespacePath:String( nmspace:NamespaceScope )
	
		Return nmspace.Name
	End
	
	Method DeclSlug:String( decl:Decl,scope:Scope )

		Local module:=scope.FindFile().fdecl.module.name

		Local slug:=module+":"+DeclPath( decl,scope ).Replace( ".","-" )
		
		Return slug
	End
	
	Method NamespaceSlug:String( nmspace:NamespaceScope )
	
		Local slug:=_module.name+":"+NamespacePath( nmspace ).Replace( ".","-" )
		
		Return slug
	End
	
	Method MakeLink:String( text:String,decl:Decl,scope:Scope )
	
		Local slug:=DeclSlug( decl,scope )
		
		Return "<a href=~qjavascript:void('"+slug+"')~q onclick=~qopenDocsPage('"+slug+"')~q>"+text+"</a>"
	End
	
	Method MakeLink:String( text:String,nmspace:NamespaceScope )
	
		Local slug:=NamespaceSlug( nmspace )
		
		Return "<a href=~qjavascript:void('"+slug+"')~q onclick=~qopenDocsPage('"+slug+"')~q>"+text+"</a>"
	End

	Method FixKeyword:String( ident:String )
	
		If KeyWords.Contains( ident.ToLower() ) Return "@"+ident.ToLower()
		
		If ident.EndsWith( "+" ) Return ident.Slice( 0,-1 )
		
		Return ident
	End
	
	Method ResolveLink:String( path:String,name:String,scope:Scope )
		
		If Not name name=path
		
		If path.StartsWith( "http:" ) Or path.StartsWith( "https:" ) Return "<a href='"+path+"'>"+name+"</a>"
	
'		Print "ResolveLink( path="+path+", name="+name+" )"
	
		Local i0:=0
		Local tpath:=""
		
		Repeat
		
			Local i1:=path.Find( ".",i0 )
			
			If i1=-1
			
				If Not scope Return name

				Local id:=path.Slice( i0 )
				
				Local node:=scope.FindNode( FixKeyword( id ) )
				If Not node Return name
				
				tpath+=id
				
				If Not name name=tpath
				
				Local vvar:=Cast<VarValue>( node )
				If vvar Return MakeLink( name,vvar.vdecl,vvar.scope )
				
				Local flist:=Cast<FuncList>( node )
				If flist Return MakeLink( name,flist.funcs[0].fdecl,flist.funcs[0].scope )
				
				Local etype:=TCast<EnumType>( node )
				If etype Return MakeLink( name,etype.edecl,etype.scope.outer )
				
				Local ntype:=TCast<NamespaceType>( node )
				If ntype Return MakeLink( name,ntype.scope )
				
				Local ctype:=TCast<ClassType>( node )
				If ctype Return MakeLink( name,ctype.cdecl,ctype.scope.outer )
				
				Print "Can't resolve link:"+path+", id="+id
				Return name
			Endif
			
			Local id:=path.Slice( i0,i1 )
			i0=i1+1

			Local type:Type
			If scope
				Try
					type=scope.FindType( FixKeyword( id ) )
				Catch ex:SemantEx
				End
			Else If Not tpath
				For Local fscope:=Eachin _module.fileScopes
					If id<>fscope.nmspace.ntype.ident Continue
					type=fscope.nmspace.ntype
					Exit
				Next
				If Not type type=Builder.monkeyNamespace.FindType( FixKeyword( id ) )
			Endif

			tpath+=id+"."
			
			If Not type 
				If scope
					Try
						Local node:=scope.FindNode( FixKeyword( id ) )
						
						Local vvar:=Cast<VarValue>( node )
						If vvar
							Local ctype:=TCast<ClassType>( vvar.type )
							If ctype
								scope=ctype.scope
								Continue
							Endif
						Endif
					Catch ex:SemantEx
					End
				Endif
				Print "Can't resolve link:"+path+", id="+id
				Return name
			Endif
			
			Local ntype:=TCast<NamespaceType>( type )
			If ntype
				scope=ntype.scope
				Continue
			Endif
			
			Local ctype:=TCast<ClassType>( type )
			If ctype
				scope=ctype.scope
				Continue
			Endif
			
			Local etype:=TCast<EnumType>( type )
			If etype
				'stop at Enum!
				If Not name name=tpath+"."+path.Slice( i0 )
				Return MakeLink( name,etype.edecl,etype.scope.outer )
			Endif
			
			Return name
			
		Forever
		
		Return name
	End
	
	Method DeclIdent:String( decl:Decl,gen:Bool=False )

		Local ident:=decl.ident
		
		If decl.IsOperator
			ident="Operator "+ident
		Else If ident="new"
			ident="New"
		Else If ident.StartsWith( "@" )
			ident=ident.Slice( 1 ).Capitalize()
		Endif
		
		If gen
			Local adecl:=Cast<AliasDecl>( decl )
			If adecl And adecl.genArgs ident+="<"+(",".Join( adecl.genArgs ))+">"
			
			Local cdecl:=Cast<ClassDecl>( decl )
			If cdecl And cdecl.genArgs ident+="<"+(",".Join( cdecl.genArgs ))+">"
			
			Local fdecl:=Cast<FuncDecl>( decl )
			If fdecl And fdecl.genArgs ident+="<"+(",".Join( fdecl.genArgs ))+">"
		Endif
		
		Return Esc( ident )
	End
	
	Method DeclIdent:String( decl:Decl,scope:Scope,gen:Bool=False )

		Return MakeLink( DeclIdent( decl,gen ),decl,scope )
	End
	
	Method DeclName:String( decl:Decl,scope:Scope )
	
		Local path:=""
		Local nmspace:=scope.FindFile().nmspace
		
		While scope<>nmspace
			If Not scope Return "?????"
			Local cscope:=Cast<ClassScope>( scope )
			If cscope
				Local decl:=cscope.ctype.cdecl
				path=DeclIdent( decl,cscope.outer,True )+"."+path
			Endif
			scope=scope.outer
		Wend
		
		If path path=path.Slice( 0,-1 )+"."
		
		Return path+DeclIdent( decl )
	End
	
	Method DeclDesc:String( decl:Decl )
	
		Local desc:=decl.docs
		
		Local i:=desc.Find( "~n" )
		
		If i<>-1 desc=desc.Slice( 0,i )
		
		If desc.StartsWith( "@deprecated" )
		
			Local arg:=desc.Slice( 11 ).Trim()
			
			desc="(Deprecated: "+arg+")"
		
		Endif
		
		Return desc
	End
	
	Method SavePage( docs:String,page:String )
	
		page=page.Replace( ".","-" )
		
		docs=_pageTemplate.Replace( "${CONTENT}",docs )
		
		stringio.SaveString( docs,_pagesDir+page+".html" )
	End
	
	Method TypeName:String( type:Type,prefix:String )
	
		Local xtype:=Cast<AliasType>( type )
		If xtype
			Local args:=""
			For Local type:=Eachin xtype.types
				args+=","+TypeName( type,prefix )
			Next
			If args args="\<"+args.Slice( 1 )+"\>"
		
			If xtype.instanceOf xtype=xtype.instanceOf
			
			Return MakeLink( Esc( xtype.adecl.ident ),xtype.adecl,xtype.scope )+args
		Endif
	
		Local vtype:=TCast<VoidType>( type )
		If vtype
			Return vtype.Name
		Endif
	
		Local gtype:=TCast<GenArgType>( type )
		If gtype
			Return gtype.Name.Replace( "?","" )
		Endif
	
		Local ptype:=TCast<PrimType>( type )
		If ptype
			Local ctype:=ptype.ctype
			Return MakeLink( Esc( ptype.Name ),ctype.cdecl,ctype.scope.outer )
		Endif
		
		Local ntype:=TCast<NamespaceType>( type )
		If ntype
			Return Esc( ntype.Name )
		Endif
		
		Local ctype:=TCast<ClassType>( type )
		If ctype
			Local args:=""
			For Local type:=Eachin ctype.types
				args+=","+TypeName( type,prefix )
			Next
			If args args="\<"+args.Slice( 1 )+"\>"
			
			If ctype.instanceOf ctype=ctype.instanceOf
			
			Return MakeLink( Esc( ctype.cdecl.ident ),ctype.cdecl,ctype.scope.outer )+args
		Endif
		
		Local etype:=TCast<EnumType>( type )
		If etype
			Local name:=etype.Name
			If name.StartsWith( prefix ) name=name.Slice( prefix.Length )
			Return MakeLink( Esc( name ),etype.edecl,etype.scope.outer )
		Endif
		
		Local qtype:=TCast<PointerType>( type )
		If qtype
			Return TypeName( qtype.elemType,prefix )+" Ptr"
		Endif
		
		Local atype:=TCast<ArrayType>( type )
		If atype
			If atype.rank=1 Return TypeName( atype.elemType,prefix )+"\[\]"
			Return TypeName( atype.elemType,prefix )+"\[,,,,,,,,,".Slice( 0,atype.rank )+"\]"
		End
		
		Local ftype:=TCast<FuncType>( type )
		If ftype
			Local args:=""
			For Local arg:=Eachin ftype.argTypes
				args+=","+TypeName( arg,prefix )
			Next
			args=args.Slice( 1 )
			Return TypeName( ftype.retType,prefix )+"( "+args+" )"
		Endif
		
		Print type.Name+"!!!!!!"
		Assert( False )
		Return ""
	End
	
	Method TypeName:String( type:Type,scope:Scope )
		Local prefix:=scope.FindFile().nmspace.Name+"."
		Return TypeName( type,prefix )
	End
	
	Method EmitHeader( decl:Decl,scope:Scope )
		Local fscope:=scope.FindFile()
		Local nmspace:=fscope.nmspace
		Local module:=fscope.fdecl.module
		
		_md.CurrentDir=ExtractDir( fscope.fdecl.path )
		
		Local md:=module.name+":"+MakeLink( NamespacePath( nmspace ),nmspace )+"."+DeclName( decl,scope )
		
		_md.Emit( "_"+md+"_" )
		
	End
	
	Method EmitDocs( docs:String )
	
		Local lines:=docs.Split( "~n" )
		
		Local indent:=0
		If lines.Length>1
			indent=10000
			For Local i:=1 Until lines.Length
				If Not lines[i].Trim() Continue
				indent=Min( indent,FindNonSpc( lines[i] ) )
			Next
			If indent=10000 indent=0
			lines[0]=" ".Dup( indent )+lines[0].Trim()
		Endif
		
		_md.Emit( lines,indent )
	End
	
	Method EmitDocs( decl:Decl )
	
		EmitDocs( decl.docs )
	End
	
	Method DocsHidden:Bool( decl:Decl )
		
		If decl.docs Return decl.docs.StartsWith( "@hidden" )
		
		Return decl.IsPrivate Or decl.IsInternal
	End
	
	Method DocsHidden:Bool( decl:Decl,access:Int )
		
		If access And (decl.flags & access) Return DocsHidden( decl )
		
		Return True
	End

	Method EmitExtensions( nmspace:NamespaceScope )
		
		If Not nmspace.classexts.Length Return
		
		_md.EmitBr()
		_md.Emit( "| Extensions | &nbsp; |" )
		_md.Emit( "|:---|:---" )
		
		For Local ctype:=Eachin nmspace.classexts
			
			Local decl:=ctype.cdecl
			
			_md.Emit( "| "+DeclIdent( decl,ctype.scope.outer )+" | "+DeclDesc( decl )+" |" )
		
		Next
		
	End
	
	Method EmitMembers( kind:String,scope:Scope,access:Int,inherited:int )
	
		Local tag:=""
		
		If inherited>=0
		
			If inherited tag="Inherited "
			
			Select access
			Case DECL_PUBLIC tag+="Public "
			Case DECL_PROTECTED tag+="Protected "
			End
		Endif
	
		Local init:=True
		
		For Local node:=Eachin scope.nodes
		
			Local atype:=Cast<AliasType>( node.Value )
			If atype
				If kind<>"alias" Continue
				Local decl:=atype.adecl
				If DocsHidden( decl,access ) Continue
				If inherited>=0 And inherited<>(scope<>atype.scope) Continue
				
				If init
					init=False
					_md.EmitBr()
					_md.Emit( "| "+tag+"Aliases | &nbsp; |" )
					_md.Emit( "|:---|:---" )
				Endif
				
				_md.Emit( "| "+DeclIdent( decl,atype.scope )+" | "+DeclDesc( decl )+" |" )
				Continue
			Endif

			Local ctype:=Cast<ClassType>( node.Value )
			If ctype
				Local decl:=ctype.cdecl
				If kind<>decl.kind Continue
				If DocsHidden( decl,access ) Continue
				If inherited>=0 And inherited<>(scope<>ctype.scope.outer) Continue
				
				If init
					init=False
					Local kinds:=kind.Capitalize() + (kind="class" ? "es" Else "s")
					_md.EmitBr()
					_md.Emit( "| "+tag+kinds+" | |" )
					_md.Emit( "|:---|:---|" )
				Endif
				
				_md.Emit( "| "+DeclIdent( decl,ctype.scope.outer )+" | "+DeclDesc( decl )+" |" )
				Continue
			Endif
			
			Local etype:=Cast<EnumType>( node.Value )
			If etype
				If kind<>"enum" Continue
				Local decl:=etype.edecl
				If DocsHidden( decl,access ) Continue
				If inherited>=0 And inherited<>(scope<>etype.scope.outer) Continue
				
				If init
					init=False
					_md.EmitBr()
					_md.Emit( "| "+tag+"Enums | |" )
					_md.Emit( "|:---|:---|" )
				Endif

				_md.Emit( "| "+DeclIdent( decl,etype.scope.outer )+" | "+DeclDesc( decl )+" |" )
				Continue
			Endif

			Local vvar:=Cast<VarValue>( node.Value )
			If vvar
				Local decl:=vvar.vdecl
				If kind<>decl.kind Continue
				If DocsHidden( decl,access ) Continue
				If inherited>=0 And inherited<>(scope<>vvar.scope) Continue

				If init
					init=False
					_md.EmitBr()
					_md.Emit( "| "+tag+kind.Capitalize()+"s | |" )
					_md.Emit( "|:---|:---|" )
				Endif

				_md.Emit( "| "+DeclIdent( decl,vvar.scope )+" | "+DeclDesc( decl )+" |" )
				Continue
			Endif
			
			Local plist:=Cast<PropertyList>( node.Value )
			If plist
				If kind<>"property" Continue
				Local decl:=plist.pdecl
				If DocsHidden( decl,access ) Continue
				If inherited>=0 And inherited<>(scope<>plist.scope) Continue
				
				If init
					init=False
					_md.EmitBr()
					_md.Emit( "| "+tag+"Properties | |" )
					_md.Emit( "|:---|:---|" )
				Endif

				_md.Emit( "| "+DeclIdent( decl,plist.scope )+" | "+DeclDesc( decl )+" |" )
				Continue
			Endif
		
			Local flist:=Cast<FuncList>( node.Value )
			If flist
				If kind<>"constructor" And kind<>"operator" And kind<>"method" And kind<>"function" Continue

				For Local func:=Eachin flist.funcs
					Local decl:=func.fdecl
					If DocsHidden( decl,access ) Continue
					If inherited>=0 And inherited<>(scope<>func.scope) Continue
					
					If kind="constructor" 
						If decl.ident<>"new" Continue
					Else If kind="operator"
						If Not decl.IsOperator Continue
					Else If kind<>decl.kind Or decl.ident="new" Or decl.IsOperator
						Continue
					Endif
					
					If init
						init=False
						_md.EmitBr()
						_md.Emit( "| "+tag+kind.Capitalize()+"s | |" )
						_md.Emit( "|:---|:---|" )
					Endif
					
					_md.Emit( "| "+DeclIdent( decl,func.scope )+" | "+DeclDesc( decl )+" |" )
					Exit
					
				Next
				Continue
			Endif
			
		Next

	End
	
	Method BeginNode( name:String,page:String="" )
	
		If page page=",data:{page:'"+_module.name+":"+page+"'}"
		
		_nav.Emit( "{ text:'"+name+"'"+page+",children:[" )

	End
	
	Method EmitNode( decl:Decl,scope:Scope,page:String="" )

		Local id:=decl.ident
		If id.StartsWith( "@" ) id=id.Slice( 1 ).Capitalize()	
	
		EmitNode( id,scope,page )
	End
	
	Method EndNode()

		_nav.Emit( "] }" )
	End
	
	Method EmitLeaf( name:String,page:String="" )
	
		If page page=",data:{page:'"+_module.name+":"+page+"'}"
		
		_nav.Emit( "{ text:'"+name+"'"+page+",children:[] }" )
		
	End
	
	Method EmitLeaf( decl:Decl,page:String="" )
	
		Local id:=decl.ident
		If id.StartsWith( "@" ) id=id.Slice( 1 ).Capitalize()	

		EmitLeaf( id,page )
	End
	
	Method EmitNode( name:String,scope:Scope,page:String="" )
	
		BeginNode( name,page )
	
		BeginNode( "Aliases" )
		EmitAliases( scope,"alias" )
		EndNode()
		
		BeginNode( "Enums" )
		EmitEnums( scope,"enum" )
		EndNode()
		
		BeginNode( "Structs" )
		EmitClasses( scope,"struct" )
		EndNode()		
		
		BeginNode( "Classes" )
		EmitClasses( scope,"class" )
		EndNode()
		
		BeginNode( "Interfaces" )
		EmitClasses( scope,"interface" )
		EndNode()
		
		BeginNode( "Constants" )
		EmitVars( scope,"const" )
		EndNode()

		BeginNode( "Globals" )
		EmitVars( scope,"global" )
		EndNode()
		
		BeginNode( "Fields" )
		EmitVars( scope,"field" )
		EndNode()

		BeginNode( "Contructors" )		
		EmitFuncs( scope,"constructor" )
		EndNode()
		
		BeginNode( "Properties" )
		EmitProperties( scope,"property" )
		EndNode()

		BeginNode( "Operators" )		
		EmitFuncs( scope,"operator" )
		EndNode()
		
		BeginNode( "Methods" )
		EmitFuncs( scope,"method" )
		EndNode()

		BeginNode( "Functions" )
		EmitFuncs( scope,"function" )
		EndNode()
		
		Local nmscope:=Cast<NamespaceScope>( scope )
		If nmscope
			BeginNode( "Extensions" )
			For Local ctype:=Eachin nmscope.classexts
				EmitClass( ctype )
			Next
			EndNode()
		Endif
		
		EndNode()
		
	End
	
	Method EmitNamespace( nmspace:NamespaceScope,docs:String )

		_linkScope=nmspace
		
		Local md:=_module.name+":"+nmspace.Name
		
		_md.Emit( "_"+md+"_" )
	
		EmitMembers( "alias",nmspace,DECL_PUBLIC,-1 )
		EmitMembers( "enum",nmspace,DECL_PUBLIC,-1 )
		EmitMembers( "struct",nmspace,DECL_PUBLIC,-1 )
		EmitMembers( "class",nmspace,DECL_PUBLIC,-1 )
		EmitMembers( "interface",nmspace,DECL_PUBLIC,-1 )
		EmitMembers( "const",nmspace,DECL_PUBLIC,-1 )
		EmitMembers( "global",nmspace,DECL_PUBLIC,-1 )
		EmitMembers( "function",nmspace,DECL_PUBLIC,-1 )
		
		EmitExtensions( nmspace )
		
		EmitDocs( docs )

		docs=_md.Flush()
		
		Local page:=NamespacePath( nmspace )
		SavePage( docs,page )
		
		EmitNode( nmspace.ntype.Name,nmspace,page )
	End
	
	Method EmitVars( scope:Scope,kind:String )
	
		For Local node:=Eachin scope.nodes
	
			Local vvar:=Cast<VarValue>( node.Value )
			If Not vvar Or vvar.transFile.module<>_module Continue
			
			Local decl:=vvar.vdecl
			If decl.kind<>kind Or DocsHidden( decl ) Continue
		
			_linkScope=vvar.scope

			EmitHeader( decl,vvar.scope )
		
			_md.Emit( "##### "+decl.kind.Capitalize()+" "+DeclIdent( decl )+":"+TypeName( vvar.type,vvar.scope ) )
			
			EmitDocs( decl )
		
			Local docs:=_md.Flush()

			Local page:=DeclPath( vvar.vdecl,vvar.scope )
			SavePage( docs,page )
			
			EmitLeaf( vvar.vdecl,page )
			
		Next
	
	End
	
	Method EmitAliases( scope:Scope,kind:String )
	
		For Local node:=Eachin scope.nodes
		
			Local atype:=Cast<AliasType>( node.Value )
			If Not atype Continue
			
			Local decl:=atype.adecl
			If decl.kind<>kind Or DocsHidden( decl ) Continue
		
			_linkScope=atype.scope
		
			EmitHeader( decl,atype.scope )
		
			_md.Emit( "##### Alias "+DeclIdent( decl,True )+":"+TypeName( atype._alias,atype.scope ) )
		
			EmitDocs( decl )
		
			Local docs:=_md.Flush()

			Local page:=DeclPath( atype.adecl,atype.scope )
			SavePage( docs,page )
			
			EmitLeaf( atype.adecl,page )

		Next
	
	End
	
	Method EmitEnums( scope:Scope,kind:String )
	
		For Local node:=Eachin scope.nodes
	
			Local etype:=Cast<EnumType>( node.Value )
			If Not etype Continue
			
			Local decl:=etype.edecl
			If decl.kind<>kind Or DocsHidden( decl ) Continue
			
			_linkScope=etype.scope.outer

			EmitHeader( decl,etype.scope.outer )
		
			_md.Emit( "##### Enum "+DeclIdent( decl ) )
		
			EmitDocs( decl )
		
			Local docs:=_md.Flush()

			Local page:=DeclPath( etype.edecl,etype.scope.outer )
			SavePage( docs,page )
			
			EmitLeaf( etype.edecl,page )
			
		Next
	
	End
	
	Method EmitClass( ctype:ClassType )
		
		Local decl:=ctype.cdecl
		
		_linkScope=ctype.scope
			
		EmitHeader( decl,ctype.scope.outer )
		
		If decl.IsExtension
			
			_md.Emit( "##### "+decl.kind.Capitalize()+" "+DeclIdent( decl,True )+" Extension" )
			
		Else
			
			Local xtends:=""
			If ctype.superType
				If ctype.superType<>Type.ObjectClass
					xtends=" Extends "+TypeName( ctype.superType,ctype.scope.outer )
				Endif
			Else If ctype.extendsVoid
				xtends=" Extends Void"
			Endif
			
			Local implments:=""
			If decl.ifaceTypes
				Local ifaces:=""
				For Local iface:=Eachin ctype.ifaceTypes
					ifaces+=","+TypeName( iface,ctype.scope.outer )
				Next
				ifaces=ifaces.Slice( 1 )
				If decl.kind="interface"
					xtends=" Extends "+ifaces
				Else
					implments=" Implements "+ifaces
				Endif
			Endif
			
			Local mods:=""
			If decl.IsVirtual
				mods+=" Virtual"
			Else If decl.IsAbstract
				mods+=" Abstract"
			Else If decl.IsFinal
				mods+=" Final"
			Endif
			
			_md.Emit( "##### "+decl.kind.Capitalize()+" "+DeclIdent( decl,True )+xtends+implments+mods )

		Endif
		
		EmitDocs( decl )
		
		Local access:=DECL_PUBLIC
		For Local acc:=0 Until 2
		
			Local inh:=False
			
			EmitMembers( "alias",ctype.scope,access,inh )
			EmitMembers( "enum",ctype.scope,access,inh )
			EmitMembers( "struct",ctype.scope,access,inh )
			EmitMembers( "class",ctype.scope,access,inh )
			EmitMembers( "interface",ctype.scope,access,inh )
			EmitMembers( "const",ctype.scope,access,inh )
			EmitMembers( "global",ctype.scope,access,inh )
			EmitMembers( "field",ctype.scope,access,inh )
			EmitMembers( "property",ctype.scope,access,inh )
			EmitMembers( "constructor",ctype.scope,access,inh )
			EmitMembers( "operator",ctype.scope,access,inh )
			EmitMembers( "method",ctype.scope,access,inh )
			EmitMembers( "function",ctype.scope,access,inh )
			
			access=DECL_PROTECTED
		End

		Local docs:=_md.Flush()

		Local page:=DeclPath( ctype.cdecl,ctype.scope.outer )
		SavePage( docs,page )
		
		EmitNode( ctype.cdecl,ctype.scope,page )
		
	End
	
	Method EmitClasses( scope:Scope,kind:String )
	
		For Local node:=Eachin scope.nodes
			
			Local ctype:=Cast<ClassType>( node.Value )
			If Not ctype Or ctype.transFile.module<>_module Continue
			
			Local decl:=ctype.cdecl
			If decl.kind<>kind Or DocsHidden( decl ) Continue
			
			EmitClass( ctype )
			
			#rem
			
			Local xtends:=""
			If ctype.superType
				If ctype.superType<>Type.ObjectClass
					xtends=" Extends "+TypeName( ctype.superType,ctype.scope.outer )
				Endif
			Else If ctype.extendsVoid
				xtends=" Extends Void"
			Endif
			
			Local implments:=""
			If decl.ifaceTypes
				Local ifaces:=""
				For Local iface:=Eachin ctype.ifaceTypes
					ifaces+=","+TypeName( iface,ctype.scope.outer )
				Next
				ifaces=ifaces.Slice( 1 )
				If decl.kind="interface"
					xtends=" Extends "+ifaces
				Else
					implments=" Implements "+ifaces
				Endif
			Endif
			
			Local mods:=""
			If decl.IsVirtual
				mods+=" Virtual"
			Else If decl.IsAbstract
				mods+=" Abstract"
			Else If decl.IsFinal
				mods+=" Final"
			Endif
			
			_md.Emit( "##### "+decl.kind.Capitalize()+" "+DeclIdent( decl,True )+xtends+implments+mods )
			
			EmitDocs( decl )
			
			Local access:=DECL_PUBLIC
			For Local acc:=0 Until 2
			
				Local inh:=False
				
				EmitMembers( "alias",ctype.scope,access,inh )
				EmitMembers( "enum",ctype.scope,access,inh )
				EmitMembers( "struct",ctype.scope,access,inh )
				EmitMembers( "class",ctype.scope,access,inh )
				EmitMembers( "interface",ctype.scope,access,inh )
				EmitMembers( "const",ctype.scope,access,inh )
				EmitMembers( "global",ctype.scope,access,inh )
				EmitMembers( "field",ctype.scope,access,inh )
				EmitMembers( "property",ctype.scope,access,inh )
				EmitMembers( "constructor",ctype.scope,access,inh )
				EmitMembers( "operator",ctype.scope,access,inh )
				EmitMembers( "method",ctype.scope,access,inh )
				EmitMembers( "function",ctype.scope,access,inh )
				
				access=DECL_PROTECTED
			End

			Local docs:=_md.Flush()

			Local page:=DeclPath( ctype.cdecl,ctype.scope.outer )
			SavePage( docs,page )
			
			EmitNode( ctype.cdecl,ctype.scope,page )
			
			#end
			
		Next
	
	End
	
	Method EmitProperties( scope:Scope,kind:String )
	
		For Local node:=Eachin scope.nodes
		
			Local plist:=Cast<PropertyList>( node.Value )
			If Not plist Continue
			
			Local decl:=plist.pdecl
			If decl.kind<>kind Or DocsHidden( decl ) Continue

			Local func:=plist.getFunc
			If Not func 
				func=plist.setFunc
				If Not func Continue
			Endif

			Local type:=func.ftype.argTypes ? func.ftype.argTypes[1] Else func.ftype.retType
			
			_linkScope=func.scope
			
			EmitHeader( decl,func.scope )
			
			_md.Emit( "##### Property "+DeclIdent( decl )+":"+TypeName( type,func.scope ) )
			
			EmitDocs( decl )
			
			Local docs:=_md.Flush()
			
			Local page:=DeclPath( plist.pdecl,plist.scope )
			SavePage( docs,page )
			
			EmitLeaf( plist.pdecl,page )

		Next
	
	End
	
	Method EmitFuncs( scope:Scope,kind:String )
	
		For Local node:=Eachin scope.nodes
		
			Local flist:=Cast<FuncList>( node.Value )
			If Not flist Or Cast<PropertyList>( flist ) Continue
			
			Local buf:StringStack
					
			For Local func:=Eachin flist.funcs
				If (func.IsMethod Or func.IsCtor) And func.scope<>scope Continue
				
				Local decl:=func.fdecl
				If DocsHidden( decl ) Continue
				
				If kind="constructor"
					If decl.ident<>"new" Continue
				Else If kind="operator"
					If Not decl.IsOperator Continue
				Else If kind<>decl.kind Or decl.ident="new" Or decl.IsOperator
					Continue
				Endif
				
				_linkScope=func.scope
				
				If Not buf
					buf=New StringStack
					EmitHeader( decl,func.scope )
				Endif
				
				buf.Push( decl.docs )
				
				Local tkind:=decl.kind.Capitalize()+" "
				If decl.IsOperator tkind=""
				
				Local params:=""
				For Local i:=0 Until func.ftype.argTypes.Length
					Local ident:=Esc( func.fdecl.type.params[i].ident )
					Local type:=TypeName( func.ftype.argTypes[i],func.scope )
					Local init:=""
					If func.fdecl.type.params[i].init
						init="="+func.fdecl.type.params[i].init.ToString()
					Endif
					If params params+=", "
					params+=ident+":"+type+init
				Next
				
				_md.Emit( "##### "+tkind+DeclIdent( decl,True )+":"+TypeName( func.ftype.retType,func.scope )+"( "+params+" )" )
	
			Next
			
			If Not buf Continue
			
			EmitDocs( buf.Join( "~n" ) )
		
			Local docs:=_md.Flush()
			
			Local page:=DeclPath( flist.funcs[0].fdecl,flist.funcs[0].scope )

			SavePage( docs,page )
			
			EmitLeaf( flist.funcs[0].fdecl,page )
			
		Next
	
	End
	
End
	
