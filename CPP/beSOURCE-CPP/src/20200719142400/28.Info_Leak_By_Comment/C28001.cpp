#include <stdio.h>
#include <stdlib.h>

/**
* 
* 
* 
* 
*
* 
*
*
*
*
*
*
*
*
*
*
*
*
*
*/

/*
 *  default password is "abracadabra".  
 *	Password for administrator is "admin"
 */
char *passwd = "abracadabra";

int verifyAuth(char *ipasswd)
{
	char* admin="admin";

    if (strncmp(ipasswd, passwd, sizeof(ipasswd)) != 0) {
        printf("Authetication Fail!\n");
    }
    return admin;
}

/**
* 
*  
 
            
	//  default password is "abracadabra".  [case #1] password in Comment
    char *passwd="abracadabra";
    
    int verifyAuth(char *ipasswd)
    {
    	if (strncmp(ipasswd, passwd, sizeof(ipasswd)) != 0) {
        	printf("Authetication Fail!\n");
            return 0;
		}
        return 1;
	}
*/
