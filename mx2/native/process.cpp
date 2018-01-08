#include "process.h"

static void *tmps[32];
static int tmpsi;

static const WCHAR *widen( const char *p ){

	int n=MultiByteToWideChar( CP_UTF8,0,p,-1,0,0 );

	WCHAR *w=(WCHAR*)malloc( n*2 );
	
	MultiByteToWideChar( CP_UTF8,0,p,-1,w,n );
	
	free(tmps[tmpsi&31]);
	tmps[(tmpsi++)&31]=w;
	
	return w;
}

int invoke( const char *cmd ){
	BOOL inherit=false;
	DWORD flags=CREATE_NO_WINDOW;
	STARTUPINFOW si={sizeof(si)};
	PROCESS_INFORMATION pi={0};
	//	bbString tmp=BB_T( "cmd /S /C\"" )+BB_T( cmd )+BB_T( "\"" );		
	const WCHAR *wopts=L"cmd /S /C\"";
	const WCHAR *wcmd=widen( cmd );	
	WCHAR *wtmp=(WCHAR*)malloc( (wcslen( wopts )+wcslen( wcmd )+2)*2 );	
	wcscpy( wtmp,wopts );
	wcscat( wtmp,wcmd );
	wcscat( wtmp,L"\"" );			
	BOOL success=CreateProcessW( 0,wtmp,0,0,inherit,flags,0,0,&si,&pi );	
	free(wtmp);
	if( !success ) return -1;
	DWORD state = WaitForSingleObject( pi.hProcess,INFINITE );
	if(state){
		printf("WOWOWOWO\n");
		fflush(stdout);
	}	
	int res=GetExitCodeProcess( pi.hProcess,(DWORD*)&res ) ? res : -1;
//	CloseHandle( pi.hThread );
	CloseHandle( pi.hProcess );
	return res;

}
