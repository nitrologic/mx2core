
Namespace mx2.docs

Function FindSpc:Int( str:String )
	For Local i:=0 Until str.Length
		If str[i]<=32 Return i
	Next
	Return str.Length
End

Function FindNonSpc:Int( str:String )
	For Local i:=0 Until str.Length
		If str[i]>32 Return i
	Next
	Return -1
End

Function Slugify:String( str:String )
	Local st:=0
	While st<str.Length And Not IsIdent( str[st] )
		st+=1
	Wend
	Local en:=str.Length
	While en>st And Not IsIdent( str[en-1] )
		en-=1
	Wend
	Local out:=""
	For Local i:=st Until en
		Local chr:=str[i]
		If IsIdent( chr )
			out+=String.FromChar( chr ).ToLower()
			Continue
		Endif
		out+="-"
	Next
	Return out
End

Class MarkdownBuffer

	Alias LinkResolver:String( link:String,name:String )

	Alias TagHandler:Bool( tag:String,arg:String )
	
	Method New( url:String )
	End

	Method New( currentDir:String,linkResolver:LinkResolver=Null,tagHandler:TagHandler=Null )
		_currentDir=currentDir
		_linkResolver=linkResolver
		_tagHandler=tagHandler
	End
	
	Property CurrentDir:String()
	
		Return _currentDir
	
	Setter( currentDir:String )

		_currentDir=currentDir
	End
	
	Property Label:String()
	
		Return _label
	End
	
	Method Emit( line:String )
	
		If Not line.Contains( "~n" )
			_buf.Push( ReplaceLinks( line ) )
			Return
		Endif
		
		Emit( line.Split( "~n" ) )
	End

	Method Emit( lines:String[],indent:Int=0 )
	
		Local i:=0
		While i<lines.Length
		
			Local line:=lines[i].Slice( indent )
			i+=1
			
			If Not line.StartsWith( "@" )
				Emit( line )
				Continue
			Endif
			
			Local j:=FindSpc( line )
			Local tag:=line.Slice( 1,j )
			Local arg:=line.Slice( j ).Trim()
				
			Select tag
			Case "label"
			
				_label=arg
				
			Case "param"
			
				_params.Push( arg )
				
			Case "return"
			
				_return=arg
				
			Case "example"
			
				_buf.Push( "```" )
				
				While i<lines.Length
				
					Local line:=lines[i]
					i+=1
					
					If line.Trim()="@end" Exit
					
					line=line.Slice( indent )
					
					If line.StartsWith( "#" ) line="\"+line
					
					_buf.Push( line )
				Wend
				
				_buf.Push( "```" )
				
			Case "deprecated"
			
				_buf.Push( "(Deprecated: "+arg+")" )
			
			Case "include"
			
				If arg.Length>1 And arg.StartsWith( "~q" ) And arg.EndsWith( "~q" ) arg=arg.Slice( 1,-1 )
				
				Local path:=_currentDir+arg
				
				Local text:=stringio.LoadString( path )
				If Not text
					Print "Failed to @include '"+path+"'"
					Continue
				Endif
				
				Select ExtractExt( arg ).ToLower()
				Case ".monkey2"
				
					_buf.Push( "<a href=~q${CD}/"+arg+"~q class=~qnostyle~q>~n" )
					_buf.Push( "```" )
					_buf.Push( text )
					_buf.Push( "```" )
					_buf.Push( "~n</a>" )
					
				Case ".html"
				
					_buf.Push( text )
					
				Case ".txt"
				
					_buf.Push( "```" )
					
					_buf.Push( text )
					
					_buf.Push( "```" )
					
				Case ".md"
				
					Emit( text )
					
				Default
					Print "Unrecognized @include file type '"+ExtractExt( arg )+"'"
				End
			
			Default
			
				If Not _tagHandler( tag,arg )
					Print "MarkdownBuffer: unrecognized directive @"+tag+" in "+line
				Endif

			End

		Wend
	
	End
	
	Method EmitBr()
	
		_buf.Push( "" )
	End
	
	Method Flush:String()

		If _params.Length	
		
			EmitBr()
			Emit( "| Parameters |    |" )
			Emit( "|:-----------|:---|" )
			
			For Local p:=Eachin _params
			
				Local i:=FindSpc( p )
				Local id:=p.Slice( 0,i )
				p=p.Slice( i ).Trim()
				
				If Not id Or Not p Continue
				
				Emit( "| `"+id+"` | "+p+" |" )
			Next
			
			_params.Clear()
			
		Endif
		
		Local markdown:=_buf.Join( "~n" ).Trim()+"~n"
		
		_buf.Clear()
		_return=""
		_label=""
		
		Local docs:=minimarkdown.MarkdownToHtml( markdown )
		
		Return docs
	End
	
	Private
	
	Class Node
		Field indent:Int
		Field parent:Node
		Field children:=New Stack<Node>
		Field slug:String
		Field url:String	'starts with module name eg: "monkey/"
		
		Method New( indent:Int=0,parent:Node=Null )
			Self.indent=indent
			Self.parent=parent
			If parent parent.children.Push( Self )
		End
	End

	Field _currentDir:String	
	Field _linkResolver:LinkResolver
	Field _tagHandler:TagHandler
	
	Field _nodeStack:Stack<Node>
	
	Field _buf:=New StringStack
	Field _params:=New StringStack
	Field _return:String
	Field _label:String
	
	Method ReplaceLinks:String( line:String )
	
		Repeat
			Local i0:=line.Find( "[[" )
			If i0=-1 Return line
			
			Local i1:=line.Find( "]]",i0+2 )
			If i1=-1 Return line
			
			Local link:=line.Slice( i0+2,i1 ),name:=""
			Local i:=link.Find( "|" )
			If i<>-1
				name=link.Slice( i+1 )
				link=link.Slice( 0,i )
			Endif
			
			If _linkResolver<>Null 
				link=_linkResolver( link,name )
			Else If name
				link=name
			Endif
			
			line=line.Slice( 0,i0 )+link+line.Slice( i1+2 )
		Forever
		
		Return line
	End

End

