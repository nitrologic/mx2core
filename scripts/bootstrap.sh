mkdir ../bin
cp ../env/* ../bin
cp ~/monkey2/bin/mx2cc_linux ../bin

mx2cc=../bin/mx2cc_linux

#$mx2cc makemods -clean -config=release monkey libc std transpiler
$mx2cc makeapp -clean -apptype=console -config=release -product=bin/mx2cc ../mx2/mx2.monkey2
