#include "cgic.h"
#include <wchar.h>

#ifdef _WIN32
# include <winsock2.h>
# include <windows.h>
# include <direct.h>
# pragma comment(lib, "ws2_32") /* include ws2_32.lib when linking */
#endif

void cwe80_bad()
{
    char cname[1024];
    char cvalue[1024];
    /*  
       */
    /*  */
    cgiFormString("cname", cname, sizeof(cname));  
    /*  */
    cgiFormString("cdata", cvalue, sizeof(cvalue));  
    if (strlen(cname)) {
        /*  
            
            
            */  
        cgiHeaderCookieSetString(cname, cvalue,
                86400, cgiScriptName, cgiServerName);
  	}
}
