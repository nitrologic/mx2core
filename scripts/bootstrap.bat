rem echo off
mkdir ..\bin
copy ..\env\*.txt ..\bin
copy C:\monkey2\bin\mx2cc_windows.exe ..\bin
set mx2cc=..\bin\mx2cc_windows.exe
%mx2cc% makemods -clean -config=release monkey libc std
%mx2cc% makeapp -clean -apptype=console -config=release -product=bin/mx2cc.exe ../mx2cc/mx2cc.monkey2
