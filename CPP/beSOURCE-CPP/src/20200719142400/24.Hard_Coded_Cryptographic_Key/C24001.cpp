/*
 * 
 *
 * 
 * 
 */

extern char *salt;

typedef int SQLSMALLINT ;

int cwe321_bad(char *user, char *passwd)
{
    char *server = "DBserver";
    char *cpasswd;
    SQLHENV henv;
    SQLHDBC hdbc;

    SQLAllocHandle(SQL_HANDLE_ENV, SQL_NULL_HANDLE, &henv);
    SQLAllocHandle(SQL_HANDLE_DBC, henv, &hdbc);

    cpasswd = crypt(passwd, salt);
    if (strcmp(cpasswd, "68af404b513073582b6c63e6b") != 0) {      /*  */
        printf("Incorrect password\n");
        return -1;
    }
	
    SQLConnect(hdbc,
               (SQLCHAR*) server,
               (SQLSMALLINT) strlen(server),
               (SQLCHAR*) user,
               (SQLSMALLINT) strlen(user),
               (SQLCHAR*) passwd,
               (SQLSMALLINT) strlen(passwd)   );
    return 0;
}
