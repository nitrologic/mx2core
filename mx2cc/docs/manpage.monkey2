
Namespace mx2.docs

Class ManPage

	Class Node

		Field indent:Int
		Field parent:Node
		Field children:=New Stack<Node>
		Field page:ManPage
		Field text:String
		Field slug:String
		
		Method New( indent:Int,parent:Node,page:ManPage )
			Self.indent=indent
			Self.parent=parent
			Self.page=page
			If parent parent.children.Push( Self )
		End
		
		Method SetParent( node:Node )
		
			If parent parent.children.Remove( Self )
			
			If text
				parent=node
				If parent parent.children.Add( Self )
				Return
			Endif
			
			parent=Null
			While Not children.Empty
				children.Top.SetParent( node )
			Wend
		End
		
		Method ToJson:JsonObject( baseDir:String )
		
			Local jobj:=New JsonObject
			jobj["text"]=New JsonString( text )

			Local jdata:=New JsonObject
			jdata["page"]=New JsonString( page.Page+"#"+slug )
			jobj["data"]=jdata

			If children.Length
				Local jchildren:=New JsonArray
				For Local child:=Eachin children
					jchildren.Push( child.ToJson( baseDir ) )
				Next
				jobj["children"]=jchildren
			Endif
			
			Return jobj
			
		End

	End
	
	Property Path:String()
	
		Return _path
	End
	
	Property Page:String()
	
		Return _page
	End
	
	Property RootNode:Node()
	
		Return _root
	End
	
	Property HtmlSource:String()
	
		Return _html
	End
	
	Function ImportManPage:Node( path:String,module:Module,linkResolver:MarkdownBuffer.LinkResolver,pages:StringMap<ManPage> )
	
		Local page:=New ManPage
		pages[path]=page
		
		Local root:=New Node( 0,Null,page )
		Local node:=root
		
		page._path=module.baseDir+"docs/__MANPAGES__/"+StripDir( path )+".html"
		page._page=module.name+":"+StripDir( StripExt( path ) )
		page._root=root

		Local md:=New MarkdownBuffer( ExtractDir( path ),linkResolver,Lambda:Bool( tag:String,arg:String )
		
			Select tag
			Case "manpage"
			
				If root.text Or root.children.Length
					Print "Makedocs error: @manpage must appear at top of file"
					Return True
				Endif
				
				root.text=arg
				
				Return True
				
			Case "import"
			
				If arg.Length>1 And arg.StartsWith( "~q" ) And arg.EndsWith( "~q" ) arg=arg.Slice( 1,-1 )
				
				If Not ExtractRootDir( arg ) arg=ExtractDir( path )+arg
				
				Local node:=ImportManPage( arg,module,linkResolver,pages )
				
				node.SetParent( root )
				
				Return True
			End
			
			Return False
		
		End )
		
		Local text:=LoadString( path )
		Local lines:=text.Split( "~n" )
		
		Local buf:=New StringStack
		
		Local code:=False
		
		For Local i:=0 Until lines.Length
		
			Local line:=lines[i]
			
			If line.StartsWith( "```" )
				code=Not code
				buf.Push( line )
				Continue
			Else If code
				buf.Push( line )
				Continue
			Endif

			If Not line.StartsWith( "#" )
				buf.Push( line )
				Continue
			Endif
			
			If Not buf.Empty
				md.Emit( buf.ToArray() )
				buf.Clear()
			Endif
			
			Local j:=1 
			While j<line.Length And line[j]=35	'#
				j+=1
			Wend

			Local text:=line.Slice( j ).Trim()
			If Not text Continue
			
			While j<node.indent
				node=node.parent
			Wend
						
			If j>node.indent
				node=New Node( j,node,page )
			Else
				node=New Node( j,node.parent,page )
			Endif

			node.text=text
			node.slug=Slugify( text )
			
			buf.Push( "<h"+j+" id=~q"+node.slug+"~q>"+text+"</h"+j+">" )
		Next
		
		If Not buf.Empty
			md.Emit( buf.ToArray() )
			buf.Clear()
		Endif
		
		page._html=md.Flush()
		
		Return root
	End
	
	Function MakeManPages:StringMap<ManPage>( path:String,module:Module,linkResolver:MarkdownBuffer.LinkResolver )
	
		Local pages:=New StringMap<ManPage>
		
		ImportManPage( path,module,linkResolver,pages )
		
		Return pages
	End
	
	Private
	
	Field _root:Node
	Field _path:String
	Field _page:String	
	Field _html:String

End
