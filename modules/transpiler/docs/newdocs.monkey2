
Namespace mx2.docs

Enum DocsType
	Root=0
	Decl=1
	Dir=2
	Nav=3
End

Class DocsNode
	
	Method New( ident:String,label:String,parent:DocsNode,type:DocsType )

		_ident=ident
		_label=label ? label Else ident
		_parent=parent
		_type=type

		If _parent _parent._children.Add( Self )
	End
	
	Property Hash:Bool()
		
		Return _hash
	
	Setter( hash:Bool )
		
		_hash=hash
	End
	
	Property Ident:String()
	
		Return _ident
	End
	
	Property Label:String()
	
		Return _label
	End
	
	Property Parent:DocsNode()
	
'		If _type=DocsType.Nav Return _parent ? _parent.Parent Else Null
	
		Return _parent
	End
	
	Property Children:DocsNode[]()
	
		Return _children.ToArray()
	End
	
	Property NumChildren:Int()
	
		Return _children.Length
	End
	
	Property Type:DocsType()
		
		Return _type
	End
	
	Property Markdown:String()
	
		Return _markdown
		
	Setter( markdown:String )
	
		_markdown=markdown
	End
	
	#rem
	Property Path:String()
		
		If _type=DocsType.Dir Return ""
		
		If _type=DocsType.Nav Return _parent ? _parent.Path Else ""
		
		Local path:=_parent ? _parent.Path Else ""
		
		Return path ? path+(_hash ? "#" Else ".")+_ident Else _ident
	End
	#end
	
	'eg: module/
	Property FilePath:String()
		
		Local path:=_parent ? _parent.FilePath Else ""
		
		Select _type
		Case DocsType.Root
			
			Return _ident
			
		Case DocsType.Decl
			
			If path And Not path.EndsWith( "/" ) path+="-"
			
			Return path+_ident.Replace( ".","-" )

		Case DocsType.Dir
			
			If path And Not path.EndsWith( "/" ) path+="/"
				
			Return path+_ident+"/"
		
		Case DocsType.Nav
			
			Return path
			
		End
		
		Return ""
	End
	
	Property DeclPath:String()

		Local path:=_parent ? _parent.DeclPath Else ""
		
		Select _type
			
		Case DocsType.Decl
			
			If path path+="."
				
			Return path+_ident
		
		Case DocsType.Nav
			
			Return path
		End
		
		Return ""
		
	End
	
	Property DeclLink:String()
		
		Local path:=_parent ? _parent.DeclLink Else ""
		
		Select _type
			
		Case DocsType.Decl
			
			If path path+="."
				
			Return path+"[["+DeclPath+"|"+_label+"]]"
		
		Case DocsType.Nav
			
			Return path
		End
		
		Return ""
	End
	
	Method FindChild:DocsNode( path:String,found:Bool )
	
		If _type<>DocsType.Nav
			
			If path=_ident Return Self
			
			If path.Contains( "." ) And path.StartsWith( _ident+"." )
				
				path=path.Slice( _ident.Length+1 )
				
				found=True
				
			Else If found
				
				Return Null
				
			Endif
						
		Endif
		
		For Local child:=Eachin _children
			
			Local docs:=child.FindChild( path,found )
			
			If docs Return docs
		Next

		Return Null
	End
	
	Method Find:DocsNode( path:String,done:Map<DocsNode,Bool> =null )	
		
		For Local child:=Eachin _children
			If done And done.Contains( child ) Continue
			
			Local docs:=child.FindChild( path,False )
			If docs Return docs
	
		Next
		
		Local docs:=FindChild( path,false )
		If docs Return docs
		
		If Not done done=New Map<DocsNode,Bool>
		
		If _parent Return _parent.Find( path,done )
		
		Return Null
	End
	
	Method Remove()
		
		If Not _parent Return
		
		For Local child:=Eachin _children
			_parent._children.Add( child )
			child._parent=_parent
		Next
		
		_parent._children.Remove( Self )
		_parent=Null
	End
	
	Method Clean()
		
		For Local child:=Eachin Children
			child.Clean()
		Next
		
		If Not _ident
			Remove()
		Endif
	End

	Method Debug()
		Print FilePath
		For Local child:=Eachin _children
			child.Debug()
		Next
	End
	
	Private

	Field _hash:bool
	Field _ident:String
	Field _label:String
	Field _parent:DocsNode
	Field _type:DocsType
	
	Field _children:=New Stack<DocsNode>
	Field _markdown:String
	
End

