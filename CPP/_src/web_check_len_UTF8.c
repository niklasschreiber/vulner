/*****************************************************************************
 //
 // <Encode_UTF8_SMS.c>: Defines the main function
 //
 *****************************************************************************/
// 11/03/2013 Corrected PDU length for 7bit non concatenated SMS

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include "smpdu.h"
#include "web_func.h"

#define ITEM_SIZE       3000


/* ***************************************************************************
 * 	<Encode_UTF8_SMS.h>: include file for standard system include files,
 *      or project specific include files that are used frequently.
 */


struct encode_utf8_data
{
	unsigned char flat_ucs2[2*255*160];
	unsigned char flat_gsm[2*255*160];
	int utf8_len;
	int ucs2_len;
	int gsm_len;
	unsigned short msgref;
	unsigned short msgtotal;
	unsigned short msgpartial;
	int offset;
	unsigned char dcs;	// 0 = GSM; 8= UCS2
};

struct encode_utf8_data STATUS;
//************************************************************


unsigned char Encode_UTF8_msgref = 0;

typedef enum
{
	ok, /* conversion successful */
	sourceExhausted, /* partial character in source, but hit end */
	targetExhausted
/* insuff. room in target for conversion */
} ConversionResult;

typedef unsigned long UCS4;
typedef unsigned short UCS2;
typedef unsigned short UTF16;
typedef unsigned char UTF8;

const int halfShift = 10;
const UCS4 halfBase = 0x0010000UL;
const UCS4 halfMask = 0x3FFUL;
const UCS4 kSurrogateHighStart = 0xD800UL;
const UCS4 kSurrogateHighEnd = 0xDBFFUL;
const UCS4 kSurrogateLowStart = 0xDC00UL;
const UCS4 kSurrogateLowEnd = 0xDFFFUL;

const UCS4 kReplacementCharacter = 0x0000FFFDUL;
const UCS4 kMaximumUCS2 = 0x0000FFFFUL;
const UCS4 kMaximumUTF16 = 0x0010FFFFUL;
const UCS4 kMaximumUCS4 = 0x7FFFFFFFUL;

ConversionResult ConvertUTF8toUTF16(UTF8** sourceStart, UTF8* sourceEnd,
		UTF16** targetStart, const UTF16* targetEnd);
unsigned char utf2gsm(unsigned char *output, int *olen, unsigned char *input,
		int ilen);
int Encode_UTF8_No_SMS(unsigned char *utf8input, struct encode_utf8_data *status);
short Check_LenMsg( char  msg_txt[ITEM_SIZE], short nTipoMsg, int lenMsg, char *acNome );
short num_conc( char  *msg_txt );

extern unsigned char Encode_UTF8_msgref;

// returns 0 OK - 2 LAST MESSAGE - 3 ERROR
int Encode_UTF8_No_SMS(unsigned char *utf8input, struct encode_utf8_data *status)
{
	int ret = 0;
	int msglen = 0;

	int i_bitoffset = 0;
	int i_udhl_septet = 0;

	int msgtotal = 0;

	unsigned char *sourceStart;
	unsigned char *sourceEnd;
	unsigned char *targetStart;
	unsigned char *targetEnd;

	// Parse utf8 to count symbols (maybe)
	// Convert to UCS2
	if (utf8input)
	{
		// Initialize status
		status->msgref = (Encode_UTF8_msgref++) & 0xff;
		status->msgtotal = 0;
		status->msgpartial = 0;
		status->offset = 0;

		// Initialize converter
		status->utf8_len = strlen(utf8input);
		sourceStart = utf8input;

		// Convert to UTF16
		sourceEnd = sourceStart + status->utf8_len;
		targetStart = status->flat_ucs2;
		targetEnd = status->flat_ucs2 + sizeof(status->flat_ucs2);
		ConvertUTF8toUTF16((UTF8 **) &sourceStart, (UTF8 *) sourceEnd,
				(UTF16 **) &targetStart, (UTF16 *) targetEnd);
		status->ucs2_len = targetStart - status->flat_ucs2;

		status->dcs = utf2gsm(status->flat_gsm, &status->gsm_len,
				status->flat_ucs2, status->ucs2_len);

		if (status->dcs == 8)
		{
			// Compute number of segments
			if (status->ucs2_len > 140)
				msgtotal = (status->ucs2_len + 140 - 6 - 1) / (140 - 6);
			else
				msgtotal = 1;
		}
		else
		{
			// Compute number of segments
			if (status->gsm_len > 160)
				msgtotal = (status->gsm_len + 160 - 7 - 1) / (160 - 7);
			else
				msgtotal = 1;
		}
		status->msgtotal = (msgtotal <= 255) ? msgtotal : 255;
	}

	status->msgpartial++;
	ret = (status->msgpartial <= status->msgtotal) ? 0 : 2;

	return ret;
}

