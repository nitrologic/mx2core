
Namespace mx2.newdocs

Enum DocsType
	Root=0
	Decl=1
	Hash=2
	Dir=3
	Nav=4
End

Class DocsNode
	
	Method New( ident:String,label:String,parent:DocsNode,type:DocsType,clean:Bool=False )

		_ident=ident
		_label=label ? label Else ident
		_parent=parent
		_type=type
		_clean=clean

		If _parent _parent._children.Add( Self )
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
	
	Property ParentDecl:DocsNode()
		
		If Not _parent Return Null
		
		If _parent._type<>DocsType.Decl Return _parent.ParentDecl
		
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
	
	Property FilePath:String()
		
		Local path:=_parent ? _parent.FilePath Else ""
		
		Select _type
		Case DocsType.Root
			
			Return _ident
			
		Case DocsType.Decl,DocsType.Hash
			
			If path And Not path.EndsWith( "/" ) path+=_type=DocsType.Hash ? "#" Else "-"
			
			Return path+_ident.Replace( ".","-" )
			
		Case DocsType.Dir
			
			If path And Not path.EndsWith( "/" ) path+="/"
				
			Return path+_ident+"/"
			
		Case DocsType.Nav
			
			Return path
			
		End
		
		Return ""
	End
	
	Property FilePathUrl:String()
		
		If _type=DocsType.Nav Return _parent ? _parent.FilePath+_ident+".html" Else _ident+".html"
		
		Local url:=FilePath
			
		Local i:=url.Find( "#" )
		If i<>-1
			url=url.Slice( 0,i )+".html"+url.Slice( i )
		Else
			url+=".html"
		Endif
		
		Return url
	End
	
	Property DeclPath:String()

		Local path:=_parent ? _parent.DeclPath Else ""
		
		Select _type
			
		Case DocsType.Decl,DocsType.Hash
			
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
	
	Method Find:DocsNode( path:String )
		
		Local done:=New Map<DocsNode,Bool>
		
		Return Find( path,done )
	End
	
	Method Find:DocsNode( path:String,done:Map<DocsNode,Bool> )
		
		If done[Self] Return Null
		done[Self]=True
		
		Local found:DocsNode,declPath:=""
	
 		For Local child:=Eachin _children
 		
 			Local docs:=child.Find( path,done )
 			If Not docs Continue
 			
 			Local path:=docs.DeclPath
 			If Not found Or path.Length<declPath.Length
	 			declPath=path
	 			found=docs
	 		Endif

 		Next
 		
 		If found Return found
 		
 		Select _type
 		
 		Case DocsType.Decl,DocsType.Hash
		
			Local declPath:=DeclPath
			
			If declPath=path Or declPath.EndsWith( "."+path ) Return Self
		
		End
		
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
		
		If _clean
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

	Field _ident:String
	Field _label:String
	Field _parent:DocsNode
	Field _type:DocsType
	Field _clean:Bool
	
	Field _children:=New Stack<DocsNode>
	Field _markdown:String
	
End
