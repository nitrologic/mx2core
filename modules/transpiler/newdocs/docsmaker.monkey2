
Namespace mx2.newdocs

Class DocsMaker

	Method new( docsDir:String,pageTemplate:String )
	
		_docsDir=docsDir
		
		_pageTemplate=pageTemplate
	End

	Method CreateModuleDocs( module:Module )
	
		_module=module

		local docsDir:=_docsDir+"modules/"+_module.name+"/"
		DeleteDir( docsDir,true )
		CreateDir( docsDir,True )

		Local root:=New DocsNode( "","",null,DocsType.Root )

		_convertor=New MarkdownConvertor( ResolveHtmlLink )
		
		'assets
		Local asspath:=module.baseDir+"newdocs/assets"
		If GetFileType( asspath )=FileType.Directory
			Local dst:=docsDir+"assets"
'			DeleteDir( dst,True )
			CreateDir( dst,True )
			CopyDir( asspath,dst )
		Endif
		
		'manual
		Local manpath:=module.baseDir+"newdocs/manual.md"
		
		Local manDocs:DocsNode
		
		If GetFileType( manpath )=FileType.File
			
			Print "Making manual docs"
			
			Local src:=LoadString( manpath )
			
			manDocs=New DocsNode( "manual","",root,DocsType.Dir )
			
			Local buf:=New DocsBuffer( manDocs,ExtractDir( manpath ) )

			buf.Emit( src )
			
			buf.Flush()
		Endif
		
		Local modDocs:=New DocsNode( "module","",root,DocsType.Dir )
		
		Local modNav:=MakeModuleDocs( modDocs )
		
		#rem		
		Local modNav:=New DocsNode( _module.name,_module.name,modDocs,DocsType.Nav )
		
		Local done:=New Map<NamespaceScope,Bool>
		
		'Create docs tree
		
		For Local fscope:=Eachin _module.fileScopes
			
			Local scope:=Cast<NamespaceScope>( fscope.outer )
			If Not scope Continue
			
			If done[scope] Continue
			
			MakeNamespaceDocs( scope,modNav )
			
			done[scope]=True
		Next
		#end
		
		CreateHtmlPages( root,docsDir )
		
		If manDocs CreateJSNavTree( manDocs,docsDir+"manual/" )
			
		If modDocs CreateJSNavTree( modDocs,docsDir+"module/" )
		
	End
	
	Private
	
	Field _docsDir:String
	
	Field _pageTemplate:String
	
	Field _module:Module
	
	Field _convertor:MarkdownConvertor
	
	Field _converting:DocsNode
	
	Method CreateJSNavTree( docs:DocsNode,dir:String )
		
		docs.Clean()
		
		Local buf:=New StringStack
		
		buf.Push( "~n" )
		
		Local first:=True
		For Local child:=Eachin docs.Children
			If Not first buf.Push( "," )
			CreateJSNavTree( child,buf,"","modules/"+_module.name+"/" )
			first=False
		Next

		Local tree:=buf.Join( "" )
		
		tree=tree.Replace( "\_","_" )
		
		SaveString( tree,dir+"index.js" )
	End
		
	Method CreateJSNavTree( docs:DocsNode,buf:StringStack,indent:String,dir:String )
		
		buf.Add( "~n"+indent+"{text:'"+docs.Label+"'" )
		
		Select docs.Type
			
		Case DocsType.Decl,DocsType.Hash,DocsType.Nav
			
			If docs.Ident
				
				Local url:=dir+docs.FilePathUrl
				
				buf.Add( ",data:{page:'"+url+"'}")
				
			Endif
			
		End
		
		Local children:=docs.Children
		
		If children
		
			buf.Add( ",children:[" )

			local first:=True			
			For Local child:=Eachin children
				If Not first buf.Add( "," )
				CreateJSNavTree( child,buf,indent+"  ",dir )
				first=False
			Next
			
			buf.Add( "]" )
		
		Endif

		buf.Add( "}" )
		
	End
	
	Method CreateHtmlPages( docs:DocsNode,dir:String )
		
		Select docs.Type
			
		Case DocsType.Decl,DocsType.Nav
			
			If docs.Ident
			
				_converting=docs
				
				Local html:=_convertor.ConvertToHtml( docs.Markdown )
				
				_converting=Null
				
				If _pageTemplate html=_pageTemplate.Replace( "${CONTENT}",html )
		
				Local url:=dir+docs.FilePathUrl
				
	'			Print "Creating decl: "+docs.DeclPath
				
				SaveString( html,url )
				
			Endif
			
		Case DocsType.Dir
			
			Local path:=dir+docs.FilePath
			
