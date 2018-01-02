rem echo off
call common.bat
%mx2cc% makemods -clean -config=release monkey libc std
%mx2cc% makeapp -clean -apptype=console -config=release -product=scripts/mx2cc.products/mx2cc_windows.exe ../src/mx2cc/mx2cc.monkey2
rem copy mx2cc.products\mx2cc_windows.exe %mx2cc%
