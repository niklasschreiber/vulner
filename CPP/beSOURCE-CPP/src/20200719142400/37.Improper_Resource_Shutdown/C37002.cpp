//
// 
//

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sql.h>
#include <sqlext.h>
#include <sqltypes.h>
#include <sqlucode.h>
#include <odbcinst.h>
#include <netdb.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>

// 
void sqlDB()
{
     SQLHANDLE env_hd, con_hd;
                
     SQLAllocHandle(SQL_HANDLE_ENV, SQL_NULL_HANDLE, &env_hd);
     SQLAllocHandle(SQL_HANDLE_DBC, env_hd, &con_hd);
                
     /* do transactions */
                
}

// 
void serverSock()
{
     struct sockaddr_in serverAddr;
     struct sockaddr *server = (struct sockaddr *)(&serverAddr);
     int listenFd = socket(AF_INET, SOCK_STREAM, 0);
                
     bind(listenFd, server, sizeof(serverAddr));
     listen(listenFd, 5);
     while (1) {
        int connectFd = accept(listenFd, (struct sockaddr *) NULL, NULL);
        /* do read/write operations */
        shutdown(connectFd, 2);
     }
}

