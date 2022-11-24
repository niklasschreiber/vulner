////////////////////////////////////////// USERS //////////////////////////////////////////////////

// Chiave primaria  :           IMSI - Reversed
// Chiave alternata 1:          MSISDN – Unique - Reversed
//
// la struttura è fillerata a NULL
// tutte le stringhe sono NULL terminate

#define ROAMUN_GT_LEN			(32)
#define IMSI_LEN				(18)
#define MSISDN_LEN				(18)
#define OPERATOR_ID_LEN			(2)
#define LAST_VLR_ADDRESS_LEN	(ROAMUN_GT_LEN)
#define FILLER_LEN				(80)

#pragma fieldalign shared2 _ROAMUN_user
typedef struct _ROAMUN_user
{
	char 		imsi[IMSI_LEN];							// Primary Key, REVERSED, NULL terminato
	char 		msisdn[MSISDN_LEN];						// Alternate Key, REVERSED, NULL terminato
	char 		operator_id[OPERATOR_ID_LEN];			// ID MVNO, codifica MAP3 (0=TIM, A=COOP, B=TISCALI, ecc...), NULL terminato
	short 		arp_id;									// ARP - riporta al DB Decoupling, numerico intero, NULL terminato
	char 		arp_bl;									// Stato per ARP. Valori ammessi: 0x00 = whitelisted – 0x01 = blacklisted
	char 		lbo_bl;									// Stato per LBO. Valori ammessi: 0x00 = whitelisted – 0x01 = blacklisted
	char 		last_vlr_address[LAST_VLR_ADDRESS_LEN];	// ultimo VLR noto, formato INTERNAZIONALE, NULL terminato
	long long	last_arp_id_ts;							// ultimo update ARP ID
	long long 	last_arp_bl_ts;							// ultimo update ARP BL
	long long 	last_lbo_bl_ts;							// ultimo update LBO BL
	long long 	last_vlr_address_ts;					// ultimo update VLR
	long long 	last_update_ts;							// ultimo update del record
	long long	start_date;								// data inizio validità record
	long long   end_date;								// data fine validità record
	char 		filler[FILLER_LEN];
} ROAMUN_user;

#pragma fieldalign shared2 _ts_if4_record
typedef struct _ts_if4_record
{
	char		imsi[16];			 					// Primary key, reversed
	char		msisdn[16];
	char		imei[16];
	char		roamingStatus;							// 0x30 = not roaming, 0x31 = roaming
	char		roamingChanged;							// 0x30 = not changed, 0x31 = changed
	char		mccmnc[6];
	long long	jts;
	char		c_retry;
	char		filler[15];
} t_ts_if4_record;
