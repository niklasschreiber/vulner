#include <stdio.h>
#include <string.h>
#include <memory.h>
#include <openssl/evp.h>
#include <openssl/pem.h>
#include <openssl/rsa.h>
 
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
*/
void encryption_init()
{
   EVP_CIPHER_CTX ctx;

   EVP_CIPHER_CTX_init(&ctx);
   EVP_EncryptInit(&ctx, EVP_des_ecb(), NULL, NULL); /* DES usage */
}

