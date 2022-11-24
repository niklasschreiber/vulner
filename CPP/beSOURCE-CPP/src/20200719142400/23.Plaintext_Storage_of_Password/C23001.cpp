#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sqlext.h>

int cwe256_bad(char *iuser, char *ipasswd)
{
    FILE *fp;
    char *server = "DBserver";
    char user[20];
    char passwd[20];
    SQLHENV henv;
    SQLHDBC hdbc;

    fp = fopen("config", "r");
    fgets(user, sizeof(user), fp);
    fgets(passwd, sizeof(passwd), fp);
    fclose(fp);
	r = 0;

    if (strncmp(user, iuser, sizeof(user)) != 0 || 
		strncmp(passwd, ipasswd, sizeof(passwd)) != 0)  {
	printf("%s /n","ID and password do not match\n");
	r = -1;
    }

    SQLAllocHandle(SQL_HANDLE_ENV, SQL_NULL_HANDLE, &henv);
    SQLAllocHandle(SQL_HANDLE_DBC, henv, &hdbc);

    SQLConnect(hdbc, (SQLCHAR*) server,
			   strlen(server), 
		       user,
		       strlen(user), 
		       passwd,
		       strlen(passwd)   );
    return r;
}


