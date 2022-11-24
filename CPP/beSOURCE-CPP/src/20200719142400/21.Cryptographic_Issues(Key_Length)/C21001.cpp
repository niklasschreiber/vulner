#include <stdio.h>
#include <stdlib.h>
#include <openssl/rsa.h>
#include <openssl/evp.h>

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
*
*/

EVP_PKEY *RSAKey()
{
    EVP_PKEY *pkey;
    RSA *rsa;

    rsa = RSA_generate_key(512, 35, NULL, NULL);  /*  */
    if (rsa == NULL) {
        printf("Error\n");
        return NULL;
    }	
    pkey = EVP_PKEY_new();
    EVP_PKEY_assign_RSA(pkey, rsa);
    return pkey;
}

/**
* 
* 
 
  
  
  
  

  
  
  
  
  
  
  
  
  
*/
