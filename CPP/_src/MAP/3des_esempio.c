int encrypt1 (char *output, char *input, short input_len, char *key, short key_len)
{
 md5_state_t  MD5;
 unsigned char digest [16];
 int i;
 unsigned char buffer[1024+8];
 unsigned char buffer2[8];
 unsigned char buffer3[8];
 
 *((long long *)buffer)=input_len;
 memcpy (buffer+8,input,input_len);
 memset (buffer+8+input_len, 0, sizeof(buffer)-input_len-8);
 
 md5_init(&MD5);
 md5_append(&MD5,key,key_len);
 md5_finish(&MD5,digest);
 
 for (i = 0; i<1024+8; i+=8)
 {
     des ((BYTE *)buffer2, (BYTE *)(buffer+i), CHIFFRE, (BYTE *)key);
  if (i)
  {
      des ((BYTE *)buffer3, (BYTE *)buffer2, CHIFFRE, (BYTE *)(key+8));
      des ((BYTE *)(output+i), (BYTE *)buffer3, CHIFFRE, (BYTE *)(output+i-8));
  }
  else
  {
      des ((BYTE *)(output+i), (BYTE *)buffer2, CHIFFRE, (BYTE *)(key+8));
  }
  // output[i] = input[i]^digest[i%16];
 }
 
 return 0;
}
 
int decrypt1 (char *output, short *output_len, char *input, char *key, short key_len)
{
 char buffer[1024+8];
 md5_state_t  MD5;
 unsigned char digest [16];
 unsigned char buffer2[8];
 unsigned char buffer3[8];
 int i;
 
 md5_init(&MD5);
 md5_append(&MD5,key,key_len);
 md5_finish(&MD5,digest);
 
 for (i = 0; i<1024+8; i+=8)
 {
  if (i)
  {
      des ((BYTE *)buffer3, (BYTE *)(input+i), DECHIFFRE, (BYTE *)(input+i-8));
   des ((BYTE *)buffer2, (BYTE *)buffer3, DECHIFFRE, (BYTE *)(key+8));
  }
  else
   des ((BYTE *)buffer2, (BYTE *)(input+i), DECHIFFRE, (BYTE *)(key+8));
 
     des ((BYTE *)(buffer+i), (BYTE *)buffer2, DECHIFFRE, (BYTE *)key);
  // output[i] = input[i]^digest[i%16];
 }
 
 memcpy(output, buffer + 8, 1024);
 *output_len = (short)*((long long *)buffer);
 
 return 0;
}