Class DocsBuffer
	
	Method New()
		
	End
	
	Method New( docs:DocsNode,baseDir:String )
		
		_docs=docs
		
		_baseDir=baseDir
		
	End
	
	Method EmitBr()
		
		EmitLine( "" )
	End
	
	Method Emit( docs:String )
	
		Local lines:=docs.Split( "~n" )

		EmitLines( lines )
	End
	
	Method EmitLine( line:String )
		
		line=line.Trim()
		
		If Not line And _lines.Length And Not _lines.Top Return
		
		_lines.Push( line )
	End
	
	Method EmitLines( lines:String[] )
				
		Local i:=0
		
		While i<lines.Length
		
			Local line:=lines[i].Trim()
			i+=1
			
			If Not line.StartsWith( "@" )
				EmitLine( line )
				Continue
			Endif
			
			Local j:=line.Find( " " )
			If j=-1 j=line.Length
			
			Local tag:=line.Slice( 1,j )
			Local arg:=line.Slice( j+1 ).Trim()
			
			Select tag
			Case "deprecated"
				
				Emit( "(Deprecated: "+arg+")" )
				
			Case "label"
			
				_label=arg
				
			Case "param"
			
				_params.Push( arg )
				
			Case "return"
			
				_return=arg
				
			Case "import"
				
				Local path:=_baseDir+arg
				
				Local src:=LoadString( path )
				
				If src
'					Print "Importing "+path
					
					Local docs:=New DocsNode( "","",_docs,DocsType.Nav )
					
					Local buf:=New DocsBuffer( docs,ExtractDir( path ) )
					
					buf.Emit( src )
					
					docs.Markdown=buf.Flush()
				Else
					Print "DocsBuffer: Can't @import file '"+path+"'"
				Endif
			
			Case "example"

				EmitLine( "```" )
				
				Local i0:=i
				While i<lines.Length And lines[i].Trim()<>"@end"
					
					EmitLine( lines[i] )
					i+=1
				Wend
				
'				FixIndent( i0,i )

				EmitLine( "```" )

				If i<lines.Length i+=1
					
			Case "#","##","###","####","#####"
				
				Local label:=arg
				Local ident:=label.Replace( " ","_" )
				
				EmitLine( "<a name='"+ident+"'></a>" )
				
				EmitLine( tag+" "+arg )
				
				Local docs:=New DocsNode( ident,label,_docs,DocsType.Decl )
				
				docs.Hash=True
				
			Case "manpage"
				
				Local label:=arg
				Local ident:=label.Replace( " ","_" )
				
				Local docs:=New DocsNode( ident,label,_docs,DocsType.Decl )
				
				Local buf:=New DocsBuffer( docs,_baseDir )
				
				buf.EmitLines( lines.Slice( i ) )
				
				docs.Markdown=buf.Flush()
				
				i=lines.Length
				
			Case "import"
				
				Local path:=_baseDir+arg
				
				Local src:=LoadString( path )
				
				If src
'					Print "Importing "+path
					
					Local docs:=New DocsNode( "","",_docs,DocsType.Nav )
					
					Local buf:=New DocsBuffer( docs,ExtractDir( path ) )
					
					buf.Emit( src )
					
					docs.Markdown=buf.Flush()
				Else
					Print "DocsBuffer: Can't @import file '"+path+"'"
				Endif
				
			Default
			
				Print "DocsBuffer error: tag='"+tag+"' line='"+lines[i-1]+"'"
			
			End
			
			
		Wend
	End
	
	Method Flush:String()
	
		If _params.Length	
		
			EmitBr()
			Emit( "| Parameters |    |" )
			Emit( "|:-----------|:---|" )
			
			For Local p:=Eachin _params
			
				Local i:=p.Find( " " )
				If i=-1 Continue
				
				Local id:=p.Slice( 0,i )
				Local docs:=p.Slice( i ).Trim()
				If Not docs Continue
				
				Emit( "| `"+id+"` | "+p+" |" )
			Next
			
			_params.Clear()
			
		Endif
		
		Local markdown:=_lines.Join( "~n" ).Trim()+"~n"
		
		_lines.Clear()
		_label=""
		_return=""
		
		Return markdown
	End
	
	Private
	
	Field _docs:DocsNode
	field _baseDir:String
	Field _lines:=New StringStack
	Field _label:String
	Field _params:=New StringStack
	Field _return:String
	
	Method FixIndent( i0:Int,i1:Int )
		
		Local indent:=10000
		
		For Local i:=i0 Until i1
			Local line:=_lines[i],j:=0
			While j<line.Length
				If line[j]>32 Exit
				j+=1
			Wend
			indent=Min( indent,j )
		Next
		
		If indent=10000 indent=0
			
		For Local i:=i0 Until i1
			_lines[i]=_lines[i].Slice( indent )
		Next
	
	End
