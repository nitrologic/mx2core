
Namespace mx2.newdocs

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
					
					Local docs:=New DocsNode( "","",_docs,DocsType.Nav,True )
					
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
				Local ident:=label.Replace( " ","-" ).ToLower()
				
				Local docs:=New DocsNode( ident,label,_docs,DocsType.Hash )
				
				EmitLine( "<a name='"+ident+"'></a>" )
				
				EmitLine( tag+" "+arg )
				
				
			Case "manpage"
				
				Local label:=arg
				Local ident:=label.Replace( " ","-" ).ToLower()
				
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
					
					Local docs:=New DocsNode( "","",_docs,DocsType.Nav,True )
					
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