'			Print "Creating dir:"+dir
			
			CreateDir( path )
			
		End
		
		For Local child:=Eachin docs.Children
		
			CreateHtmlPages( child,dir )
		Next
	End
	
	Method ResolveHtmlLink:String( link:String,name:String )
		
		If Not name name=link
		
		Local i:=link.Find( "://" )				'http://, https://
		If i<>-1
			If link.StartsWith( "http://" ) Or link.StartsWith( "https://" )
				Local anchor:="<a href='"+link+"'>"+name+"</a>"
				Return anchor
			Endif
			Local anchor:="<a href='"+link+"'>"+name+"</a>"
			Return anchor
		Endif
		
		i=link.Find( ":" )				'absolute link?
		If i<>-1
			Local modname:=link.Slice( 0,i ),url:=""
			
			If i<link.Length-1
			
				Local slug:=link.Slice( i+1 ).Replace( ".","-" )
			
				url="../../"+modname+"/module/"+slug
				
				Local i:=url.Find( "#" )
				If i<>-1
					url=url.Slice( 0,i )+".html"+url.Slice( i )
				Else
					url+=".html"
				Endif
			Else
				url="../../"+modname+"/module/"+modname+"-module.html"
			Endif
			
			Local anchor:="<a href='"+url+"'>"+name+"</a>"
			Return anchor
		Endif
		
'		Const monkeyTypes:="inumeric,iintegral,ireal,bool,byte,ubyte,short,ushort,int,uint,long,ulong,float,double,string,cstring,ovariant,typeinfo,declinfo,array,object,throwable"
		
		Local docs:=_converting.Find( link )
		If Not docs
			Print "Link not found:"+link+" while converting docs:"+_converting.FilePath
			Return name
		Endif
		
		Local url:="../"+docs.FilePathUrl
		Local anchor:="<a href='"+url+"'>"+name+"</a>"
		Return anchor
	End

	Method TypeName:String( type:Type,name:String="" )
	
		Local xtype:=Cast<AliasType>( type )
		If xtype
			Local types:=""
			For Local type:=Eachin xtype.types 
				types+=","+TypeName( type )
			Next
			If types types="<"+types.Slice(1)+">"
		
			If xtype.instanceOf xtype=xtype.instanceOf
			
			Return TypeName( xtype._alias,xtype.adecl.ident )+types
		Endif

		Local ptype:=Cast<PrimType>( type )
		If ptype 
			Local ctype:=ptype.ctype
			Local path:=ctype.Name
			If Not name name=DeclLabel( ctype.cdecl )
			Return "[[monkey:"+path+"|"+name+"]]"
			
'			If Not name name=ctype.Name
'			Local cname:=DeclDocsIdent( ctype.cdecl )
'			return "[[monkey:monkey.types."+cname+"|"+name+"]]"
		Endif
	
		Local atype:=Cast<ArrayType>( type )
		If atype
			Local ext:="[,,,,,,,,".Slice( 0,atype.rank )+"]"
			Return TypeName( atype.elemType,name )+ext
		Endif
		
		Local vtype:=Cast<PointerType>( type )
		If vtype 
			Return TypeName( vtype.elemType,name )+" Ptr"
		Endif
		
		Local ftype:=Cast<FuncType>( type )
		If ftype
			Local retType:=TypeName( ftype.retType )
			local argTypes:=""
			For Local arg:=Eachin ftype.argTypes
				If argTypes argTypes+=","
				argTypes+=","+TypeName( arg )
			Next
			Return retType+":("+argTypes+")"
		Endif
	
		Local ctype:=Cast<ClassType>( type )
		If ctype
			Local types:=""
			For Local type:=Eachin ctype.types 
				types+=","+TypeName( type )
			Next
			If types types="<"+types.Slice(1)+">"
				
			If ctype.instanceOf ctype=ctype.instanceOf
			
			'Print "Typeinfo name="+ctype.Name
			
			Local module:=ctype.transFile.module
			
			Local path:=type.Name
