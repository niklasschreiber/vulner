#include <stdio.h>
#include <ldap.h>

/*
 * 
 * 
 */

#define FIND_DN ""

int cwe90_bad() {
  // 
  char* filter = getenv("filter_string");
  int rc;
  LDAP *ld = NULL;
  LDAPMessage* result;

  //
  rc = ldap_search_ext_s( ld, FIND_DN, LDAP_SCOPE_BASE, filter, NULL, 0, NULL, NULL, LDAP_NO_LIMIT, LDAP_NO_LIMIT, &result);
}
