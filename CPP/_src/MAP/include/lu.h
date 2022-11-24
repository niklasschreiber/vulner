// ------------------------------------------------------------------------------------
//
//  File Name   : cancloc.h
//
//  Created     : 03-09-2012
// ------------------------------------------------------------------------------------
//  Description : MAP Location Update IMSI GSM/GPRS V2/V3 structure
//
//
//  Last Change : 04-09-2012
//
// ------------------------------------------------------------------------------------
#ifndef _LU_H
#define _LU_H

#include <E2TCA2.H> nolist
#include <E2TCUP.H> nolist
#include <E2TCDF.H> nolist
#include <E2TCWB.H> nolist
#include <E2TCXT.H> nolist
#include <mapty.h>
#include <maputil.h>

#define LU_GSM_OperationCode   2
#define LU_GPRS_OperationCode 23

/* --------------------------------------------------------------------------------------
updateLocation OPERATION  (V2 / V3 )
ARGUMENT
	updateLocationArg SEQUENCE {
		imsi OCTET STRING ( SIZE (3 .. 8 ) ),
	...
	...
	...
::= localValue : 2

updateGprsLocation OPERATION
ARGUMENT
	updateGprsLocationArg SEQUENCE {
		imsi OCTET STRING ( SIZE (3 .. 8 ) ),
	...
	...
	...
::= localValue : 23
-------------------------------------------------------------------------------------- */

// ------------------------------------------------------------------------------------------------

int MAP_Encode_GSM_IMSI_LU_ARGUMENT_Operation( INS_String *imsi,
		 	 	 	 	 	 	 	 	 	   E2TCEL *cmpnt,
		 	 	 	 	 	 	 	 	 	   int *numComp );

int MAP_Encode_GPRS_IMSI_LU_ARGUMENT_Operation( INS_String *imsi,
		 	 	 	 	 	 	 	 	 	    E2TCEL *cmpnt,
		 	 	 	 	 	 	 	 	 	    int *numComp );

int MAP_Decode_IMSI_LU_ARGUMENT( INS_String *imsi,
								 struct ComponentParameter    *cmpnt);

// -------------------------------------------------------------------------------------------------

#endif