End

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
		
		Local done:=New Map<NamespaceScope,Bool>
		
		'Create docs tree
		
		For Local fscope:=Eachin _module.fileScopes
			
			Local scope:=Cast<NamespaceScope>( fscope.outer )
			If Not scope Continue
			
			If done[scope] Continue
			
			MakeNamespaceDocs( scope,modDocs )
			
			done[scope]=True
		Next
		
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
		
		SaveString( tree,dir+"index.js" )
	End
		
	Method CreateJSNavTree( docs:DocsNode,buf:StringStack,indent:String,dir:String )
		
		buf.Add( indent+"{text:'"+docs.Label+"'" )
		
		Select docs.Type
			
		Case DocsType.Decl
			
			Local url:=dir+docs.FilePath+".html"
		
			buf.Add( ",data:{page:'"+url+"'}")
		
		End
		
		Local children:=docs.Children
		
		If children
		
			buf.Add( ",children:[~n" )

			local first:=True			
			For Local child:=Eachin children
				If Not first buf.Add( ",~n" )
				CreateJSNavTree( child,buf,indent+"  ",dir )
				first=False
			Next
			
			buf.Add( indent+"]~n" )
		
		Endif

		buf.Add( indent+"}" )
		
	End
	
	Method CreateHtmlPages( docs:DocsNode,dir:String )
		
		Select docs.Type
			
		Case DocsType.Decl
			
			_converting=docs
			
			Local html:=_convertor.ConvertToHtml( docs.Markdown )
			
			_converting=Null
			
			If _pageTemplate html=_pageTemplate.Replace( "${CONTENT}",html )
	
			Local path:=dir+docs.FilePath+".html"
			
			SaveString( html,path )
			
		Case DocsType.Dir
			
			Local path:=dir+docs.FilePath
			
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
			Local modname:=link.Slice( 0,i )
			Local slug:=link.Slice( i+1 ).Replace( ".","-" )
'			Local url:="file://"+_docsDir+"modules/"+modname+"/module/"+slug+".html"
			Local url:="../../"+modname+"/module/"+slug+".html"
			Local anchor:="<a href='"+url+"'>"+name+"</a>"
			Return anchor
		Endif
		
		Const monkeyTypes:="inumeric,iintegral,ireal,bool,byte,ubyte,short,ushort,int,uint,long,ulong,float,double,string,cstring,ovariant,typeinfo,declinfo,array,object,throwable"
		
		Local docs:=_converting.Find( link )
		If Not docs
			Print "Link not found:"+link+" while converting docs:"+_converting.FilePath
			Return name
		Endif
		
		Local url:="../"+docs.FilePath+".html"
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
			If Not name name=ctype.Name
			Local cname:=DeclIdent( ctype.cdecl )'ctype.Name.ToLower()
			return "[[monkey.types."+cname+"|"+name+"]]"
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
			
			Local module:=ctype.transFile.module
			
			Local path:=type.Name
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

		Local ident:=decl.ident.Replace( "@","" )
		
		If Not IsIdent( ident[0] ) ident="Op"+OpSym( ident ).Slice( 1 ).Capitalize()
	
		Return ident
	End
	
	Method DeclLabel:String( decl:Decl )
	
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
		
		Local xdecl:=Cast<AliasDecl>( decl )
		If xdecl And xdecl.genArgs label+="<"+",".Join( xdecl.genArgs )+">"
		
		Local cdecl:=Cast<ClassDecl>( decl )
		If cdecl And cdecl.genArgs label+="<"+",".Join( cdecl.genArgs )+">"
			
		label=label.Replace( "_","\_" )