'			If path="Typeinfo" path="monkey.types.TypeInfo"	'need to fix @typeinfo keyword!
			
			Local i:=path.Find( "<" )
			If i<>-1 path=path.Slice( 0,i )
				
			If Not name 
				name=path
				If _module=ctype.transFile.module
					Local i:=name.FindLast( "." )
					If i<>-1 name=name.Slice( i+1 )
				Endif
			Endif
			
			Return "[["+module.name+":"+path+"|"+name+"]]"+types
		Endif
		
		Local gtype:=Cast<GenArgType>( type )
		If gtype
			Return gtype.ident
		Endif
		
		Return type.Name
	End
	
	Method DeclIdent:String( decl:Decl )

		Local ident:=decl.ident
		If ident.StartsWith( "@" )
			If ident.StartsWith( "@u" )
				ident="U"+ident.Slice( 2 ).Capitalize()
			Else
				ident=ident.Slice( 1 ).Capitalize()
				If ident="Cstring" ident="CString"
			Endif
		Else
			If ident="new" ident="New" Else If ident="to" ident="To"
		Endif

'		Local ident:=decl.ident.Replace( "@","" )
		
		If Not IsIdent( ident[0] ) ident="Op"+OpSym( ident ).Slice( 1 ).Capitalize()
			
		Return ident
	End
	
	Method DeclDocsIdent:String( decl:Decl )
		
		Local ident:=DeclIdent( decl )
		
		If decl.IsExtension ident+="EXT"
	
		Return ident
	End
	
	Method DeclLabel:String( decl:Decl )
	
		Local label:=decl.ident

		Local fdecl:=Cast<FuncDecl>( decl )
		If fdecl And fdecl.IsOperator
			If label="to" label="To"
			label="Operator "+label
		Else
			label=DeclIdent( decl )
		Endif
	
	#rem
		Local label:=decl.ident
		If label.StartsWith( "@" )
			If label.StartsWith( "@u" )
				label="U"+label.Slice( 2 ).Capitalize()
			Else
				label=label.Slice( 1 ).Capitalize()
				If label="Cstring" label="CString"
			Endif
		Else
			If label="new" label="New"
		Endif
		
		Local fdecl:=Cast<FuncDecl>( decl )
		If fdecl And fdecl.IsOperator
			If label="to" label=" To"
			 label="Operator"+label
		Endif
	#end
		
		Local xdecl:=Cast<AliasDecl>( decl )
		If xdecl And xdecl.genArgs label+="<"+",".Join( xdecl.genArgs )+">"
		
		Local cdecl:=Cast<ClassDecl>( decl )
		If cdecl And cdecl.genArgs label+="<"+",".Join( cdecl.genArgs )+">"
			
		label=label.Replace( "_","\_" )
'		label=label.Replace( "<","\<" )
'		label=label.Replace( ">","\>" )
		
'		If Cast<ClassDecl>( decl ) And decl.IsExtension label+=" Extension"
		
		Return label
	End
	
	Method DeclLink:String( decl:Decl )
	
		Return "[["+DeclDocsIdent( decl )+"|"+DeclLabel( decl )+"]]"
	End
	
	Method DeclDesc:String( decl:Decl )
	
		Local desc:=decl.docs
		
		Local i:=desc.Find( "~n" )
		If i<>-1 desc=desc.Slice( 0,i )
		
		If desc.StartsWith( "@deprecated" )
		
			Local arg:=desc.Slice( 11 ).Trim()
			
			desc="(Deprecated: "+arg+")"
		Endif
		
		Local pdecl:=Cast<PropertyDecl>( decl )
		If pdecl
			local rw:=""
			If pdecl.getFunc And Not pdecl.setFunc
				rw=" _(read only)_"
			Else If pdecl.setFunc And Not pdecl.getFunc
				rw=" _(write only)_"
			Endif
			desc+=rw
		Endif
		
		Return desc
	End
	
	Method EmitHeader( buf:DocsBuffer,decl:Decl,parent:DocsNode )
		
		buf.Emit( "_[["+_module.name+":|"+_module.name+"]]:"+parent.DeclLink+"."+DeclLabel( decl )+"_" )
		
	End
	
	Method DocsVisible:Bool( decl:Decl,access:Int )
	
		If Not (decl.flags & access) return False
	
		If decl.docs.StartsWith( "@hidden" ) Return False
		
		If decl.IsInternal Return False
		
		If decl.IsPublic Return True
		
		Return decl.docs<>Null
	End
	
	Method MakeMemberDocs:DocsNode( scope:Scope,kind:String,access:Int,parent:DocsNode,buf:DocsBuffer )

		Local kinds:=kind+"s"
		If kind.EndsWith( "s" )
			kinds=kind+"es"
		Else If kind.EndsWith( "y" )
			kinds=kind.Slice( 0,-1 )+"ies"
		Endif

		Local tag:=""
		If access & DECL_PUBLIC
			kinds=kinds.Capitalize()
