#include <stdio.h>
#include <stdlib.h>
#include <ldap.h>

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
*/

int anonyLDAP_bind(LDAP *ld)
{
    unsigned long rc;

    ldap_simple_bind_s(ld, NULL, NULL);
    if (rc != LDAP_SUCCESS) 
       return 0;
    return 1;
}
