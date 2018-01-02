
Namespace mx2

Function OpSym:String( id:String )
	Select id
	Case "*" Return "_mul"
	Case "/" Return "_div"
	Case "+" Return "_add"
	Case "-" Return "_sub"
	Case "&" Return "_and"
	Case "|" Return "_or"
	Case "~~" Return "_xor"
	Case "[]" Return "_idx"
	Case "*=" Return "_muleq"
	Case "/=" Return "_diveq"
	Case "+=" Return "_addeq"
	Case "-=" Return "_subeq"
	Case "&=" Return "_andeq"
	Case "|=" Return "_oreq"
	Case "~~=" Return "_xoreq"
	Case "[]=" Return "_idxeq"
	Case "<" Return "_lt"
	Case "<=" Return "_le"
	Case ">" Return "_gt"
	Case ">=" Return "_ge"
	Case "=" Return "_eq"
	Case "<>" Return "_ne"
	Case "<=>" Return "_cmp"
	End
	Return "????? OpSym ?????"
End

Function MungIdent:String( ident:String )

	If Not IsIdent( ident[0] ) Return OpSym( ident )

	Return ident.Replace( "_","_0" )
End

Function MungArg:String( type:Type )

	If type=Type.VoidType Return "v"
	
	Local ptype:=TCast<PrimType>( type )
	If ptype
		Select ptype
		Case Type.BoolType	Return "z"
		Case Type.ByteType	Return "b"
		Case Type.UByteType	Return "c"
		Case Type.ShortType	Return "h"
		Case Type.UShortType	Return "t"
		Case Type.IntType	Return "i"
		Case Type.UIntType	Return "j"
		Case Type.LongType	Return "l"
		Case Type.ULongType	Return "m"
		Case Type.FloatType	Return "f"
		Case Type.DoubleType	Return "d"
		Case Type.StringType	Return "s"
		Case Type.VariantType	Return "q"
		End
		Return "????? MungArg ?????"
	End
	
	Local atype:=TCast<ArrayType>( type )
	If atype
		Local sym:="A"
		If atype.rank>1 sym+=String( atype.rank )
		Return sym+MungArg( atype.elemType )
	Endif
	
	Local ftype:=TCast<FuncType>( type )
	If ftype
		Local sym:="F"+MungArg( ftype.retType )
		For Local ty:=Eachin ftype.argTypes
			sym+=MungArg( ty )
		Next
		Return sym+"E"
	Endif
	
	Local ctype:=TCast<ClassType>( type )
	If ctype
		Return "T"+ClassName( ctype ).Replace( "::","_3" )+"_2"
	Endif
	
	Local etype:=TCast<EnumType>( type )
	If etype
		Return "T"+EnumName( etype ).Replace( "::","_3" )+"_2"
	Endif

	Local qtype:=TCast<PointerType>( type )
	If qtype
		Return "P"+MungArg( qtype.elemType )
	Endif
	
'	Return "????? MungArg "+String.FromCString( type.typeName() )+" ?????"
	Return "????? MungArg ?????"
End

Function MungArgs:String( types:Type[] )

	Local sym:="_1"
	For Local ty:=Eachin types
		If TCast<GenArgType>( ty ) Continue
		sym+=MungArg( ty )
	Next
	Return sym

End

Function ScopeName:String( scope:Scope )

	If Not scope Return "????? ScopeName ?????"
	
	Local fscope:=Cast<FileScope>( scope )
	If fscope
		Return MungIdent( fscope.fdecl.nmspace ).Replace( ".","_" )
	Endif
	
	Local cscope:=Cast<ClassScope>( scope )
	If cscope 
		Local ctype:=cscope.ctype
		Local sym:=ScopeName( scope.outer )+"_"+MungIdent( ctype.cdecl.ident )
		If ctype.types sym+=MungArgs( ctype.types )
		Return sym
	End
	
	Local escope:=Cast<EnumScope>( scope )
	If escope
		Local etype:=escope.etype
		Local sym:=ScopeName( scope.outer )+"_"+MungIdent( etype.edecl.ident )
		Return sym
	Endif
	
	Return ScopeName( scope.outer )