'			tag="Public "
		Else If access & DECL_PROTECTED
			tag="Protected "
		Else If access & DECL_PRIVATE
			tag="Private "
		Endif
		
'		Local kinds:=kind+"s"
'		If kind.EndsWith( "s" )
'			kinds=kind+"es"
'		Else If kind.EndsWith( "y" )
'			kinds=kind.Slice( 0,-1 )+"ies"
'		Endif
		
		Local first:=True,docs:DocsNode
		
		If kind="extension"
			
			Local nmscope:=Cast<NamespaceScope>( scope )
			
			For Local ctype:=Eachin nmscope.classexts
				
				If ctype.transFile.module<>_module Continue
				
				Local decl:=ctype.cdecl
				If Not DocsVisible( decl,DECL_PUBLIC ) Continue
				
				If first
					first=False
					buf.EmitBr()
					buf.Emit( "| Extensions | |" )
					buf.Emit( "|:---|:---|" )
					docs=New DocsNode( "","Extensions",parent,DocsType.Nav )
'					docs=New DocsNode( "Extensions","",parent,DocsType.Nav )
				Endif
				
				buf.Emit( "| "+DeclLink( decl )+" | "+DeclDesc( decl )+" |" )
				
				MakeClassDocs( ctype,docs )
				
			Next
			
			Return docs
			
		Endif

		For Local node:=Eachin scope.nodes
		
			Local xtype:=Cast<AliasType>( node.Value )
			If xtype
				
'				If xtype.scope<>scope continue
				
				Local decl:=xtype.adecl
				If decl.kind<>kind Or Not DocsVisible( decl,access ) Continue

				If first
					first=False
					buf.EmitBr()
					buf.Emit( "| "+tag+kinds+" | |" )
					buf.Emit( "|:---|:---|" )
					docs=New DocsNode( "",tag+kinds,parent,DocsType.Nav )
'					docs=New DocsNode( tag+kinds,"",parent,DocsType.Nav )
				Endif

				buf.Emit( "| "+DeclLink( decl )+" | "+DeclDesc( decl )+" |" )
		
				MakeAliasDocs( xtype,docs )
				
				Continue
			Endif
			
			Local ctype:=Cast<ClassType>( node.Value )
			If ctype
				
'				If ctype.scope<>scope continue
			
				If ctype.transFile.module<>_module Continue
				
				Local decl:=ctype.cdecl
				If decl.kind<>kind Or Not DocsVisible( decl,access ) Continue
				
				If first
					first=False
					buf.EmitBr()
					buf.Emit( "| "+tag+kinds+" | |" )
					buf.Emit( "|:---|:---|" )
					docs=New DocsNode( "",tag+kinds,parent,DocsType.Nav )
'					docs=New DocsNode( tag+kinds,"",parent,DocsType.Nav )
				Endif
				
				buf.Emit( "| "+DeclLink( decl )+" | "+DeclDesc( decl )+" |" )
				
				MakeClassDocs( ctype,docs )
				
				Continue
			Endif
			
			Local etype:=Cast<EnumType>( node.Value )
			If etype
				
'				If etype.scope.outer<>scope Continue
			
				Local decl:=etype.edecl
				If decl.kind<>kind Or Not DocsVisible( decl,access ) Continue
				
				If first
					first=False
					buf.EmitBr()
					buf.Emit( "| "+tag+kinds+" | |" )
					buf.Emit( "|:---|:---|" )
					docs=New DocsNode( "",tag+kinds,parent,DocsType.Nav )
'					docs=New DocsNode( tag+kinds,"",parent,DocsType.Nav )
				Endif
				
				buf.Emit( "| "+DeclLink( decl )+" | "+DeclDesc( decl )+" |" )
				
				MakeEnumDocs( etype,docs )
				
				Continue
			Endif
				
		
			Local plist:=Cast<PropertyList>( node.Value )
			If plist
				
