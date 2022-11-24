#include <stdafx.h>
#include <stdio.h>
#include <string.h>

extern char *getPassword(char *buf, int buflen);
extern char *getID(char *buf, int buflen);

int loginToClient(char *id, char *passwd);

int main()
{
	char id[20];
	char passwd[20];

	getID(id, 20);
    getPassword(passwd, 20);

    printf("id = %s, password = %s\n", id, passwd);

	if ( loginToClient(id, passwd) != 0 )
	{
		// ... //
	}

	return 0;
}

int loginToClient(char *id, char *passwd)
{
	int flag = 0;

	// ... //

	return flag;
}

