//

#include <stdlib.h>
#include <sql.h>

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
*/


void f(SQLHSTMT sqlh) {
	char *query = getenv("query_string");
 	SQLExecDirect(sqlh, query, SQL_NTS);
}
