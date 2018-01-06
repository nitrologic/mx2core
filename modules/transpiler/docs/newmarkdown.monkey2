
Namespace mx2.docs

Class MarkdownConvertor

	Alias LinkResolver:String( link:String,name:String )

	Method New( linkResolver:LinkResolver )
	
		_linkResolver=linkResolver
	End
	
	Method ConvertToHtml:String( source:String )
	
		_source=source
		
		_lines=_source.Split( "~n" )

		_lineNum=0

		_buf.Clear()
		
		For Local i:=0 Until _lines.Length
	
			_lines[i]=_lines[i].TrimEnd()
		Next
		
		While Not AtEnd
		
			Local line:=NextLine()
		
			If line.StartsWith( "#" )
			
				EmitHeader( line )
			
			Else If line.StartsWith( "|" )
			
				EmitTable( line )
				
			Else If line.StartsWith( "*" )
			
				EmitList( line )
				
			Else If line.StartsWith( "```" )
			
				EmitCode( line )
				
			Else If line.StartsWith( "---" )
			
				Emit( "<hr class="+_cls+">" )
				
			Else If line.StartsWith( "<" )
			
				Emit( line+"\" )
				
			Else If line
			
				If _lineNum>1 And _lines[_lineNum-2]=""
					Emit( "<p class="+_cls+">"+Escape( line ) )
				Else
					Emit( Escape( line ) )
				Endif

			Else
			
'				If Not _buf.Empty And _buf.Top<>"<p>" Emit( "<p>" )
				
			Endif
				
'			Else 
			
'				If _buf.Empty Or _buf.Top="" Emit( "<p>" )
			
'				Emit( Escape( line ) )
			
'			Endif
			
		Wend
		
		Local html:=_buf.Join( "~n" )
		
		html=html.Replace( "\~n","" )
		
		Return html
	
	End

	Private
	
	Const CHAR_HASH:=35		'#
	Const CHAR_ESCAPE:=92	'\
	
	Field _cls:="~qmx2docs~q"
	
	Field _source:String
	Field _linkResolver:LinkResolver
	
	Field _lines:String[]
	
	Field _lineNum:=0
	Field _buf:=New StringStack
	
	Property AtEnd:Bool()
		Return _lineNum>=_lines.Length
	End
	
	Method Emit( str:String )
		_buf.Push( str )
	End

	Method NextLine:String()
		Local line:=_lineNum>=0 And _lineNum<_lines.Length ? _lines[_lineNum] Else ""
		_lineNum+=1
		Return line
	End
	
	Method PrevLine:String()
		_lineNum-=1
		Local line:=_lineNum>=0 And _lineNum<_lines.Length ? _lines[_lineNum] Else ""
		Return line
	End
	
	Method Find:Int( str:String,chr:String,index:Int=0 )

		Local i0:=index

		Repeat
		
			Local i1:=str.Find( chr,i0 )
			If i1=-1 Return str.Length
			
			i0=i1+chr.Length
			
			If i1 And str[i1-1]=CHAR_ESCAPE
				Continue
			Endif
			
			If chr="[[" Or chr="]]" Return i1
			
			Local i2:=str.Find( "]]",i0 )
			If i2<>-1
				Local i3:=str.Find( "[[",i0 )
				If i2<>-1 And (i3=-1 Or i3>i2) continue
			Endif
			
			Return i1
		Forever
		
		Return str.Length
	End

	Method ReplaceAll:String( str:String,find:String,rep:String,index:Int )
	
		Local i0:=index
		
		Repeat
		
			Local i1:=str.Find( find,i0 )
			If i1=-1 Exit
			
			str=str.Slice( 0,i1 )+rep+str.Slice( i1+find.Length )
			i0=i1+rep.Length
		
		Forever
		
		Return str
	End
	
	Method EscapeHtml:String( str:String )
	
		'str=str.Replace( "&","&amp;" )
		Local i0:=0
		Repeat
		
			Local i1:=str.Find( "&",i0 )
			If i1=-1 Exit
			
			Local i2:=str.Find( ";",i1+1 )
			If i2<>-1 And i2-i1<8
			
				Local r:=str.Slice( i1+1,i2 )
				
				Const tags:=New String[]( "nbsp" )
				
				For Local tag:=Eachin tags
					If r<>tag Continue
					
					i0=i2+1
					Exit
				Next
				
				If i0>i1 Continue
			Endif
			
			Local r:="&amp;"
			str=str.Slice( 0,i1 )+r+str.Slice( i1+1 )
			i0=i1+r.Length
		
		Forever

		'str=str.Replace( "<","&lt;" )
		'str=str.Replace( ">","&gt;" )
		i0=0
		Repeat
		
			Local i1:=str.Find( "<",i0 )
			If i1=-1 
				str=ReplaceAll( str,">","&gt;",i0 )
				Exit
			Endif
			
			Local i2:=str.Find( ">",i1+1 )
			If i2=-1
				str=ReplaceAll( str,"<","&lt;",i1 )
				Exit
			Endif
			
			Local i3:=str.Find( "<",i1+1 )
			If i3<>-1 And i3<i2
				Local r:="&lt;"
				str=str.Slice( 0,i1 )+r+str.Slice( i1+1 )
				i0=i1+r.Length
				Continue
			Endif
			
			Local r:=str.Slice( i1+1,i2 )
			
			Const tags:=New String[]( "a href=","/a" )
			
			For Local tag:=Eachin tags
				If Not r.StartsWith( tag ) Continue
				
				r=r.Replace( "\","\\" )
				r=r.Replace( "*","\*" )
				r=r.Replace( "_","\_" )
				r=r.Replace( "`","\`" )
				
				r="<"+r+">"
				str=str.Slice( 0,i1 )+r+str.Slice( i2+1 )
				i0=i1+r.Length
				Exit
			Next
			If i0>i1 Continue
			
			r="&lt;"+r+"&gt;"
			str=str.Slice( 0,i1 )+r+str.Slice( i2+1 )
			i0=i1+r.Length
		Forever
			
		Return str
	End
	
	
	Method ConvertSpanTags:String( str:String,tag:String,ent:String )
	
		Local op:="<"+ent+">"
		Local cl:="</"+ent+">"
	
		Local i0:=0
		Repeat
		
			Local i1:=Find( str,tag,i0 )
			If i1=str.Length Return str
			
			Local i2:=Find( str,tag,i1+1 )
			If i2=str.Length Return str
			
			Local r:=op+str.Slice( i1+1,i2 )+cl
			
			str=str.Slice( 0,i1 )+r+str.Slice( i2+1 )
			i0=i1+r.Length
		
		Forever
		
		Return str
	End
	
	Method ConvertSpanLinks:String( str:String )
	
		Local i0:=0
		Repeat
		
			Local i1:=Find( str,"[[",i0 )
			If i1=str.Length Return str
			
			Local i2:=Find( str,"]]",i1+2 )
			If i2=str.Length Return str
			
			Local link:=str.Slice( i1+2,i2 ),name:=""
			
			Local i3:=link.Find( "|" )
			If i3<>-1
				name=link.Slice( i3+1 )
				link=link.Slice( 0,i3 )
			Endif
			
			Local r:=_linkResolver( link,name )
			
			str=str.Slice( 0,i1 )+r+str.Slice( i2+2 )
			i0=i1+r.Length
			
		Forever
		
		Return str
			
	End
	
	Method ConvertEscapeChars:String( str:String )
	
		Local i0:=0
		
		Repeat
			Local i1:=str.Find( "\",i0 )
			If i1=-1 Or i1+1=str.Length Return str
			
			str=str.Slice( 0,i1 )+str.Slice( i1+1 )
			i0=i1+1
		Forever
		
		Return str
	End
	
	Method Escape:String( str:String )
	
		str=EscapeHtml( str )
		
		'str=ConvertSpanHtml( str )
		
		str=ConvertSpanTags( str,"*","b" )
		str=ConvertSpanTags( str,"_","i" )
		str=ConvertSpanTags( str,"`","code" )

		str=ConvertEscapeChars( str )

		str=ConvertSpanLinks( str )
		
		Return str
	End
	
	Method EmitHeader( line:String )

		Local i:=1
		While i<line.Length
			If line[i]<>CHAR_HASH Exit
			i+=1
		Wend
		
		Local arg:=line.Slice( i ).Trim()
		
		Emit( "<h"+i+" class="+_cls+">" )
		Emit( Escape( line.Slice( i ).TrimStart() ) )
		Emit( "</h"+i+">" )
	End
	
	Method EmitTable( line:String )

		Local head:=line
		Local align:=NextLine()
				
		If Not align.StartsWith( "|" )
			Emit( Escape( head ) )
			PrevLine()
			Return
		Endif
			
		Local heads:=New StringStack
		Local aligns:=New StringStack
				
		Local i0:=1
		While i0<head.Length
			Local i1:=Find( head,"|",i0 )
			heads.Push( Escape( head.Slice( i0,i1 ).TrimStart() ) )
			i0=i1+1
		Wend
				
		i0=1
		While i0<align.Length
			Local i1:=Find( align,"|",i0 )
			Local t:=align.Slice( i0,i1 )
			If t.StartsWith( ":-" )
				If t.EndsWith( "-:" )
					aligns.Push( "center" )
				Else
					aligns.Push( "left" )
				Endif
			Else If t.EndsWith( "-:" )
				aligns.Push( "right" )
			Else
				aligns.Push( "center" )
			Endif
			i0=i1+1
		Wend
				
		While aligns.Length<heads.Length
			aligns.Push( "center" )
		Wend
				
		Emit( "<table class="+_cls+">" )

		Emit( "<tr class="+_cls+">" )
		For Local i:=0 Until heads.Length
			Emit( "<th style=~qtext-align:"+aligns[i]+"~q>"+heads[i]+"</th>" )
		Next
		Emit( "</tr>" )
				
		Repeat
			Local row:=NextLine()
			If Not row.StartsWith( "|" ) 
				PrevLine()
				Exit
			Endif
					
			Emit( "<tr class="+_cls+">" )
			Local i0:=1,col:=0
			While i0<row.Length And col<heads.Length
				Local i1:=Find( row,"|",i0 )
				Emit( "<td class="+_cls+" style=~qtext-align:"+aligns[col]+"~q>"+Escape( row.Slice( i0,i1 ).TrimStart() )+"</td>" )
				i0=i1+1
				col+=1
			Wend
			Emit( "</tr>" )
		Forever
				
		Emit( "</table>" )
		
	End
	
	Method EmitList( line:String )
	
		Local kind:=line.Slice( 0,1 )
		
		Select kind
		Case "*" Emit( "<ul>" )
		Case "+" Emit( "<ol>" )
		End
		
		Repeat
		
			Emit( "<li class="+_cls+">"+Escape( line.Slice( 1 ) )+"</li>" )
			
			If AtEnd Exit
		
			line=NextLine()
			If line.StartsWith( kind ) Continue
			
			PrevLine()
			Exit

		Forever
		
		Select kind
		Case "*" Emit( "</ul>" )
		Case "+" Emit( "</ol>" )
		End
	
	End
	
	Method EmitCode( line:String )
	
		Emit( "<pre class="+_cls+"><code class="+_cls+">\" )
	
		While Not AtEnd
		
			line=NextLine()
			If line.StartsWith( "```" ) Exit
			
			Emit( EscapeHtml( line ) )
			
		Wend
		
		Emit( "</code></pre>" )
	
	End
	
End
