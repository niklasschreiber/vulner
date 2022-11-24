// ------------------------------------------------------------------------------
//   PROJECT : LTE-TFS v 01.00
// ------------------------------------------------------------------------------
//
//   File Name   : gttltedb.h
//   Last Change : 16-05-2013
//
// ------------------------------------------------------------------------------
//   Description
//   -----------
// ------------------------------------------------------------------------------
//   Functions
//   ------------------
//
// ------------------------------------------------------------------------------
#ifndef _GTTLTEDB_H
#define _GTTLTEDB_H

#define imsidb_len				128
#define MAX_RANGE_END_LEN		20
#define MAX_RANGE_BEGIN_LEN		20
#define MAX_HSS_HOST_NAME_LEN	256
#define MAX_INFO_IDX			20

#define FQDN_HOST_NAME_FOUND		0
#define FQDN_HOST_NAME_NOT_FOUND	1

// ------------
//   IMSI DB
// ------------
// filler NULL - Stringhe NULL terminate
#pragma fieldalign shared2 _imsi_pkey
typedef struct _imsi_pkey
{
	unsigned short	range_len;						// Primary Key
	char			range_end[MAX_RANGE_END_LEN];	// Primary Key, NOT reversed
} IMSI_PKEY;

#pragma fieldalign shared2 _imsi_record
typedef struct _imsi_record
{
	IMSI_PKEY		pkey;				// Primary Key
	char			range_ini[MAX_RANGE_BEGIN_LEN];
	unsigned short	hss_id;				// Alternate Key
	long long		insert_ts;
	long long		update_ts;
	char			filler[68];
} IMSI_RECORD;

// record di testa con range_len=0
#pragma fieldalign shared2 _imsi_head_record
typedef struct _imsi_head_record
{
	IMSI_PKEY		pkey;						// Primary Key
	char			lunghezze[MAX_INFO_IDX];	// ogni char contiene l'info (0=no, 1=si) se ci sono range di quella lunghezza. Es:
												// lunghezze[16] per i range lunghi 16, lunghezze[10] per quelli lunghi 10, ecc...
	char			filler[86];
} IMSI_HEAD_RECORD;

#define hssdb_len			320
#define hssdb_altkey_len	251
// ------------
//    HSS DB
// ------------
// filler NULL - Stringhe NULL terminate
#pragma fieldalign shared2 _hss_record
typedef struct _hss_record
{
	unsigned short	hss_id;								// Primary Key
	char			hostname[MAX_HSS_HOST_NAME_LEN];	// Alternate Key, NOT reversed, la chiave è di solo 251 byte che è il max ammesso
														// max 255: 251 AK + 2 PK + 2 N° Alt. Key = 255
	long long		insert_ts;
	long long		update_ts;
	char			filler[46];
} HSS_RECORD;

#endif
