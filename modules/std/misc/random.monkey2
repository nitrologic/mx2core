
Namespace std.random

Private

Global state0:ULong=1234
Global state1:ULong=~1234|1

Function rotl:ULong( x:ULong,k:Int )
	Return (x Shl k) | (x Shr (64-k))
End

Public

#rem monkeydoc Seeds the random number generator.

@param seed The seed value.

#end
Function SeedRnd( seed:ULong )
	state0=seed*2|1
	state1=~state0|1
	RndULong()
	RndULong()
End

#rem monkeydoc Generates a random unsigned long value.

This is the core function used by all other functions in the random namespace that generate random numbers.

The algorithm currently used is 'xoroshiro128+'.

@return A random unsigned long value.

#end
Function RndULong:ULong()
	Local s0:=state0
	Local s1:=state1
	s1~=s0
	state0=rotl( s0,55 ) ~ s1 ~ (s1 Shl 14)
	state1=rotl( s1,36 )
	return state0+state1
End

#rem monkeydoc Generates a random double value.

When used with no parameters, returns a random double value in the range 0 (inclusive) to 1 (exclusive).

When used with one parameter, returns a random double value in the range 0 (inclusive) to `max` (exclusive).

When used with two parameters, returns a random double value in the range `min` (inclusive) to `max` (exclusive).

@param min Minimum value to return.

@param max Maximum value to return.

#end
Function Rnd:Double()
	Local x:=RndULong(),y:ULong=$3ff
	Local t:ULong=(y Shl 52) | (x Shr 12)
	Return (Cast<Double Ptr>( Varptr t ))[0]-1
End

Function Rnd:Double( max:Double )
	Return Rnd()*max
End

Function Rnd:Double( min:Double,max:Double )
	Return Rnd(max-min)+min
End
