/* -------------------------------------------------------------------------
+  Project : Traffic Steering
+
+  -------------------------------------------------------------------------
+ MODULE: lu.c
+
+ MODULE TYPE:
+ Location Update GSM/GPRS encode/decode IMSI function
+
+ FULL DESCRIPTION:
+ This module contains encode/decode IMSI function to be used in conjunction
+ with the TFS JPN context
+
+ FUNCTIONS DEFINED:
+ None.
+
+ DATA DEFINED:
+ N/A
+
+  -------------------------------------------------------------------------
+
+
+
+  -------------------------------------------------------------------------
+  History :
+
+  03-09-2012 - initial version
+  
+  Last Change : 04-09-2012
+
+  ------------------------------------------------------------------------- */
#include <string.h>
#include <strings.h>
#include <mapty.h>
#include <maputil.h>
#include "lu.h"

static struct MAP_LU_storage
{
	INS_String  imsi;
}MAP_LU_Data;

#define E2TCTAG_GSM_GPRS_UpdateLocation_IMSI			((void *) 0x04000000)

/* ------------------------------------------------------------------------- */
int MAP_Encode_IMSI_LU_ARGUMENT( INS_String *imsi,
								 E2TCEL *cmpnt,
								 int *numComp );

char localOpCode_LU_GSM  = LU_GSM_OperationCode;  // CODE local 2
char localOpCode_LU_GPRS = LU_GPRS_OperationCode; // CODE local 23
/* ------------------------------------------------------------------------- */

int MAP_Encode_GSM_IMSI_LU_ARGUMENT_Operation( INS_String *imsi,
		 	 	 	 	 	 	 	 	 	   E2TCEL *cmpnt,
		 	 	 	 	 	 	 	 	 	   int *numComp )
{
	unsigned char   origin_level = 3;
    int				num;
    int				i_ret;
	E2TCEL			*pCur;

    pCur = cmpnt;

    pCur->flags           = E2TCFLG_TAG;
    pCur->len_or_domain   = origin_level;
    (pCur++)->data_or_tag = E2TCTAG_WB_OC_L;

    pCur->flags           = E2TCFLG_DATAPTR;
    pCur->len_or_domain   = sizeof(char);

    (pCur++)->data_or_tag = (char *)(&localOpCode_LU_GSM);

	// set temporary internal struct to 0x4A value
    memset( &MAP_LU_Data,
    		0x4A,
    		sizeof(struct MAP_LU_storage) );

    i_ret = MAP_Encode_IMSI_LU_ARGUMENT( imsi,
										 pCur,
										 &num );

    if( i_ret == MAP_SUCCESS)
	{
	    pCur += num;
		*numComp = pCur - cmpnt;
	}

    return  i_ret;
}

int MAP_Encode_GPRS_IMSI_LU_ARGUMENT_Operation( INS_String *imsi,
		 	 	 	 	 	 	 	 	 	    E2TCEL *cmpnt,
		 	 	 	 	 	 	 	 	 	    int *numComp )
{
	unsigned char   origin_level = 3;
    int				num;
    int				i_ret;
	E2TCEL			*pCur;

    pCur = cmpnt;

    pCur->flags           = E2TCFLG_TAG;
    pCur->len_or_domain   = origin_level;
    (pCur++)->data_or_tag = E2TCTAG_WB_OC_L;

    pCur->flags           = E2TCFLG_DATAPTR;
    pCur->len_or_domain   = sizeof(char);

    (pCur++)->data_or_tag = (char *)(&localOpCode_LU_GPRS);

	// set temporary internal struct to 0x4A value
    memset( &MAP_LU_Data,
    		0x4A,
    		sizeof(struct MAP_LU_storage) );

    i_ret = MAP_Encode_IMSI_LU_ARGUMENT( imsi,
										 pCur,
										 &num );

    if( i_ret == MAP_SUCCESS)
	{
	    pCur += num;
		*numComp = pCur - cmpnt;
	}

    return  i_ret;
}

int MAP_Decode_IMSI_LU_ARGUMENT( INS_String *imsi,
								 struct ComponentParameter    *cmpnt )
{
    int		ret = MAP_SUCCESS;
    int		offset = 0;

    imsi->length = 0;

    if( cmpnt->SEL_entries > 0 )
	{
		if( *(cmpnt->SEL_Entry[offset].tag) == 0x30 && // E2TCTAG_WB_PSEQID
			 ( *(cmpnt->SEL_Entry[offset + 1].tag) == 0x04 && // E2TCTAG_GSM_GPRS_UpdateLocation_IMSI
			 ( cmpnt->SEL_Entry[offset + 1].len >= 3 || cmpnt->SEL_Entry[offset + 1].len <= 8 ) ) )
		{
			offset++;

			// IMSI
			if( (ret = DecodeTBCD2INS_String( (unsigned char *) cmpnt->SEL_Entry[offset].data,
											   cmpnt->SEL_Entry[offset].len,
											   imsi )) != MAP_SUCCESS )
			{
				ret = MAP_ERNUM_MISTYPED_PARAMETER;
			}
		}
		else
			ret = MAP_ERNUM_MISTYPED_PARAMETER;
	}
	else
		ret = MAP_ERNUM_MISTYPED_PARAMETER;

	return ret;
}

/* -------------------------------------------------------------------------
+  MAP_Encode_IMSI_LU_ARGUMENT  GSM V2/V3 e GPRS V3
+  ------------------------------------------------------------------------- */
int MAP_Encode_IMSI_LU_ARGUMENT( INS_String *imsi,
								 E2TCEL *cmpnt,
								 int *numComp )
{
    int             ret = MAP_SUCCESS;
    int             len;
	unsigned char   origin_level = 3;
    E2TCEL          *pCur;

    pCur = cmpnt;

	if( imsi->length >= 5 &&
		imsi->length <= 16 )
	{
		// SEQUENCE
		pCur->flags           = E2TCFLG_TAG;
		pCur->len_or_domain   = (unsigned char) (origin_level);
		(pCur++)->data_or_tag = E2TCTAG_WB_PSEQID;	// 0x30

		pCur->flags           = E2TCFLG_TAG;
		pCur->len_or_domain   = (unsigned char) (origin_level + 1);
		(pCur++)->data_or_tag = E2TCTAG_GSM_GPRS_UpdateLocation_IMSI;

		if( ( ret = EncodeINS_String2TBCD( imsi,
										   MAP_LU_Data.imsi.value,
										   &len ) ) == MAP_SUCCESS )
		{
			MAP_LU_Data.imsi.length = (short) len;

			pCur->flags           = E2TCFLG_DATAPTR;
			pCur->len_or_domain   = (unsigned char) MAP_LU_Data.imsi.length;
			(pCur++)->data_or_tag = &(MAP_LU_Data.imsi.value);
		}
		else
			return MAP_ERNUM_API_ERROR;
	}
	else
		return MAP_ERNUM_API_ERROR;

    *numComp = pCur - cmpnt;

    return ret;
}

/* ------------------------------< eof >---------------------------------- */
