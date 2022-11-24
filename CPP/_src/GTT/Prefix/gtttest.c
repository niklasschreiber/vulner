/*------------------------------------------------------------------------
+ Filename      : GTTTEST.C
+ Related files :
+ ------------------------------------------------------------------------
+ Description :
+ Test program to send request messages to gtt-server and receive response
+ ------------------------------------------------------------------------
+ History :
+ Ver. 1.0 - 23 nov 2004 - Emanuele Rossini
+     Creation.
+ ------------------------------------------------------------------------
*/
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <tal.h>
#include <cextdecs>
#include <p2apdf.h>
#include <cssinc.cext>
#include <ssplog.h>
#include <sspevt.h>

#include <gttserv.h>
#include <skelet.h>

static gtt_data  MsgStru;

void main(int argc, char *argv[])
{
   char msg[2048];
   short msg_length, err;
   char LogPath[20];
   char LogPrefix[7];
   int LogDays, iTraceLev;
   short itmp;

   SetIniFileName((const char *) getenv("INI-FILE"));

   DELAY(atoi(GetParam("GENERAL","START-DELAY"))*100);

   // Inizializzazione
   BeginTxRxSection();

   if (RxSetUp("RX")) { exit(1); }   // risposta

   TxSetUp("TX");      // richiesta

   EndTxRxSection();

   // configuro log
   memset(LogPath,0,sizeof(LogPath));
   memcpy(LogPath,GetParam("LOG", "VOLUME"),sizeof(LogPath));

   memset(LogPrefix,0,sizeof(LogPrefix));
   memcpy(LogPrefix,GetParam("LOG", "PREFIX"),sizeof(LogPrefix));

   LogDays = atoi(GetParam("LOG", "LOGDAYS"));

   log_init(LogPath, LogPrefix, LogDays);
   iTraceLev = (int)atoi(GetParam("LOG","TRACE-LEVEL"));
   log_param(iTraceLev,LOG_STAT,"");

   log(1,"LOG started...");

   // costruisco messaggio
   memset(&MsgStru,0x00,sizeof(MsgStru));

   MsgStru.subsystem_id = atoi(GetParam("GTT-PARAM","SUBSYSTEM_ID"));
   MsgStru.op_code = OCQUERY;
   MsgStru.if_version = atoi(GetParam("GTT-PARAM","IF_VERSION"));
   MsgStru.translation_type= atoi(GetParam("GTT-PARAM","TRANSLATION_TYPE"));

   MsgStru.query_data.natureOfAddress = (char)atoi(GetParam("GTT-PARAM","QD_NOA"));
   MsgStru.query_data.numberingPlan = (char)atoi(GetParam("GTT-PARAM","QD_NP"));
   MsgStru.query_data.address.length = atoi(GetParam("GTT-PARAM","QD_ADDLEN"));
   memcpy(MsgStru.query_data.address.value,GetParam("GTT-PARAM","QD_ADDVAL"),
          MsgStru.query_data.address.length);

   strcpy(MsgStru.external_reference,"Ext ref.");

   MsgStru.result_address.choice = 0x01;
   MsgStru.result_address.address.mts_address.cpu_req = (char)atoi(GetParam("GTT-PARAM","MTS_REPLY_CPUREQ"));
   MsgStru.result_address.address.mts_address.task_id = (char)atoi(GetParam("GTT-PARAM","MTS_REPLY_TASK_ID"));
   MsgStru.result_address.address.mts_address.server_class = (char)atoi(GetParam("GTT-PARAM","MTS_REPLY_S_CLASS"));
   MsgStru.result_address.address.mts_address.cpu = (char)atoi(GetParam("GTT-PARAM","MTS_REPLY_CPU"));

   // invio messaggio
   log(1,"Begin Transaction...");
   err = MsgSend("TX", (char*)&MsgStru, sizeof(MsgStru));
   if (err)
   {
      log(1,"Send error...%d",err);
      log_close();
      exit(0);
   }
   else
   {
      log(1,"Send OK...");
      log(1,"Dati richiesta-------------------");
      log(1,"subsystem_id -> %d",MsgStru.subsystem_id);
      log(1,"op_code -> %d",MsgStru.op_code);
      log(1,"if_version -> %d",MsgStru.if_version);
      log(1,"translation_type -> %d",MsgStru.translation_type);

      log(1,"natureOfAddress -> %d",MsgStru.query_data.natureOfAddress);
      log(1,"numberingPlan -> %d",MsgStru.query_data.numberingPlan);
      log(1,"address.length -> %d",MsgStru.query_data.address.length);

      if (MsgStru.query_data.numberingPlan == 2)
      {
         memcpy(&itmp,MsgStru.query_data.address.value,MsgStru.query_data.address.length);
         log(1,"address.value -> %d",MsgStru.query_data.address.value);
      }
      else
      {
         log(1,"address.value -> %s",MsgStru.query_data.address.value);
      }

      log(1,"external_reference -> %s",MsgStru.external_reference);

      log(1,"cpu_req -> %d",MsgStru.result_address.address.mts_address.cpu_req);
      log(1,"task_id -> %d",MsgStru.result_address.address.mts_address.task_id);
      log(1,"server_class -> %d",MsgStru.result_address.address.mts_address.server_class);
      log(1,"cpu -> %d",MsgStru.result_address.address.mts_address.cpu);
      log(1,"Fine richiesta-------------------");
   }

   // mi metto in ricezione per risposta
   err = -1;
   while (err != 0)
      err = MsgReceive(msg, &msg_length);

   memset(&MsgStru,0x00,sizeof(MsgStru));
   memcpy(&MsgStru,msg,msg_length);

   // loggo risposta
   log(1,"Ricevuta risposta...");
   log(1,"Dati risposta--------------------");
   log(1,"natureOfAddress -> %d",MsgStru.query_response.natureOfAddress);
   log(1,"numberingPlan -> %d",MsgStru.query_response.numberingPlan);
   log(1,"address.length -> %d",MsgStru.query_response.address.length);

   if (MsgStru.translation_type == TTYPEPC)
   {
      memcpy(&itmp,MsgStru.query_response.address.value,MsgStru.query_response.address.length);
      log(1,"address.value -> %d",itmp);

   }
   else
   {
      log(1,"address.value -> %s",MsgStru.query_response.address.value);
   }


   log(1,"SSN_1 -> %d",MsgStru.SSN_1);
   log(1,"SSN_2 -> %d",MsgStru.SSN_2);
   log(1,"SSN_3 -> %d",MsgStru.SSN_3);
   log(1,"SSN_4 -> %d",MsgStru.SSN_4);
   log(1,"SSN_5 -> %d",MsgStru.SSN_5);

   log(1,"result_code -> %d",MsgStru.result_code);
   log(1,"Fine risposta--------------------");
   log(1,"End transaction...");
   log(1,"Log closed.");
   log_close();
   exit(0);
}

