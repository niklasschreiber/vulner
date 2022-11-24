#include <stdio.h>
#include <netinet/in.h>
#include <stdlib.h>
#include <string.h>



int main() {
  char* rPort = getenv("rPort");
  struct sockaddr_in serv_addr;
  int sockfd = 0;
  char buf[25];


  strncpy(buf, rPort, 25);

  if (connect(sockfd,(struct sockaddr *)&buf,sizeof(serv_addr)) < 0)
    error("ERROR connecting");
}