UCS4 offsetsFromUTF8[6] =
{ 0x00000000UL, 0x00003080UL, 0x000E2080UL, 0x03C82080UL, 0xFA082080UL,
		0x82082080UL };
char bytesFromUTF8[256] =
{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
		0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
		0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
		0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
		0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
		0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
		0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
		0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1,
		1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
		1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 3, 3,
		3, 3, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5 };

ConversionResult ConvertUTF8toUTF16(UTF8** sourceStart, UTF8* sourceEnd,
		UTF16** targetStart, const UTF16* targetEnd)
{
	ConversionResult result = ok;
	register UTF8* source = *sourceStart;
	register UTF16* target = *targetStart;
	while (source < sourceEnd)
	{
		register UCS4 ch = 0;
		register unsigned short extraBytesToWrite = bytesFromUTF8[*source];
		if (source + extraBytesToWrite > sourceEnd)
		{
			result = sourceExhausted;
			break;
		};
		switch (extraBytesToWrite)
		{ /* note: code falls through cases! */
		case 5:
			ch += *source++;
			ch <<= 6;
		case 4:
			ch += *source++;
			ch <<= 6;
		case 3:
			ch += *source++;
			ch <<= 6;
		case 2:
			ch += *source++;
			ch <<= 6;
		case 1:
			ch += *source++;
			ch <<= 6;
		case 0:
			ch += *source++;
		};
		ch -= offsetsFromUTF8[extraBytesToWrite];

		if (target >= targetEnd)
		{
			result = targetExhausted;
			break;
		};
		if (ch <= kMaximumUCS2)
		{
			*target++ = ch;
		}
		else if (ch > kMaximumUTF16)
		{
			*target++ = kReplacementCharacter;
		}
		else
		{
			if (target + 1 >= targetEnd)
			{
				result = targetExhausted;
				break;
			};
			ch -= halfBase;
			*target++ = (ch >> halfShift) + kSurrogateHighStart;
			*target++ = (ch & halfMask) + kSurrogateLowStart;
		};
	};
	*sourceStart = source;
	*targetStart = target;
	return result;
}

// 8bit msgref
// 1 - Length of User Data Header, in this case 05.
// 2 - Information Element Identifier, equal to 00 (Concatenated short messages, 8-bit reference number)
// 3 - Length of the header, excluding the first two fields; equal to 03
// 4 - 00-FF, CSMS reference number, must be same for all the SMS parts in the CSMS
// 5 - 00-FF, total number of parts. The value shall remain constant for every short message which makes up the concatenated short message. If the value is zero then the receiving entity shall ignore the whole information element
// 6 - 00-FF, this part's number in the sequence. The value shall start at 1 and increment for every short message which makes up the concatenated short message. If the value is zero or greater than the value in Field 5 then the receiving entity shall ignore the whole information element.

// 16bit msgref
// 1 - Length of User Data Header (UDL), in this case 6.
// 2 - Information Element Identifier, equal to 08 (Concatenated short messages, 16-bit reference number)
// 3 - Length of the header, excluding the first two fields; equal to 04
// 4 - 0000-FFFF, CSMS reference number, must be same for all the SMS parts in the CSMS
// 6 - 00-FF, total number of parts. The value shall remain constant for every short message which makes up the concatenated short message. If the value is zero then the receiving entity shall ignore the whole information element
// 7 - 00-FF, this part's number in the sequence. The value shall start at 1 and increment for every short message which makes up the concatenated short message. If the value is zero or greater than the value in Field 5 then the receiving entity shall ignore the whole information element.