'				If plist.scope<>scope continue
			
				Local decl:=plist.pdecl
				If decl.kind<>kind Or Not DocsVisible( decl,access ) Continue

				If first
					first=False
					buf.EmitBr()
					buf.Emit( "| "+tag+kinds+" | |" )
					buf.Emit( "|:---|:---|" )
					docs=New DocsNode( "",tag+kinds,parent,DocsType.Nav )
'					docs=New DocsNode( tag+kinds,"",parent,DocsType.Nav )
				Endif

				buf.Emit( "| "+DeclLink( decl )+" | "+DeclDesc( decl )+" |" )
				
				MakePropertyDocs( plist,docs )
				
				Continue
			Endif
			
			Local flist:=Cast<FuncList>( node.Value )
			If flist
				
'				If flist.funcs[0].scope<>scope Continue
				
				Local decl:=flist.funcs[0].fdecl
				Local fkind:=decl.ident="new" ? "constructor" Else decl.kind
				If fkind<>kind Or Not DocsVisible( decl,access ) Continue
				
				If first
					first=False
					buf.EmitBr()
					buf.Emit( "| "+tag+kinds+" | |" )
					buf.Emit( "|:---|:---|" )
					docs=New DocsNode( "",tag+kinds,parent,DocsType.Nav )
'					docs=New DocsNode( tag+kinds,"",parent,DocsType.Nav )
				Endif

				buf.Emit( "| "+DeclLink( decl )+" | "+DeclDesc( decl )+" |" )
				
				MakeFuncDocs( flist,docs )
				
				Continue
			Endif
			
			Local vvar:=cast<VarValue>( node.Value )
			If vvar
				
'				If vvar.scope<>scope Continue
			
				If vvar.transFile.module<>_module Continue
			
				Local decl:=vvar.vdecl
				If decl.kind<>kind Or Not DocsVisible( decl,access ) Continue

				If first
					first=False
					buf.EmitBr()
					buf.Emit( "| "+tag+kinds+" | |" )
					buf.Emit( "|:---|:---|" )
					docs=New DocsNode( "",tag+kinds,parent,DocsType.Nav )
'					docs=New DocsNode( tag+kinds,"",parent,DocsType.Nav )
				Endif

				buf.Emit( "| "+DeclLink( decl )+" | "+DeclDesc( decl )+" |" )
				
				MakeVarDocs( vvar,docs )
				
				Continue
			Endif
				
		Next
		
		Return docs
	End

	Method MakeModuleDocs:DocsNode( parent:DocsNode )
		
'		Local docs:=New DocsNode( _module.name,_module.name,parent,DocsType.Decl )
		Local docs:=New DocsNode( _module.name+"-module",_module.name,parent,DocsType.Nav )
