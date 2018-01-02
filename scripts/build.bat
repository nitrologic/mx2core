rem echo off
set mx2cc=..\bin\mx2cc.exe

rem %mx2cc% makemods -clean -config=release monkey libc std

rem %mx2cc% makeapp -clean -apptype=console -config=release -product=tmp/mx2cc.exe ../mx2cc/mx2cc.monkey2
rem copy ..\tmp\mx2cc.exe ..\bin

%mx2cc% makemods -clean -config=release monkey libc std pub miniz stb-image stb-image-write stb-truetype stb-vorbis
%mx2cc% makemods -clean -config=release jni sdl2 bullet freetype emscripten hoedown litehtml openal opengl
%mx2cc% makemods -clean -config=release mojo mojox mojo3d

rem %mx2cc% makeapp -clean -apptype=gui -build -config=release -product=tmp/Ted2.exe ../src/ted2go/Ted2.monkey2

rem xcopy ted2go.products\windows\assets ..\bin\ted2_windows\assets /Q /I /S /Y
rem xcopy ted2go.products\windows\*.dll ..\bin\ted2_windows /Q /I /S /Y
rem xcopy ted2go.products\windows\*.exe ..\bin\ted2_windows /Q /I /S /Y