// TP-DCS
// 00 GSM 7 bit default alphabet
// 08 UCS2 (16bit)

// (140-6)/2=67 UCS2 symbols

// TP-UDL is in octects for UCS2

struct utf_gsm
{
	unsigned short gsm;
	unsigned short utf;
}const utf_gsm_table[] =
{ 0x00, 0x0040, //	COMMERCIAL AT
		0x01, 0x00A3, //	POUND SIGN
		0x02, 0x0024, //	DOLLAR SIGN
		0x03, 0x00A5, //	YEN SIGN
		0x04, 0x00E8, //	LATIN SMALL LETTER E WITH GRAVE
		0x05, 0x00E9, //	LATIN SMALL LETTER E WITH ACUTE
		0x06, 0x00F9, //	LATIN SMALL LETTER U WITH GRAVE
		0x07, 0x00EC, //	LATIN SMALL LETTER I WITH GRAVE
		0x08, 0x00F2, //	LATIN SMALL LETTER O WITH GRAVE
		0x09, 0x00E7, //	LATIN SMALL LETTER C WITH CEDILLA
		0x09, 0x00C7, //	LATIN CAPITAL LETTER C WITH CEDILLA (see note above)
		0x0A, 0x000A, //	LINE FEED
		0x0B, 0x00D8, //	LATIN CAPITAL LETTER O WITH STROKE
		0x0C, 0x00F8, //	LATIN SMALL LETTER O WITH STROKE
		0x0D, 0x000D, //	CARRIAGE RETURN
		0x0E, 0x00C5, //	LATIN CAPITAL LETTER A WITH RING ABOVE
		0x0F, 0x00E5, //	LATIN SMALL LETTER A WITH RING ABOVE
		0x10, 0x0394, //	GREEK CAPITAL LETTER DELTA
		0x11, 0x005F, //	LOW LINE
		0x12, 0x03A6, //	GREEK CAPITAL LETTER PHI
		0x13, 0x0393, //	GREEK CAPITAL LETTER GAMMA
		0x14, 0x039B, //	GREEK CAPITAL LETTER LAMDA
		0x15, 0x03A9, //	GREEK CAPITAL LETTER OMEGA
		0x16, 0x03A0, //	GREEK CAPITAL LETTER PI
		0x17, 0x03A8, //	GREEK CAPITAL LETTER PSI
		0x18, 0x03A3, //	GREEK CAPITAL LETTER SIGMA
		0x19, 0x0398, //	GREEK CAPITAL LETTER THETA
		0x1A, 0x039E, //	GREEK CAPITAL LETTER XI
		0x1B, 0x00A0, //	ESCAPE TO EXTENSION TABLE (or displayed as NBSP, see note above)
		0x1B0A, 0x000C, //	FORM FEED
		0x1B14, 0x005E, //	CIRCUMFLEX ACCENT
		0x1B28, 0x007B, //	LEFT CURLY BRACKET
		0x1B29, 0x007D, //	RIGHT CURLY BRACKET
		0x1B2F, 0x005C, //	REVERSE SOLIDUS
		0x1B3C, 0x005B, //	LEFT SQUARE BRACKET
		0x1B3D, 0x007E, //	TILDE
		0x1B3E, 0x005D, //	RIGHT SQUARE BRACKET
		0x1B40, 0x007C, //	VERTICAL LINE
		0x1B65, 0x20AC, //	EURO SIGN
		0x1C, 0x00C6, //	LATIN CAPITAL LETTER AE
		0x1D, 0x00E6, //	LATIN SMALL LETTER AE
		0x1E, 0x00DF, //	LATIN SMALL LETTER SHARP S (German)
		0x1F, 0x00C9, //	LATIN CAPITAL LETTER E WITH ACUTE
		0x20, 0x0020, //	SPACE
		0x21, 0x0021, //	EXCLAMATION MARK
		0x22, 0x0022, //	QUOTATION MARK
		0x23, 0x0023, //	NUMBER SIGN
		0x24, 0x00A4, //	CURRENCY SIGN
		0x25, 0x0025, //	PERCENT SIGN
		0x26, 0x0026, //	AMPERSAND
		0x27, 0x0027, //	APOSTROPHE
		0x28, 0x0028, //	LEFT PARENTHESIS
		0x29, 0x0029, //	RIGHT PARENTHESIS
		0x2A, 0x002A, //	ASTERISK
		0x2B, 0x002B, //	PLUS SIGN
		0x2C, 0x002C, //	COMMA
		0x2D, 0x002D, //	HYPHEN-MINUS
		0x2E, 0x002E, //	FULL STOP
		0x2F, 0x002F, //	SOLIDUS
		0x30, 0x0030, //	DIGIT ZERO
		0x31, 0x0031, //	DIGIT ONE
		0x32, 0x0032, //	DIGIT TWO
		0x33, 0x0033, //	DIGIT THREE
		0x34, 0x0034, //	DIGIT FOUR
		0x35, 0x0035, //	DIGIT FIVE
		0x36, 0x0036, //	DIGIT SIX
		0x37, 0x0037, //	DIGIT SEVEN
		0x38, 0x0038, //	DIGIT EIGHT
		0x39, 0x0039, //	DIGIT NINE
		0x3A, 0x003A, //	COLON
		0x3B, 0x003B, //	SEMICOLON
		0x3C, 0x003C, //	LESS-THAN SIGN
		0x3D, 0x003D, //	EQUALS SIGN
		0x3E, 0x003E, //	GREATER-THAN SIGN
		0x3F, 0x003F, //	QUESTION MARK
		0x40, 0x00A1, //	INVERTED EXCLAMATION MARK
		0x41, 0x0041, //	LATIN CAPITAL LETTER A
		0x42, 0x0042, //	LATIN CAPITAL LETTER B
		0x43, 0x0043, //	LATIN CAPITAL LETTER C
		0x44, 0x0044, //	LATIN CAPITAL LETTER D
		0x45, 0x0045, //	LATIN CAPITAL LETTER E
		0x46, 0x0046, //	LATIN CAPITAL LETTER F
		0x47, 0x0047, //	LATIN CAPITAL LETTER G
		0x48, 0x0048, //	LATIN CAPITAL LETTER H
		0x49, 0x0049, //	LATIN CAPITAL LETTER I
		0x4A, 0x004A, //	LATIN CAPITAL LETTER J
		0x4B, 0x004B, //	LATIN CAPITAL LETTER K
		0x4C, 0x004C, //	LATIN CAPITAL LETTER L
		0x4D, 0x004D, //	LATIN CAPITAL LETTER M
		0x4E, 0x004E, //	LATIN CAPITAL LETTER N
		0x4F, 0x004F, //	LATIN CAPITAL LETTER O
		0x50, 0x0050, //	LATIN CAPITAL LETTER P
		0x51, 0x0051, //	LATIN CAPITAL LETTER Q
		0x52, 0x0052, //	LATIN CAPITAL LETTER R
		0x53, 0x0053, //	LATIN CAPITAL LETTER S
		0x54, 0x0054, //	LATIN CAPITAL LETTER T
		0x55, 0x0055, //	LATIN CAPITAL LETTER U
		0x56, 0x0056, //	LATIN CAPITAL LETTER V
		0x57, 0x0057, //	LATIN CAPITAL LETTER W
		0x58, 0x0058, //	LATIN CAPITAL LETTER X
		0x59, 0x0059, //	LATIN CAPITAL LETTER Y
		0x5A, 0x005A, //	LATIN CAPITAL LETTER Z
		0x5B, 0x00C4, //	LATIN CAPITAL LETTER A WITH DIAERESIS
		0x5C, 0x00D6, //	LATIN CAPITAL LETTER O WITH DIAERESIS
		0x5D, 0x00D1, //	LATIN CAPITAL LETTER N WITH TILDE
		0x5E, 0x00DC, //	LATIN CAPITAL LETTER U WITH DIAERESIS
		0x5F, 0x00A7, //	SECTION SIGN
		0x60, 0x00BF, //	INVERTED QUESTION MARK
		0x61, 0x0061, //	LATIN SMALL LETTER A
		0x62, 0x0062, //	LATIN SMALL LETTER B
		0x63, 0x0063, //	LATIN SMALL LETTER C
		0x64, 0x0064, //	LATIN SMALL LETTER D
		0x65, 0x0065, //	LATIN SMALL LETTER E
		0x66, 0x0066, //	LATIN SMALL LETTER F
		0x67, 0x0067, //	LATIN SMALL LETTER G
		0x68, 0x0068, //	LATIN SMALL LETTER H
		0x69, 0x0069, //	LATIN SMALL LETTER I
		0x6A, 0x006A, //	LATIN SMALL LETTER J
		0x6B, 0x006B, //	LATIN SMALL LETTER K
		0x6C, 0x006C, //	LATIN SMALL LETTER L
		0x6D, 0x006D, //	LATIN SMALL LETTER M
		0x6E, 0x006E, //	LATIN SMALL LETTER N
		0x6F, 0x006F, //	LATIN SMALL LETTER O
		0x70, 0x0070, //	LATIN SMALL LETTER P
		0x71, 0x0071, //	LATIN SMALL LETTER Q
		0x72, 0x0072, //	LATIN SMALL LETTER R
		0x73, 0x0073, //	LATIN SMALL LETTER S
		0x74, 0x0074, //	LATIN SMALL LETTER T
		0x75, 0x0075, //	LATIN SMALL LETTER U
		0x76, 0x0076, //	LATIN SMALL LETTER V
		0x77, 0x0077, //	LATIN SMALL LETTER W
		0x78, 0x0078, //	LATIN SMALL LETTER X
		0x79, 0x0079, //	LATIN SMALL LETTER Y
		0x7A, 0x007A, //	LATIN SMALL LETTER Z
		0x7B, 0x00E4, //	LATIN SMALL LETTER A WITH DIAERESIS
		0x7C, 0x00F6, //	LATIN SMALL LETTER O WITH DIAERESIS
		0x7D, 0x00F1, //	LATIN SMALL LETTER N WITH TILDE
		0x7E, 0x00FC, //	LATIN SMALL LETTER U WITH DIAERESIS
		0x7F, 0x00E0, //	LATIN SMALL LETTER A WITH GRAVE
		0x00, 0x0000 //	NULL (see note above)
		};

