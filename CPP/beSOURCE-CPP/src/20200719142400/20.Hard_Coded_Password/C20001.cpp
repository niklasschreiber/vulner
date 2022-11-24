#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sqlext.h>

int dbaccess(char *server, char *user)
{
    SQLHENV henv;
    SQLHDBC hdbc;

    SQLAllocHandle(SQL_HANDLE_ENV, SQL_NULL_HANDLE, &henv);
    SQLAllocHandle(SQL_HANDLE_DBC, henv, &hdbc);

    SQLConnect(hdbc, 
	       (SQLCHAR*) server, 
	       strlen(server), 
	       user, 
	       strlen(user), 
	       "asdf",
	       4  );
    return 0;
}


