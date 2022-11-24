//
// 
//

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <netdb.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>

int decision(char *ip_addr_string) 
{
    struct hostent *hp;
    struct in_addr myaddr;
    char *tHost = "trustme.trusty.com";
    myaddr.s_addr = inet_addr(ip_addr_string);
         
    hp = (struct hostent *)gethostbyaddr((char *)&myaddr, sizeof(struct in_addr), AF_INET);
    if (hp && !strncmp(hp->h_name, tHost, sizeof(tHost))) 
         return 1; //  
    else 
         return 0; // 
}