// Tries to convert utf2gsm
unsigned char utf2gsm(unsigned char *output, int *olen, unsigned char *input,
		int ilen)
{
	int i = 0;
	int x, f;
	unsigned short ci, co;
	int elements = sizeof(utf_gsm_table) / sizeof(struct utf_gsm);
	for (i = *olen = 0; i < ilen; i += 2)
	{
		ci = *(unsigned short *) (input + i);
		for (x = f = 0; x < elements; x++)
		{
			if (ci == utf_gsm_table[x].utf)
			{
				f = 1;
				co = utf_gsm_table[x].gsm;
				break;
			}
		}
		if (f)
		{
			if (co & 0xff00)
			{
				output[*olen] = co >> 8;
				*olen += 1;
			}

			output[*olen] = co & 0xff;
			*olen += 1;
		}
		else
		{
			//output[*olen] = 0;  // Per codificare sempre in GSM7
			//*olen += 1;
			return 8;
		}
	}
	return 0;
}

//***************************************************************************************
//Controlla la lunghezza del messaggio
// nTipoMsg = 0 testo del messaggio
// nTipoMsg = 1 descrizione set o gruppo
//***************************************************************************************
short Check_LenMsg( char  msg_txt[ITEM_SIZE], short nTipoMsg, int lenMsg, char *acNome )
{
	short rc = 0;
	short uret;
	char sTmp[40];
	Deliver  deliver;

	// fabios func
	memset(&deliver, 0x00, sizeof(deliver));
	uret = Encode_UTF8_No_SMS(msg_txt,  &STATUS);

	// serve x evetiuale alert della Check_LenMsg
	if (disp_Top == 0)
		Display_TOP("");
	//*********************** GSM ***************************************
	if(STATUS.dcs == 0)
	{
		// ****************************************************************
		// controllo lunghezza del MESSAGGIO (SMS)
		// doppio controllo su 1200 ascii e 1800 utf8
		// ***************************************************************
		if (nTipoMsg == 0)
		{
			if(STATUS.gsm_len > 1200)
			{
				printf("<script language='JavaScript'>\n\
						alert('Error: message too long. Maximum size for a message is 1200 octets.\\n\\nUTF8=' +%d + ' bytes\\nGSM='+ %d +' bytes');\n\
						history.back();\n\
						</script>\n",
						STATUS.utf8_len,
						STATUS.gsm_len);
				rc = 1;
			}
			else if(STATUS.utf8_len > 1800)
			{
				printf("<script language='JavaScript'>\n\
						alert('Error: message too long. Maximum size for a message is 1200 octets(GSM) and 1800 UTF8.\\n\\nUTF8=' +%d + ' bytes\\nGSM='+ %d +' bytes');\n\
						history.back();\n\
						</script>\n",
						STATUS.utf8_len,
						STATUS.gsm_len);
				rc = 1;
			}
		}
		else
		{
			// ****************************************************************
			// controllo lunghezza DESCRIZIONI VARIE
			// controllo UTF8
			// ***************************************************************
			if(STATUS.utf8_len > lenMsg)
			{
				printf("<script language='JavaScript'>\n\
						alert('Error: Description too long. Maximum size for a %s is %d bytes UTF8.\\n\\nUTF8=%d bytes ');\n\
						history.back();\n\
						</script>\n",
						acNome,
						lenMsg,
						STATUS.utf8_len);

				rc = 1;
			}
		}

	}
	//*********************** UCS2 ***************************************
	else
	{
		if (nTipoMsg == 0)  //controllo lunghezza del messaggio
		{
			if(STATUS.ucs2_len > 1200)
			{
				printf("<script language='JavaScript'>\n\
						alert('Error: message too long. Maximum size for a message is 600 UCS-2 characters.\\n\\nUTF8=' +%d + ' bytes\\nUCS2=' +%d +' bytes ('+ %d +' codes)' );\n\
						history.back();\n\
						</script>\n",
						STATUS.utf8_len,
						STATUS.ucs2_len,
						STATUS.ucs2_len/2);
				rc = 1;

			}
			else if(STATUS.utf8_len > 1800)
			{
				printf("<script language='JavaScript'>\n\
						alert('Error: message too long. Maximum size for a message is 600 UCS-2 and 1800 UTF8.\\n\\nUTF8=' +%d + ' bytes\\nUCS2=' +%d +' bytes ('+ %d +' codes)' );\n\
						history.back();\n\
						</script>\n",
						STATUS.utf8_len,
						STATUS.ucs2_len,
						STATUS.ucs2_len/2);
				rc = 1;
			}
		}
		else
		{	//controllo che la lunghezza UTF8 varie descrizioni
			// controllo solo UTF8 x scrittura nel DB
			if(STATUS.utf8_len > lenMsg)
			{
				printf("<script language='JavaScript'>\n\
						alert('Error: Description too long. Maximum size for a %s is %d bytes UTF8.\\n\\nUTF8=%d bytes');\n\
						history.back();\n\
						</script>\n",
						acNome,
						lenMsg,
						STATUS.utf8_len);

				rc = 1;
			}
		}
	}
	return rc;
}

//***************************************************************************************
//restituisce il numero di quanti concatenatiè formato il messaggio
//***************************************************************************************
short num_conc( char  *msg_txt )
{
	Deliver deliver;

	STATUS.msgtotal = 0;
	//fabios func
	memset(&deliver, 0x00, sizeof(deliver));
	Encode_UTF8_No_SMS(msg_txt,  &STATUS);

	return STATUS.msgtotal;

}