'		label=label.Replace( "<","\<" )
'		label=label.Replace( ">","\>" )
		
		
		Return label
	End
	
	Method DeclLink:String( decl:Decl )
	
		Return "[["+DeclIdent( decl )+"|"+DeclLabel( decl )+"]]"
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
		
		buf.Emit( "_"+_module.name+":"+parent.DeclLink+"."+DeclLabel( decl )+"_" )
	End
	
	Method DocsVisible:Bool( decl:Decl,access:int )
	
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
					docs=New DocsNode( tag+kinds,"",parent,DocsType.Nav )
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
					docs=New DocsNode( tag+kinds,"",parent,DocsType.Nav )
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
					docs=New DocsNode( tag+kinds,"",parent,DocsType.Nav )
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
					docs=New DocsNode( tag+kinds,"",parent,DocsType.Nav )
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
					docs=New DocsNode( tag+kinds,"",parent,DocsType.Nav )
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
					docs=New DocsNode( tag+kinds,"",parent,DocsType.Nav )
				Endif

				buf.Emit( "| "+DeclLink( decl )+" | "+DeclDesc( decl )+" |" )
				
				MakeVarDocs( vvar,docs )
				
				Continue
			Endif
				
		Next
		
		Return docs
	End
	
	Method MakeNamespaceDocs:DocsNode( scope:NamespaceScope,parent:DocsNode )
	
		Print "Making namespace docs:"+scope.Name

		Local buf:=New DocsBuffer

		Local docs:=New DocsNode( scope.Name,"",parent,DocsType.Decl )
		
		'EmitHeader
		buf.Emit( "_"+_module.name+":"+scope.Name+"_" )
		
		buf.Emit( "##### Namespace "+scope.Name )

		MakeMemberDocs( scope,"alias",DECL_PUBLIC,docs,buf )
		MakeMemberDocs( scope,"enum",DECL_PUBLIC,docs,buf )
		MakeMemberDocs( scope,"interface",DECL_PUBLIC,docs,buf )
		MakeMemberDocs( scope,"struct",DECL_PUBLIC,docs,buf )
		MakeMemberDocs( scope,"class",DECL_PUBLIC,docs,buf )
		MakeMemberDocs( scope,"function",DECL_PUBLIC,docs,buf )
		MakeMemberDocs( scope,"global",DECL_PUBLIC,docs,buf )
		MakeMemberDocs( scope,"const",DECL_PUBLIC,docs,buf )
		
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
		
		Local docs:=New DocsNode( DeclIdent( decl ),DeclLabel( decl ),parent,DocsType.Decl )

		EmitHeader( buf,decl,parent )
		
		buf.Emit( "##### "+decl.kind.Capitalize()+" "+DeclIdent( decl ) )
		
		buf.Emit( decl.docs )
				
		docs.Markdown=buf.Flush()
		
		Return docs
	End
	
	Method MakeClassDocs:DocsNode( ctype:ClassType,parent:DocsNode )
		
		Local decl:=ctype.cdecl
		Local scope:=ctype.scope
		
		Local buf:=New DocsBuffer
		
		Local docs:=New DocsNode( DeclIdent( decl ),DeclLabel( decl ),parent,DocsType.Decl )
		
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

		Local docs:=New DocsNode( DeclIdent( decl ),DeclLabel( decl ),parent,DocsType.Decl )
		
		Local buf:=New DocsBuffer
		
		EmitHeader( buf,decl,parent )

		buf.Emit( "##### "+decl.kind.Capitalize()+" "+DeclIdent( decl ) )
		
		buf.Emit( decl.docs )
	
		docs.Markdown=buf.Flush()
		
		For Local node:=Eachin etype.scope.nodes
			
			local val:=Cast<LiteralValue>( node.Value )
			If Not val Continue
			
			Local edocs:=New DocsNode( node.Key,node.Key,docs,DocsType.Decl )

		Next
		
		Return docs
	End
	
	Method MakePropertyDocs:DocsNode( plist:PropertyList,parent:DocsNode )
	
		Local decl:=plist.pdecl

		Local docs:=New DocsNode( DeclIdent( decl ),DeclLabel( decl ),parent,DocsType.Decl )
		
		Local buf:=New DocsBuffer
		
		EmitHeader( buf,decl,parent )
		
		buf.Emit( "##### "+decl.kind.Capitalize()+" "+DeclIdent( decl )+":"+TypeName( plist.type ) )
		
		buf.Emit( decl.docs )
	
		docs.Markdown=buf.Flush()
		
		Return docs
	End

	Method MakeFuncDocs:DocsNode( flist:FuncList,parent:DocsNode )
	
		Local decl:=flist.funcs[0].fdecl
	
		Local docs:=New DocsNode( DeclIdent( decl ),DeclLabel( decl ),parent,DocsType.Decl )
	
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
	
		Local docs:=New DocsNode( DeclIdent( decl ),DeclLabel( decl ),parent,DocsType.Decl )
		
		Local buf:=New DocsBuffer
		
		EmitHeader( buf,decl,parent )
		
		buf.Emit( "#### "+decl.kind.Capitalize()+" "+DeclLabel( decl )+":"+TypeName( vvar.type ) )
	
		buf.Emit( decl.docs )
		
		docs.Markdown=buf.Flush()
		
		Return docs
	End
	
End