'		Local docs:=New DocsNode( "",_module.name,parent,DocsType.Nav )'Decl )
		
		Local buf:=New DocsBuffer( docs,_module.baseDir+"newdocs/" )
		
		buf.Emit( "_"+_module.name+"_" )
		
		Local mpath:=_module.baseDir+"newdocs/module.md"
		
		If GetFileType( mpath )=FileType.File
			
			Local src:=LoadString( mpath )

			buf.Emit( src )
		Endif
		
		buf.Emit( "##### Module "+_module.name )
		
		Local done:=New Map<NamespaceScope,Bool>,first:=True
		
		For Local fscope:=Eachin _module.fileScopes
			
			Local scope:=Cast<NamespaceScope>( fscope.outer )
			If Not scope Continue
			
			If done[scope] Continue
			done[scope]=True
			
			If Not MakeNamespaceDocs( scope,docs ) Continue
			
			If first
				first=False
				buf.EmitBr()
				buf.Emit( "| Namespaces" )
				buf.Emit( "|:---" )
			Endif

			buf.Emit( "| [["+scope.ntype.Name+"|"+scope.ntype.Name+"]]" )

		Next
		
		docs.Markdown=buf.Flush()
		
		Return docs
	End
	
	Method MakeNamespaceDocs:DocsNode( scope:NamespaceScope,parent:DocsNode )
	
		Print "Making namespace docs:"+scope.Name

		Local buf:=New DocsBuffer

		Local docs:=New DocsNode( scope.Name,"",parent,DocsType.Decl )
		
		'EmitHeader
		buf.Emit( "_[["+_module.name+":|"+_module.name+"]]:"+scope.Name+"_" )
		
		buf.Emit( "##### Namespace "+scope.Name )

		MakeMemberDocs( scope,"alias",DECL_PUBLIC,docs,buf )
		MakeMemberDocs( scope,"enum",DECL_PUBLIC,docs,buf )
		MakeMemberDocs( scope,"interface",DECL_PUBLIC,docs,buf )
		MakeMemberDocs( scope,"struct",DECL_PUBLIC,docs,buf )
		MakeMemberDocs( scope,"class",DECL_PUBLIC,docs,buf )
		MakeMemberDocs( scope,"function",DECL_PUBLIC,docs,buf )
		MakeMemberDocs( scope,"global",DECL_PUBLIC,docs,buf )
		MakeMemberDocs( scope,"const",DECL_PUBLIC,docs,buf )
		MakeMemberDocs( scope,"extension",DECL_PUBLIC,docs,buf )
		
		If Not docs.NumChildren 
			docs.Remove()
			Return Null
		Endif
		
		docs.Markdown=buf.Flush()

		Return docs
	End
	
	Method MakeAliasDocs:DocsNode( xtype:AliasType,parent:DocsNode )
	
		Local decl:=xtype.adecl
		
		Local buf:=New DocsBuffer
		
		Local docs:=New DocsNode( DeclDocsIdent( decl ),DeclLabel( decl ),parent,DocsType.Decl )

		EmitHeader( buf,decl,parent )
		
		buf.Emit( "##### "+decl.kind.Capitalize()+" "+DeclLabel( decl ) )
		
		buf.Emit( decl.docs )
				
		docs.Markdown=buf.Flush()
		
		Return docs
	End
	
	Method MakeClassDocs:DocsNode( ctype:ClassType,parent:DocsNode )
		
		Local decl:=ctype.cdecl
		Local scope:=ctype.scope
		
		Local buf:=New DocsBuffer
		
		Local docs:=New DocsNode( DeclDocsIdent( decl ),DeclLabel( decl ),parent,DocsType.Decl )
		
		EmitHeader( buf,decl,parent )
		
		If decl.IsExtension
			
			buf.Emit( "##### "+decl.kind.Capitalize()+" "+decl.ident+" Extension" )
			
		Else
			
			Local xtends:=""
			If ctype.superType And DocsVisible( ctype.superType.cdecl,~0 )
				If ctype.superType<>Type.ObjectClass
					xtends=" Extends "+TypeName( ctype.superType )
				Endif
			Else If ctype.extendsVoid
				xtends=" Extends Void"
			Endif
			
			Local implments:=""
			If decl.ifaceTypes
				Local ifaces:=""
				For Local iface:=Eachin ctype.ifaceTypes
					ifaces+=","+TypeName( iface )
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
			
			buf.Emit( "##### "+decl.kind.Capitalize()+" "+DeclLabel( decl )+xtends+implments+mods )

		Endif
		
		buf.Emit( decl.docs )
		
		MakeMemberDocs( scope,"alias",DECL_PUBLIC,docs,buf )
		MakeMemberDocs( scope,"enum",DECL_PUBLIC,docs,buf )
		MakeMemberDocs( scope,"interface",DECL_PUBLIC,docs,buf )
		MakeMemberDocs( scope,"struct",DECL_PUBLIC,docs,buf )
		MakeMemberDocs( scope,"class",DECL_PUBLIC,docs,buf )
		MakeMemberDocs( scope,"const",DECL_PUBLIC,docs,buf )
		MakeMemberDocs( scope,"field",DECL_PUBLIC,docs,buf )
		MakeMemberDocs( scope,"constructor",DECL_PUBLIC,docs,buf )
		MakeMemberDocs( scope,"property",DECL_PUBLIC,docs,buf )
		MakeMemberDocs( scope,"method",DECL_PUBLIC,docs,buf )
		MakeMemberDocs( scope,"function",DECL_PUBLIC,docs,buf )
		
		MakeMemberDocs( scope,"alias",DECL_PROTECTED,docs,buf )
		MakeMemberDocs( scope,"enum",DECL_PROTECTED,docs,buf )
		MakeMemberDocs( scope,"interface",DECL_PROTECTED,docs,buf )
		MakeMemberDocs( scope,"struct",DECL_PROTECTED,docs,buf )
		MakeMemberDocs( scope,"class",DECL_PROTECTED,docs,buf )
		MakeMemberDocs( scope,"const",DECL_PROTECTED,docs,buf )
		MakeMemberDocs( scope,"field",DECL_PROTECTED,docs,buf )
		MakeMemberDocs( scope,"constructor",DECL_PROTECTED,docs,buf )
		MakeMemberDocs( scope,"property",DECL_PROTECTED,docs,buf )
		MakeMemberDocs( scope,"method",DECL_PROTECTED,docs,buf )
		MakeMemberDocs( scope,"function",DECL_PROTECTED,docs,buf )
		
		docs.Markdown=buf.Flush()
		
		Return docs
	End
	
	Method MakeEnumDocs:DocsNode( etype:EnumType,parent:DocsNode )
	
		Local decl:=etype.edecl

		Local docs:=New DocsNode( DeclDocsIdent( decl ),DeclLabel( decl ),parent,DocsType.Decl )
		
		Local buf:=New DocsBuffer
		
		EmitHeader( buf,decl,parent )

		buf.Emit( "##### "+decl.kind.Capitalize()+" "+DeclLabel( decl ) )
		
		buf.Emit( decl.docs )
	
		docs.Markdown=buf.Flush()
		
		For Local node:=Eachin etype.scope.nodes
			
			local val:=Cast<LiteralValue>( node.Value )
			If Not val Continue
			
