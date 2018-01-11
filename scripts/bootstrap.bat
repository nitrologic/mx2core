rem echo off
mkdir ..\bin
copy ..\env\*.txt ..\bin
copy C:\monkey2\bin\mx2cc.exe ..\bin

set mx2cc=..\bin\mx2cc.exe
rem %mx2cc% makemods -clean -config=release monkey libc std transpiler
rem %mx2cc% makeapp -clean -apptype=console -config=release -product=bin/mx2.exe ../mx2/mx2.monkey2

rem %mx2% makemods -clean -config=release monkey libc std transpiler
rem %mx2% makeapp -clean -apptype=console -config=release -product=bin/mx2.exe ../mx2cc/mx2cc.monkey2

set mx2=..\bin\mx2.exe
copy ..\mx2\mx2.products\Windows\mx2.exe %mx2%
%mx2%
%mx2% makemods
%mx2% makeapp
