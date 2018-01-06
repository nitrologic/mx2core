
Namespace mx2

Class ErrorEx Extends Throwable
	Field msg:String
	
	Method New( msg:String )
		Self.msg=msg
		
		Builder.errors.Push( Self )
	End
	
	Method ToString:String() Virtual
		Return "?[?] : Error :"+msg
	End
End

Class ParseEx Extends ErrorEx

	Field srcfile:String
	Field srcpos:Int
	
	Method New( msg:String,srcfile:String,srcpos:Int )
		Super.New( msg )
		Self.srcfile=srcfile
		Self.srcpos=srcpos
		
		If srcfile Print ToString()
	End
	
	Method ToString:String() Override
		Return srcfile+" ["+(srcpos Shr 12)+"] : Error : "+msg
	End
End

Class SemantEx Extends ErrorEx

	Field pnode:PNode

	Method New( msg:String )
		Super.New( msg )
		
		If PNode.semanting.Length pnode=PNode.semanting.Top
		
		Print ToString()
	End
	
	Method New( msg:String,pnode:PNode )
		Super.New( msg )

		Self.pnode=pnode
		
		Print ToString()
	End
	
	Method ToString:String() Override
		If Not pnode Return "? [?] : Error : "+msg
		Local fdecl:=pnode.srcfile
		If Not fdecl Return "????? ["+(pnode.srcpos Shr 12)+"] : Error : "+msg
		Return fdecl.path+" ["+(pnode.srcpos Shr 12)+"] : Error : "+msg
	End
	
End

Class BuildEx Extends ErrorEx

	Global srcpath:String	
	Global srcpos:Int
	
	Method New( msg:String )
		Super.New( msg )
		
		Print ToString()
	End
	
	Method ToString:String() Override
		
		If srcpath Return srcpath+" ["+(srcpos Shr 12)+"] : Error : "+msg
			
		Return "Build error: "+msg
	End

End

Class TransEx Extends BuildEx

	Method New( msg:String )
		Super.New( msg )
		
		Print ToString()
	End
	
	Method ToString:String() Override
		Return "Translate error: "+msg
	End
	
End

Class IdentEx Extends SemantEx

	Method New( ident:String )
		Super.New( "Identifier '"+ident+"' not found" )
	End
End

Class TypeIdentEx Extends SemantEx

	Method New( ident:String )
		Super.New( "Type '"+ident+"' not found" )
	End
	
End

Class UpCastEx Extends SemantEx

	Method New( value:Value,type:Type )
		Super.New( "Value cannot be implicitly cast from type '"+value.type.ToString()+"' to type '"+type.ToString()+"'" )
	End
End

Class OverloadEx Extends SemantEx

	Method New( value:Value,args:Value[] )
		Super.New( "Can't find overload for '"+value.ToString()+"' with arguments ("+Join( args )+")" )
	End

	Method New( value:Value,args:Type[] )
		Super.New( "Can't find overload for '"+value.ToString()+"' with argument types ("+Join( args )+")" )
	End
End

Function SemantError( func:String )
	Print "~n".Join( GetDebugStack() )
	Throw New SemantEx( func+" Internal Error" )
End

Function TransError( func:String )
	Print "~n".Join( GetDebugStack() )
	Throw New SemantEx( func+" Internal Error" )
End
