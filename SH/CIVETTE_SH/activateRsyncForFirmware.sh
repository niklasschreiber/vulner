#!/bin/bash
# activateRsyncForFirmware.sh

## Revision History:
# 20170307 ibaldachini@nabertech.com: creazione

## Usage:
# activateRsyncForFirmware.sh 11.22.33.44 # i.e. a valid IPv4 address using base 10 numbers


## Descrizione:
# Script per rsync puntuale verso il totem per il trasferimento dei file di firmware (da /media/solariq/nuovifirmware/ in /solwrk/server/inbox/firmware)

## Logica funzionamento:
# 10 tentativi, con delay 1min dopo ogni tentativo fallito.

TIMEOUT=10 # rsync timeout

FIRMWARE_DIR=/media/solariq/nuovifirmware
LOG_DIR=/var/tmp

function rsync_up {
	local IP=$1
    local retVal=0
	CMD_FIRMWARE="rsync -e 'ssh -o StrictHostKeyChecking=no' --timeout $TIMEOUT -d -a $FIRMWARE_DIR/* solari@$IP:/solwrk/server/inbox/firmware"
	LOG_FILE="$LOG_DIR/activateRsyncForFirmware_${IP}.log"

	echo $CMD_FIRMWARE >> $LOG_FILE
	eval $CMD_FIRMWARE >> $LOG_FILE 2>&1
    retVal=$?
    if [ $retVal -ne 0 ]; then
        echo "-- rsync FAILED --" >> $LOG_FILE
    else
        echo "-- rsync OK --" >> $LOG_FILE
    fi
	
    return $retVal
}

valid_IPv4() {
    local IP=$1
    local retVal=1
    
    if [[ $IP =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        # "spacchettamento" dell'indirizzo per accedere ai singoli byte tramite comando ${IP[0]} (backup e recuper di IFS, nel caso sia settato)
        IFS_bak=$IFS
        IFS='.'
        IP=($IP)
        IFS=$IFS_bak
        # check (non esaustivo) sulla validità dell'indirizzo
        if [[ ${IP[0]} -le 255 && ${IP[1]} -le 255 && ${IP[2]} -le 255 && ${IP[3]} -le 255 ]]; then
            if [[ ${IP[0]} -eq 0 && ${IP[1]} -eq 0 && ${IP[2]} -eq 0 && ${IP[3]} -eq 0 ]]; then
                retVal=3 # usato l'indirizzo riservato "0.0.0.0"
            elif [[ ${IP[0]} -eq 255 && ${IP[1]} -eq 255 && ${IP[2]} -eq 255 && ${IP[3]} -eq 255 ]]; then
                retVal=3 # usato l'indirizzo riservato "255.255.255.255"
            else
                retVal=0
            fi
        else
            retVal=2 # i numeri NON sono compresi tra 0 e 255
        fi
    else
        retVal=1 # il formato NON è di numeri (da 1 a 3 cifre) separati da '.'
    fi
    
    if [ $retVal -ne 0 ]; then echo "activateRsyncForFirmware.sh: Error: IP format not valid."; fi
    return $retVal
}

if [ $# -eq 1 ]; then # script called with 1 argument
    if valid_IPv4 $1 ; then
        IP=$1
        LOG_FILE="$LOG_DIR/activateRsyncForFirmware_${IP}.log"
        if [ -f $LOG_FILE ]; then
          LOG_TIMESTAMP=$(head -n 1 $LOG_FILE)
          LOG_BACKUP="$LOG_DIR/activateRsyncForFirmware_${LOG_TIMESTAMP}_${IP}.log"
          mv $LOG_FILE $LOG_BACKUP
        fi
        date +"%Y%m%d%H%M%S" > $LOG_FILE
        rsync_up $IP
#        for i in `seq 1 10` # 10 tentativi di rsync
#        do
#            if  rsync_up $IP  ; then
#                break # rsync ultimato correttamente
#            else 
#                sleep 60 # wait 1 minute, then re-try
#            fi
#        done
    else
        echo -e "Wrong format. Calls supported are:\nactivateRsyncForFirmware.sh 11.22.33.44 # i.e. a valid IPv4 address using base 10 numbers"
    fi
else
    echo "activateRsyncForFirmware.sh: ERROR: Must provide 1 argument."
    exit 1
fi
