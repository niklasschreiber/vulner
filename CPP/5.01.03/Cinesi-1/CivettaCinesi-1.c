/* Nuove Rules e References-CPP-Cinesi-1 */

#include <stdio.h>
#include <errno.h>
#include <time.h>
#include <stdlib.h>
#include <string.h>
#include <winbase.h>

int rc;
char filename[] = "/tmp/fileXXXXXX";
uintptr_t opaddr;

int main(void) {
		
	rc = ldap_simple_bind_s( ld, NULL, NULL ); /* VIOLATION PUNTO C3 */
	if ( rc != LDAP_SUCCESS ) { 
		return 0;
	}
	srand(2223333); /* VIOLATION PUNTO C5 */

	srand (time(NULL)); /* VIOLATION PUNTO C6 */
	
	if (mkstemp(filename)){ /* VIOLATION PUNTO C7 */
	FILE* tmp = fopen(filename,"wb+");
	while((recv(sock,recvbuf,DATA_SIZE, 0) > 0)&&(amt!=0))
		amt = fwrite(recvbuf,1,DATA_SIZE,tmp);
}

	if (IsBadWritePtr((const void*)opaddr, length)) /* VIOLATION PUNTO C8 */
	{
		[handle error]
	}
	
   
}

char* CreateReceiptURL() {
    int num;
    time_t t1;
    char *URL = (char*) malloc(MAX_URL);
    if (URL) {
        (void) time(&t1);
        srand48((long) t1);     /* VIOLATION PUNTO C4 */
        sprintf(URL, "%s%d%s", "http://test.com/", lrand48(), ".html");
    }
    return URL;
}


// Global variable
CRITICAL_SECTION CriticalSection; 
DWORD WINAPI ThreadProc( LPVOID lpParameter )
{
    ...
    // Request ownership of the critical section.
    EnterCriticalSection(&CriticalSection);  /* VIOLATION PUNTO C9 */
    // Access the shared resource.
    // Release ownership of the critical section.
    LeaveCriticalSection(&CriticalSection);
    ...
return 1;
}

size_t _mbsspn (const unsigned char *str1, const unsigned char *str2)
{
    int c;
    const unsigned char *save = str1;
	unsigned char *ret = NULL;
	char destination[25];
	char *source = " States";

    while ((c = _mbsnextc (str1))) {

		if (_mbschr (str2, c) == 0)
			break;

		str1 = _mbsinc ((unsigned char *) str1); /* VIOLATION PUNTO C10 */
		ret = _mbsdec(str1,str1+1); /* VIOLATION PUNTO C10 */
		_mbsncpy(destination, "United");
		_mbsncat(destination, source, 7); /* VIOLATION PUNTO C10 */

    }

    return str1 - save;
}

size_t _mbsspn (const unsigned char *str1, const unsigned char *str2)
{
    int c;
    const unsigned char *save = str1;

    while ((c = _mbsnextc (str1))) {  /* VIOLATION PUNTO C10 */

		if (_mbschr (str2, c) == 0)
			break;

		str1 = _mbsinc ((unsigned char *) str1);
		_mbsset( str1, _mbsnextc("#") );	/* VIOLATION PUNTO C10 */
    }

    return str1 - save;
}

void violaz_C10(LPSTR lpszName, int nLenName, LPSTR lpszEMail, int nLenEMail, LPCTSTR lpszSrc)
  {
    unsigned char   chars2[20];
	
	const unsigned char* p2 = _mbsstr((const unsigned char*)p, (const unsigned char*)".hyb"); /* VIOLATION PUNTO C10 */
	
    int             i;
	LPSTR lpsz = strdup(lpszSrc);
	
	while (*lpsz == '\x20' || *lpsz == '\t') lpsz++;
	LPSTR lpszAddr = lpsz;
	
	lpszTmp = (LPSTR)_mbstok((LPBYTE)lpszAddr, (LPBYTE)">"); /* VIOLATION PUNTO C10 */
    _setmbcp( 932 );
    _mbsnset( chars2, 0xFF, 20 ); 		/* VIOLATION PUNTO C10 */
    _mbsnbcpy( chars2, chars, 11 );
    for( i = 0; i < 20; i++ )
        printf( "%2.2x ", chars2[i] );
    printf( "\n" );
    _mbsnbcpy( chars2, chars, 20 );
    for( i = 0; i < 20; i++ )
        printf( "%2.2x ", chars2[i] );
    printf( "\n" );
	_mbsrev(chars2); 					/* VIOLATION PUNTO C10 */
	_setmbcp( 932 );
    printf( "%#6.4x\n", mb1[0] << 8 | mb1[1] );
    _mbccpy( mb1, mb2 ); 	/* VIOLATION PUNTO C10 */
  }
  
_WCRTLINK size_t _wstrftime_ms( CHAR_TYPE *s, size_t maxsize, const char *format, const struct tm *timeptr )
{
    wchar_t     *auto_buf;
    int         length;
	char pass;
	
	unsigned int result = data + 1; 	/* VIOLATION PUNTO C18 */
	int result = data + 1;				/* VIOLATION PUNTO C18 */
	unsigned int result = data * 2;		/* VIOLATION PUNTO C18 */
	int result = data * 2;				/* VIOLATION PUNTO C18 */
	unsigned int result = data * data;	/* VIOLATION PUNTO C18 */
	int result = data * data;			/* VIOLATION PUNTO C18 */


    length = _mbslen( (unsigned char *)format ) + 1; /* VIOLATION PUNTO C10 */
    auto_buf = (wchar_t *)alloca( length * CHARSIZE );
    mbstowcs( auto_buf, format, length );
	
	LoadLibrary("liberty.dll");  /* VIOLATION PUNTO C12 */
	LoadLibrary("C://Libs//liberty.dll");  /* OK */

	PKCS5_PBKDF2_HMAC(pass, strlen(pass), "2!@$(5#@532@%#$253l5#@$", 2, ITERATION, EVP_sha512(), outputBytes, digest); /* VIOLATION PUNTO C13 */
	
	crypt(pass, "2!@$(5#@532@%#$253l5#@$"); /* VIOLATION PUNTO C14 */
	
	buffer[pass] = 1; //VIOLATION PUNTO C16
	printIntLine(buffer[pass]); //VIOLATION PUNTO C16

	for (i = 0; i < (size_t)count; i++)
		{
			if (strlen(SENTENCE) != fwrite(SENTENCE, sizeof(char), strlen(SENTENCE), pFile))
			{
				exit(1);	/* VIOLATION PUNTO C21 */
			}
		}
	for (;;) {
		Runnable r = ...;
		r.run(); 			/* VIOLATION PUNTO C21 */
				 }
				 while (1) {
		newsock=accept(sock, ...);
		printf("A connection has been accepted\n");
		pid = fork(); 		/* VIOLATION PUNTO C21 */
	 }

	do {
		Socket client = serverSocket.accept();
		Thread t = new Thread(new ClientSocketThread(client)); /* VIOLATION PUNTO C21 */
		t.setName(client.getInetAddress().getHostName() + ":" + counter++);
		t.start();
		} while (hasConnections);

    return( wcsftime( s, maxsize, auto_buf, timeptr ) );
}
