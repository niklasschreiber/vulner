fexp<<EOI
.LOGTABLE EDW_DB_TEMP.logtable;
.LOGON $1;
.BEGIN EXPORT SESSIONS 8;
.EXPORT
OUTFILE $3
  FORMAT TEXT MODE RECORD
OUTMOD $4
	;
sel * from (select 'ID_CLIENTE_BIC|COD_FISCALE|NAZIONALITA|FASCE_ETA|SEGMENTAZIONE_PATRIMONIALE|PIATTAFORMA_ACQ_INIZIO_ANNO|PIATTAFORMA_ACQ_ULTIMA_DATA|TIPO_INTESTATARIO_CONTO|COD_FRAZIONARIO_RADIC|NR_CC_APERTI_MESE|NR_CC_APERTI_ANNO|NR_CC_CHIUSI_MESE|NR_CC_CHIUSI_ANNO|NR_CC_MIGRATI_MESE|NR_CC_MIGRATI_ANNO|TIPO_CONTO_APERTO|TIPO_CONTO_CHIUSO|NR_CONTI_IN_ESSERE_ALLA_DATA|TOT_SALDO_CONTI_ALLA_DATA|TOT_GM_YTD_CONTI_IN_ESSERE|NR_PPAY_EVO|NR_PPAY_STD' a) tmp;

select
 coalesce(trim(cast(ID_CLIENTE_BIC as varchar(255))),'')
 || '|' || coalesce(trim(cast(COD_FISCALE as varchar(255))),'')
 || '|' || coalesce(trim(cast(NAZIONALITA as varchar(255))),'')
 || '|' || coalesce(trim(cast(FASCE_ETA as varchar(255))),'')
 || '|' || coalesce(trim(cast(SEGMENTAZIONE_PATRIMONIALE as varchar(255))),'')
 || '|' || coalesce(trim(cast(PIATTAFORMA_ACQ_INIZIO_ANNO as varchar(255))),'')
 || '|' || coalesce(trim(cast(PIATTAFORMA_ACQ_ULTIMA_DATA as varchar(255))),'')
 || '|' || coalesce(trim(cast(TIPO_INTESTATARIO_CONTO as varchar(255))),'')
 || '|' || coalesce(trim(cast(COD_FRAZIONARIO_RADIC as varchar(255))),'')
 || '|' || coalesce(trim(cast(NR_CC_APERTI_MESE as varchar(255))),'')
 || '|' || coalesce(trim(cast(NR_CC_APERTI_ANNO as varchar(255))),'')
 || '|' || coalesce(trim(cast(NR_CC_CHIUSI_MESE as varchar(255))),'')
 || '|' || coalesce(trim(cast(NR_CC_CHIUSI_ANNO as varchar(255))),'')
 || '|' || coalesce(trim(cast(NR_CC_MIGRATI_MESE as varchar(255))),'')
 || '|' || coalesce(trim(cast(NR_CC_MIGRATI_ANNO as varchar(255))),'')
 || '|' || coalesce(trim(cast(TIPO_CONTO_APERTO as varchar(255))),'')
 || '|' || coalesce(trim(cast(TIPO_CONTO_CHIUSO as varchar(255))),'')
 || '|' || coalesce(trim(cast(NR_CONTI_IN_ESSERE_ALLA_DATA as varchar(255))),'')
 || '|' || coalesce(trim(cast(TOT_SALDO_CONTI_ALLA_DATA as varchar(255))),'')
 || '|' || coalesce(trim(cast(TOT_GM_YTD_CONTI_IN_ESSERE as varchar(255))),'')
 || '|' || coalesce(trim(cast(NR_PPAY_EVO as varchar(255))),'')
 || '|' || coalesce(trim(cast(NR_PPAY_STD as varchar(255))),'')
from $2
;
.END EXPORT;
.LOGOFF;
.QUIT
EOI