End

Function EnumName:String( etype:EnumType )

	Local edecl:=etype.edecl
	
	If edecl.symbol
		If edecl.symbol.EndsWith( "::" ) Return "int"
		Return edecl.symbol
	Endif
	
	If edecl.IsExtern Return edecl.ident
	
	Return "t_"+ScopeName( etype.scope )
End

Function EnumValueName:String( etype:EnumType,value:String )

	If Not value.StartsWith( "@" )
		Return EnumName( etype )+"("+value+")"
	Endif
	
	value=value.Slice( 1 )
	
	Local edecl:=etype.edecl

	If edecl.symbol
		If edecl.symbol.EndsWith( "::" ) 
			If edecl.symbol<>"::" value=edecl.symbol+value
			Return "int("+value+")"
		Endif
		Local i:=edecl.symbol.FindLast( "::" )
		If i<>-1 Return edecl.symbol.Slice( 0,i+2 )+value
	Endif
	
	Return value
End

Function ClassName:String( ctype:ClassType )

	Local cdecl:=ctype.cdecl

	If cdecl.symbol Return cdecl.symbol
	
	If cdecl.IsExtern
	
		Local symbol:=cdecl.ident
		
		Local cscope:=Cast<ClassScope>( ctype.scope.outer )
		If cscope symbol=ClassName( cscope.ctype )+"::"+symbol
	
		Return symbol
	Endif
	
	If ctype.cdecl.IsExtension Return "x_"+ScopeName( ctype.scope )+"_"+ctype.scope.FindFile().fdecl.ident

	Return "t_"+ScopeName( ctype.scope )
End

Function FuncName:String( func:FuncValue )

	If func.overrides Return FuncName( func.overrides )

	Local fdecl:=func.fdecl

	If fdecl.symbol Return fdecl.symbol
	
	If fdecl.IsExtern

		Local symbol:=fdecl.ident
		
		If fdecl.kind="function"
			Local cscope:=Cast<ClassScope>( func.scope )
			If cscope symbol=ClassName( cscope.ctype )+"::"+symbol
		Endif
		
		Return symbol
	Endif
	
	If fdecl.kind="function" Or func.IsExtension
	
		Local sym:="g_"+ScopeName( func.scope )+"_"+MungIdent( fdecl.ident )
		
		If fdecl.ident="to" sym+="_"+MungArg( func.ftype.retType )

		If func.types sym+=MungArgs( func.types )
		
		Return sym

	Else If fdecl.kind="method"
	
		If fdecl.ident="new" Return ClassName( Cast<ClassScope>( func.scope ).ctype )

		Local sym:="m_"+MungIdent( fdecl.ident )
		
		If fdecl.ident="to" sym+="_"+MungArg( func.ftype.retType )

		If func.types sym+=MungArgs( func.types )

		Return sym
		
	Else If fdecl.kind="lambda"
	
		Return "invoke"
	
	End
	
	Return "????? FuncName ?????"
End

Function VarName:String( vvar:VarValue )

	Local vdecl:=vvar.vdecl
	
	If vdecl.symbol Return vdecl.symbol
	
	If vdecl.IsExtern 
	
		Local symbol:=vdecl.ident
		
		If vdecl.kind="global" Or vdecl.kind="const"
			Local cscope:=Cast<ClassScope>( vvar.scope )
			If cscope symbol=ClassName( cscope.ctype )+"::"+symbol
		Endif
		
		Return symbol
	Endif

	Local sym:=MungIdent( vdecl.ident )

	Select vdecl.kind
	
	Case "local","param","capture"
	
		Return "l_"+sym
	
	Case "field"
	
		Return "m_"+sym
		
	Case "global","const"
	
		If Cast<Block>( vvar.scope ) Return "g_"+sym
	
		Return "g_"+ScopeName( vvar.scope )+"_"+sym
	
	End
	
	Return "????? VarName ?????"
End
