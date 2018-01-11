rem echo off
mkdir ..\bin
copy ..\env\*.txt ..\bin
copy C:\monkey2\bin\mx2cc.exe ..\bin

set mx2cc=..\bin\mx2cc.exe
rem %mx2cc% makemods -clean -config=release monkey libc std transpiler
%mx2cc% makeapp -clean -apptype=console -config=release -product=bin/mx2.exe ../mx2/mx2.monkey2
