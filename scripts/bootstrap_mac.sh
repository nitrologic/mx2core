mkdir ../bin
cp ../env/*.txt ../bin
cp ~/monkey2/bin/mx2cc_macos ../bin

mx2cc=../bin/mx2cc_macos

# $mx2cc makemods -clean -config=release monkey libc std transpiler
$mx2cc makemods -config=release monkey libc std transpiler
$mx2cc makeapp -clean -apptype=console -config=release -product=bin/mx2 ../mx2/mx2.monkey2
