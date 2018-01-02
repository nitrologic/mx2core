
Namespace mx2.overload

Private

Const debug:=False'True

Function dprint( txt:String )
	Global tab:=""
	If txt.StartsWith( "}" ) tab=tab.Slice( 0,2 )
	Print tab+txt
	If txt.EndsWith( "{" ) tab+="  "
End

Function GenCandidate:FuncValue( func:FuncValue,ret:Type,args:Type[] )

	Local ftype:=func.ftype
	Local retType:=ftype.retType
	Local argTypes:=ftype.argTypes
	
	If args.Length>argTypes.Length Return Null
	
	Local infered:Type[]
	If func.IsGeneric infered=New Type[func.types.Length]
	
	If ret
		If retType.IsGeneric
			retType=retType.InferType( ret,infered )
			If Not retType Return Null
		Endif
		If Not retType.Equals( ret ) Return Null
	Endif
	
	For Local i:=0 Until argTypes.Length
	
		If i>=args.Length Or Not args[i]
			Local pdecl:=func.pdecls[i]
			If Not pdecl.init Return Null
			Continue
		Endif
		
		Local argType:=argTypes[i]
		
		If argType.IsGeneric
			argType=argType.InferType( args[i],infered )
			If Not argType Return Null
		Endif
		
		If args[i].DistanceToType( argType )<0 Return Null
	Next
	
	If Not func.IsGeneric Return func
	
	For Local i:=0 Until infered.Length
		If Not infered[i] Or infered[i]=Type.BadType Return Null
	Next
	
	Return func.TryGenInstance( infered )
End

Function CanInfer:Bool( func:FuncValue,args:Type[] )

	Local ftype:=func.ftype
	Local argTypes:=ftype.argTypes
	
	Local infered:=New Type[func.types.Length]
	
	For Local i:=0 Until Min( args.Length,argTypes.Length )
		If argTypes[i].IsGeneric And Not argTypes[i].InferType( args[i],infered ) Return False
	Next
	
	For Local i:=0 Until infered.Length
		If Not infered[i] Or infered[i]=Type.BadType Return False
	Next
	
	Return True
End

'return true if func is better than func2
'
Function IsBetter:Bool( func:FuncValue,func2:FuncValue,args:Type[] )

	Local better:=False,same:=True

	For Local i:=0 Until args.Length
		If Not args[i] Continue
	
		Local dist1:=args[i].DistanceToType( func.ftype.argTypes[i] )
		Local dist2:=args[i].DistanceToType( func2.ftype.argTypes[i] )
		
		If dist1=-1 Or dist2=-1 SemantError( "FuncListType.IsBetter()" )
		
		If dist1>dist2 Return False
		
		If dist1<dist2 better=True
		
		If dist1 same=False
	Next
	
	If better Return True
	
	If Not same Return False
	
	'always prefer non-generic over generic
	'
	If Not func.instanceOf And func2.instanceOf Return True
	
	'compare 2 generic func instances
	'		
	If func.instanceOf And func2.instanceOf
		If CanInfer( func2.instanceOf,func.instanceOf.ftype.argTypes ) 
			If Not CanInfer( func.instanceOf,func2.instanceOf.ftype.argTypes ) 
				Return True
			Endif
		Endif
	Endif

	Return False
End

Function FindCandidates( func:FuncValue,candidates:Stack<FuncValue>,ret:Type,args:Type[],j:Int=0 )

	For Local i:=j Until args.Length
	
		Local flist:=TCast<FuncListType>( args[i] )
		If Not flist Continue
		
		args=args.Slice( 0 )
		
		For Local func2:=Eachin flist.funcs
			args[i]=func2.ftype
			FindCandidates( func,candidates,ret,args,i+1 )
		Next
		
		Return
	Next
	
	func=GenCandidate( func,ret,args )
	If Not func Or candidates.Contains( func ) Return
	
	candidates.Push( func )
End

Public
	
Function FindOverload:FuncValue( funcs:Stack<FuncValue>,ret:Type,args:Type[] )

	If ret DebugAssert( Not ret.IsGeneric )
	For Local arg:=Eachin args
		If arg DebugAssert( Not arg.IsGeneric )
	Next

	If debug
		dprint( "{" )
		dprint( "Funcs:"+Join( funcs.ToArray() ) )
		dprint( "Args:"+Join( args ) )
		If ret dprint( "Return:"+ret.ToString() ) Else dprint( "Return:?" )
	Endif

	Local candidates:=New Stack<FuncValue>
	
	For Local func:=Eachin funcs
		FindCandidates( func,candidates,ret,args )
	Next

	If debug dprint( "Candidates:"+Join( candidates.ToArray() ) )
	
	Local best:FuncValue
	
	For Local func:=Eachin candidates
	
		Local better:=True
		
		For Local func2:=Eachin candidates
		
			If func2=func Continue
		
			If IsBetter( func,func2,args ) Continue
			
			better=False
			Exit
		Next
		
		If Not better Continue
		
		If best 
			best=Null
			Exit
		Endif
		
		best=func
	Next

	If debug	
		If best dprint( "Best match:"+best.ToString() ) Else dprint( "No match" )
		dprint( "}" )
	Endif
	
	Return best
End
