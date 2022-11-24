#!/bin/bash

#############################################################################################
######################                                          #############################
###################### PROCEDURA REALIZZATA DA SAS OPERATION    #############################
######################                                          #############################
######################     CLEAN LOG SAS POOLED WORKSPACE       #############################
######################              E STORED VA PSASWS01        #############################
###################### Autore Sviluppi : Giuseppe Di Leo        #############################
######################  				 Francesco Cavallo      #############################
###################### Autore Test     : Marco Falcone          #############################
#############################################################################################

# Pooled Workspace Server
find /var/opt/teradata/sas/config/Lev1/SASApp/PooledWorkspaceServer/Logs/SASApp_PooledWSServer_* -type f -mtime +6 -exec /bin/rm -f '{}' \;

# Stored Process Server
find /var/opt/teradata/sas/config/Lev1/SASApp/StoredProcessServer/Logs/SASApp_STPServer_* -type f -mtime +6 -exec /bin/rm -f '{}' \;

# Workspace Server
#/bin/find /var/opt/teradata/sas/config/Lev1/SASApp/WorkspaceServer/Logs/SASApp_WorkspaceServer_* -type f -mtime +6 -exec /bin/rm -f '{}' \;

# Batch Server - Backup
find /var/opt/teradata/sas/config/Lev1/SASApp/BatchServer/Logs/*.log -type f -mtime +12 -exec mv '{}' /var/opt/teradata/sas/config/Lev1/SASApp/BatchServer/Logs/Backup/Log/ \;
gzip /var/opt/teradata/sas/config/Lev1/SASApp/BatchServer/Logs/Backup/Log/*.log;