//**************************************
// Name: ESN Converter
// Description:Converts Cellular Phone ESN from HEX to DEC format.
// By: S. Lyle Raymond
//
//This code is copyrighted and has// limited warranties.Please see http://www.Planet-Source-Code.com/vb/scripts/ShowCode.asp?txtCodeId=6549&lngWId=3//for details.//**************************************

#include <stdio.h>
/* HEX to DEC converter
converts HEX ESN to DEC
 */
int returnDigit(char digit);
char digit;

int main()
{
	// AF 01 23 45 0A BC DE 
	char prefix[2]={0xA0,0x0F};
    int i, k, convertedPrefix;
	char suffix[5]={0x23,0x45,0x0A,0xBC,0xDE};
    int n, j;
    unsigned long int convertedSuffix;
/*
	printf("Enter the eight-digit hex ESN:\n");
    
    for (i=0; i<2; i++)
        prefix[i] = getchar();
 
    for (i=0; i<7; i++)
        suffix[i] = getchar();
*/
 /* Split two-digit prefix and six-digit suffix, then
assign int values to individual characters.
Error message displayed if input exceeds 0-F.
 */
    for (i=0; i<2; i++)
        prefix[i] = returnDigit(prefix[i]);
 
    for (i=0; i<6; i++)
        suffix[i] = returnDigit(suffix[i]);
    
    // Two digit prefix converted:
    convertedPrefix = (prefix[0] * 16) + prefix[1];

    // Six digit suffix converted:
    n = 16;
    convertedSuffix = suffix[5];
    k = 0;
 
    for (i=4; i>=0; i--) 
    {
        //find power of 16
        for (j=0; j<k; j++) 
        {
            n *= 16;
        }
        
        //multiply by digit in place i
        convertedSuffix += (suffix[i]*n);
        n = 16;
        k += 1;
    }

    printf("DEC ESN: %1.3d%1.8lu\n", convertedPrefix, convertedSuffix);
 
    return 0;
}

//DIGIT CONVERSION FUNCTION
int returnDigit(char digit) 
{
    switch (digit)
    {
        case 'a':
        case 'A':
            digit = (int)10;
            break;
        case 'b':
        case 'B':
            digit = (int)11;
            break;
        case 'c':
        case 'C':
            digit = (int)12;
            break;
        case 'd':
        case 'D':
            digit = (int)13;
            break;
        case 'e':
        case 'E':
            digit = (int)14;
            break;
        case 'f':
        case 'F':
            digit = (int)15;
            break;
        case '0':
        case '1':
        case '2':
        case '3':
        case '4':
        case '5':
        case '6':
        case '7':
        case '8':
        case '9':
            digit = (int)(digit - 48);
            break;
        default:
            printf("Invalid Entry: %c\n", digit);
            break;
    }
 
    return digit;
}

