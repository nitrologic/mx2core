
Namespace libc

#Import "native/libc.cpp"
#Import "native/libc.h"

Extern

#rem monkeydoc C/C++ 'char' type.
#end
Struct char_t="char"
End

#rem monkeydoc C/C++ 'const char' type.
#end
Struct const_char_t="const char"
End

#rem monkeydoc C/C++ 'signed char' type.
#end
Struct signed_char_t="signed char"
End

#rem monkeydoc C/C++ 'unsigned char' type
#end
Struct unsigned_char_t="unsigned char"
End

#rem monkeydoc C/C++ 'wchar_t' type
#end
Struct wchar_t="wchar_t"
End

#rem monkeydoc C/C++ 'size_t' type
#end
Alias size_t:UInt

#rem monkeydoc C/C++ 'int8_t' type
#end
Alias int8_t:Byte

#rem monkeydoc C/C++ 'uint8_t' type
#end
Alias uint8_t:UByte

#rem monkeydoc C/C++ 'int16_t' type
#end
Alias int16_t:Short

#rem monkeydoc C/C++ 'uint16_t' type
#end
Alias uint16_t:UShort

#rem monkeydoc C/C++ 'int32_t' type
#end
Alias int32_t:Int

#rem monkeydoc C/C++ 'uint32_t' type
#end
Alias uint32_t:UInt

#rem monkeydoc C/C++ 'int64_t' type
#end
Alias int64_t:Long

#rem monkeydoc C/C++ 'uint64_t' type
#end
Alias uint64_t:ULong

#rem monkeydoc C/C++ 'intptr_t' type
#end
Alias intptr_t:ULong

#rem monkeydoc C/C++ 'uintptr_t' type
#end
Alias uintptr_t:ULong

Function sizeof<T>:size_t( t:T )="sizeof"
	
'***** limits.h *****

Const PATH_MAX:Int

'***** stdio.h *****

Struct FILE
End

Const stdin:FILE Ptr
Const stdout:FILE Ptr
Const stderr:FILE Ptr

Const SEEK_SET:Int
Const SEEK_CUR:Int
Const SEEK_END:Int

Function fopen:FILE Ptr( path:CString,mode:CString )="fopen_utf8"

Function rewind:Void( stream:FILE )
Function ftell:Int( stream:FILE Ptr )
Function fseek:Int( stream:FILE Ptr,offset:Int,whence:Int )

Function fread:Int( buf:Void Ptr,size:Int,count:Int,stream:FILE Ptr )
Function fwrite:Int( buf:Void Ptr,size:Int,count:Int,stream:FILE Ptr )
Function fflush:Int( stream:FILE Ptr )
Function fclose:Int( stream:FILE Ptr )
Function fputs:Int( str:CString,stream:FILE Ptr )="fputs_utf8"

Function remove:Int( path:CString )="remove_utf8"
Function rename:Int( oldPath:CString,newPath:CString )="rename_utf8"

Function puts:Int( str:CString )="puts_utf8"

'***** stdlib.h *****

Function malloc:Void Ptr( size:Int )
Function free:Void( mem:Void Ptr )
	

#If __TARGET__<>"ios"	'gone in ios11!
Function system:Int( cmd:CString )="system_utf8"
#endif

Function setenv:Int( name:CString,value:CString,overwrite:Int )="setenv_utf8"
Function getenv:char_t Ptr( name:CString )="getenv_utf8"

Function exit_:Void( status:Int )="exit"
Function atexit:Int( func:Void() )="atexit" 
Function abort:Void()
	
Function realpath:char_t Ptr( path:CString,resolved_path:char_t Ptr )="realpath_utf8"

'***** string.h *****

Function strlen:Int( str:CString )

Function memset:Void Ptr( dst:Void Ptr,value:Int,count:Int )
Function memcpy:Void Ptr( dst:Void Ptr,src:Void Ptr,length:Int )
Function memmove:Void Ptr( dst:Void Ptr,src:Void Ptr,length:Int )
Function memcmp:Int( dst:Void Ptr,src:Void Ptr,length:Int )

'***** time.h *****

Struct time_t
End

Struct tm_t
	Field tm_sec:Int
	Field tm_min:Int
	Field tm_hour:Int
	Field tm_mday:Int
	Field tm_mon:Int
	Field tm_year:Int
	Field tm_wday:Int
	Field tm_yday:Int
	Field tm_isdst:Int
End

Struct timeval
	Field tv_sec:Long	'dodgy - should be time_t
	Field tv_usec:Long	'dodyy - should be suseconds_t
End

Struct timezone
End

'Note: clock() scary - pauses while process sleeps!
Const CLOCKS_PER_SEC:Long="((bbLong)CLOCKS_PER_SEC)"
Function clock:Long()="(bbLong)clock"

Function tolong:Long( timer:time_t )="bbLong"

Function time:time_t( timer:time_t Ptr )
Function localtime:tm_t Ptr( timer:time_t Ptr )
Function gmtime:tm_t Ptr( timer:time_t Ptr )
Function difftime:Double( endtime:time_t,starttime:time_t ) 
Function gettimeofday:Int( tv:timeval Ptr )="gettimeofday_utf8"

'***** unistd.h *****

Function getcwd:char_t Ptr( buf:char_t Ptr,size:Int )="getcwd_utf8"
Function chdir:Int( path:CString )="chdir_utf8"
Function rmdir:Int( path:CString )="rmdir_utf8"

'***** sys/stat.h *****

Enum mode_t
End

Const S_IFMT:mode_t		'$f000
Const S_IFIFO:mode_t	'$1000
Const S_IFCHR:mode_t	'$2000
Const S_IFBLK:mode_t	'$3000
Const S_IFDIR:mode_t	'$4000
Const S_IFREG:mode_t	'$8000

Struct stat_t
	Field st_mode:mode_t
	Field st_size:Long
	Field st_atime:time_t	'last access
	Field st_mtime:time_t	'last modification
	Field st_ctime:time_t	'status change
End

Function stat:Int( path:CString,buf:stat_t Ptr )="stat_utf8"
Function mkdir:Int( path:CString,mode:Int )="mkdir_utf8"

'***** dirent.h *****

Struct DIR
End

Struct dirent
	Field d_name:CString
End

Function opendir:DIR Ptr( path:CString )="opendir_utf8"
Function readdir:dirent Ptr( dir:DIR Ptr )="readdir_utf8"
Function closedir( dir:DIR Ptr )="closedir_utf8"
