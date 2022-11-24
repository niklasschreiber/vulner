#ifndef DB_H
#define DB_H

/****************************************************************
 *
 * File: db.h
 * Description: defines data structure to access databases
 *
 ****************************************************************/

#include "db_const.h"

////////////////////////////////////////// USERS //////////////////////////////////////////////////

// Chiave primaria  :           IMSI - Reversed
// Chiave alternata 1:          MSISDN – Unique - Reversed
//
// la struttura è fillerata a NULL
// tutte le stringhe sono NULL terminate

#pragma fieldalign shared2 _ROAMUN_user
typedef struct _ROAMUN_user
{
	char 		imsi[IMSI_LEN];							// Primary Key, REVERSED, NULL terminato
	char 		msisdn[MSISDN_LEN];						// Alternate Key, REVERSED, NULL terminato
	char 		operator_id[OPERATOR_ID_LEN];			// ID MVNO, codifica MAP3 (0=TIM, A=COOP, B=TISCALI, ecc...), NULL terminato
	short 		arp_id;									// ARP - riporta al DB Decoupling, numerico intero, NULL terminato
	char 		filler;
	char 		lbo_bl;									// Stato per LBO. Valori ammessi: 0x00 = whitelisted – 0x01 = blacklisted
	char 		last_vlr_address[LAST_VLR_ADDRESS_LEN];	// ultimo VLR noto, formato INTERNAZIONALE, NULL terminato
	long long	last_arp_id_ts;							// ultimo update ARP ID
	long long 	last_arp_bl_ts;							// ultimo update ARP BL
	long long 	last_lbo_bl_ts;							// ultimo update LBO BL
	long long 	last_vlr_address_ts;					// ultimo update VLR
	long long 	last_update_ts;							// ultimo update del record
	long long	start_date;								// data inizio validità record
	long long   end_date;								// data fine validità record
	char 		filler1[FILLER_LEN];
} ROAMUN_user;

#define ROAMUN_USER_PK_LEN					IMSI_LEN
///////////////////////////////////////////////////////////////////////////////////////////////////


/////////////////////////////////////////// PROFILES //////////////////////////////////////////////

// Chiave primaria  :         ProfileId
//
// la struttura è fillerata a NULL
// tutte le stringhe sono NULL terminate

#pragma fieldalign shared2 _ROAMUN_arp_profile
typedef struct _ROAMUN_arp_profile
{
	short 		profile_id;								// numerico intero, ID di ARP o LBO
	char 		description[DESCRIPTION_LEN];			// NULL terminato
	char 		scf_address_mo[SCP_ADDRESS_MO_LEN];		// GT SCF per originate, formato internazionale, NULL terminato
	char 		scf_address_mt[SCP_ADDRESS_MT_LEN];		// GT SCF per terminate, formato internazionale, NULL terminato
	char 		smsc_address[SMSC_ADDRESS_LEN];			// GT per sottomettere MO a SMSC ARP, formato internazionale, NULL terminato
	long		pc_map_proxy;							// Point code per invocare il Map Proxy
	char 		manage_dest_extra_eucap;				// indica se il destinatario della chiamata può essere extraeuropeo
														//   Valori ammessi: 0x00 = OFF – 0x01 = ON
	char 		manage_dest_extra_eusms;				// indica se il destinatario del SMS può essere extraeuropeo
														//   Valori ammessi: 0x00 = OFF – 0x01 = ON
	long long 	insert_ts;								// inserimento del record
	long long 	last_update_ts;							// ultimo update del record
	char 		filler[FILLER_LEN];
} ROAMUN_arp_profile;

#define ROAMUN_DECOUPLING_PROFILE_PK_LEN	sizeof(short)

///////////////////////////////////////////////////////////////////////////////////////////////////

#pragma fieldalign shared2 _ROAMUN_short_code_premium
typedef struct _ROAMUN_short_code_premium
{
	char number[MSISDN_LEN];							// short code o numero premium - chiave primaria
	char is_range;										// 0x00 = not range - 0x01 = range
	char is_tim;										// 0x00 = not tim (gestito da ARP) - 0x01 = tim
														// default tim
} ROAMUN_short_code_premium;

#define ROAMUN_SHORT_CODE_PREMIUM_PK_LEN	MSISDN_LEN

#pragma fieldalign shared2 _ROAMUN_service_keys
typedef struct _ROAMUN_service_keys
{
	long  service_key_arp;								// service key arp - PK
	short arp_id;										// arp id come da tabella decoupling profiles - PK - ALT1
	long  service_key_tim;								// service key tim - ALT1
	char  gt_arp[ROAMUN_GT_LEN];						// GT impianto arp
	char  gt_tim[ROAMUN_GT_LEN];						// GT impianto tim
} ROAMUN_service_keys;

#define ROAMUN_SERVICE_KEYS_PK_LEN		sizeof (long) + sizeof (short)
#define ROAMUN_SERVICE_KEYS_ALT_LEN		sizeof (long) + sizeof (short)

#endif