'			Local edocs:=New DocsNode( node.Key,node.Key,docs,DocsType.Decl,True )
			Local edocs:=New DocsNode( node.Key,node.Key,docs,DocsType.Decl,True )

		Next
		
		Return docs
	End
	
	Method MakePropertyDocs:DocsNode( plist:PropertyList,parent:DocsNode )
	
		Local decl:=plist.pdecl

		Local docs:=New DocsNode( DeclDocsIdent( decl ),DeclLabel( decl ),parent,DocsType.Decl )
		
		Local buf:=New DocsBuffer
		
		EmitHeader( buf,decl,parent )
		
		buf.Emit( "##### "+decl.kind.Capitalize()+" "+DeclLabel( decl )+":"+TypeName( plist.type ) )
		
		buf.Emit( decl.docs )
	
		docs.Markdown=buf.Flush()
		
		Return docs
	End

	Method MakeFuncDocs:DocsNode( flist:FuncList,parent:DocsNode )
	
		Local decl:=flist.funcs[0].fdecl
	
		Local docs:=New DocsNode( DeclDocsIdent( decl ),DeclLabel( decl ),parent,DocsType.Decl )
	
		Local buf:=New DocsBuffer
		
		EmitHeader( buf,decl,parent )
		
		For Local pass:=0 Until 2
		
			For Local func:=Eachin flist.funcs
			
				Local decl:=func.fdecl
				
				If Not DocsVisible( decl,~0 ) continue
				
				If pass=0
				
					Local params:=""
					
					For Local i:=0 Until func.ftype.argTypes.Length
						Local ident:=func.fdecl.type.params[i].ident
						Local type:=TypeName( func.ftype.argTypes[i] )
						Local init:=""
						If func.fdecl.type.params[i].init
							init="="+func.fdecl.type.params[i].init.ToString()
						Endif
						If params params+=","
						params+=ident+":"+type+init
					Next

					If decl.IsOperator
						buf.Emit( "##### "+DeclLabel( decl )+":"+TypeName( func.ftype.retType )+"( "+params+" )" )
					Else
						buf.Emit( "##### "+decl.kind.Capitalize()+" "+DeclLabel( decl )+":"+TypeName( func.ftype.retType )+"( "+params+" )" )
					endif
					
				Else
				
					buf.Emit( decl.docs )
					
				Endif
				
			Next
			
		Next
		
		docs.Markdown=buf.Flush()
		
		Return docs
	End
	
	Method MakeVarDocs:DocsNode( vvar:VarValue,parent:DocsNode )
	
		Local decl:=vvar.vdecl
	
		Local docs:=New DocsNode( DeclDocsIdent( decl ),DeclLabel( decl ),parent,DocsType.Decl )
		
		Local buf:=New DocsBuffer
		
		EmitHeader( buf,decl,parent )
		
		buf.Emit( "#### "+decl.kind.Capitalize()+" "+DeclLabel( decl )+":"+TypeName( vvar.type ) )
	
		buf.Emit( decl.docs )
		
		docs.Markdown=buf.Flush()
		
		Return docs
	End
	
End
