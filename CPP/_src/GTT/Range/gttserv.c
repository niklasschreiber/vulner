/*------------------------------------------------------------------------
+ Filename      : GTTSERV.C
+ Related files :
+ ------------------------------------------------------------------------
+ Description :
+ Server Global Title Translation BRA/JPN
+ 10/06/2014 - Added Dual Imsi for Roaming Unbundling
+ 17/06/2014 - Changed section and parameter names to merge with TFSINI
+ ------------------------------------------------------------------------
+ History :
+ Ver. 1.0 - 01 sep 2004 - Emanuele Rossini
+     Creation.
+
+ Last Change: 16-04-2015
+ ------------------------------------------------------------------------
*/
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdarg.h>
#include <p2system.p2apdfh>
#include <erainc.ccpy>
#include <cssinc.cext>
#include <cextdecs.h>
#include <skelet.h>
#include <ssplog.h>
#include <sspevt.h>
#include <usrlib.h>
#include "gttserv.h"
#include "gttstat.h"

#if (_TNS_E_TARGET)
T0000H06_21JUN2018_KTSTEA10_01() {};
#elif (_TNS_X_TARGET)
T0000L16_21JUN2018_KTSTEA10_01() {};
#endif

#define INI_SECTION_GTT "GTT"

// messaggi
static gtt_data GTT_Msg;

// prototipi
static void InitializeProc(void);
static short ParamReloadProc(void);
static short ManageSysMessages(char *msg );
static short ManageUserMessages( char *msg,
								 short msg_length ,
								 short *i_reply_to_do );

static void FlushStat(void);
static short InitStats(void);
//static short StatReplace(short sIndex, long lValue);
static short StatAdd( short sIndex,
					  long lValue );

static long stat_timerval ( long i_stat_interval );

short SetTimerBump_( long l_stat_bump_interval, // in seconds
                     long l_tag );

// variabili
static long long llBeginTime, llEndTime;

static short g_StatGroup;
static short g_MaxRegs;
static char  g_RegSet[16];
static long  l_TimeOut;
static char  logf[40];
static char  logp[20];
static int   logd,logl;

static short i_my_cpu;
static char  ac_my_process_name[10];
static char  ac_node_name[10];

int main(int argc, char **argv)
{
   short 	msg_length;
   short 	err = 0;
   short	i_stop = 0;
   short	i_reply_to_do;
   char 	msg[2048];
   char		*work;

   if(work = getenv("INI-FILE"))
   {
	   SetIniFileName(work);

	   work = GetParam(INI_SECTION_GTT, "START-DELAY");

	   if(work)
	   {
		   DELAY((long)(atol(work)*100));

		   InitializeProc();

		   if(logl >= LOG_DEBUG)
		   		log_(LOG_DEBUG,"sizeof gtt_data[%d]",sizeof(GTT_Msg));
	   }
	   else
		   i_stop = 1;
   }
   else
	   i_stop = 1;

   while(!i_stop)
   {
      /* Receive message */
      err = MsgReceive( msg,
    		  	  	    &msg_length,
    		  	  	    sizeof(msg) );

      /* Manage Message */
      switch(err)
      {
         case SKE_USERMSG: // Manage Procedure Messages
         {
            // reply all'interno
            ManageUserMessages( msg,
            					msg_length,
            					&i_reply_to_do );

            if(i_reply_to_do)
            	REPLYX();

            break;
         }
         case SKE_SYSMSG:// Manage System Messages
         {
            REPLYX();
            ManageSysMessages(msg);

            break;
         }
         default:
         {
            REPLYX();
            break;
         }
      }   /* switch(err) */
   }
}

static short ParamReloadProc(void)
{
   short 	err = 0;
   short    i_ret = 0;
   char		tmp[255];
   char		*work;

   // carica tabella
   work = GetParam(INI_SECTION_GTT,"NETWORK-NODES");

   if(work)
   {
	   strcpy(tmp, work);

	   err = GT_PC_GT_Load(tmp);

	   if (err && err != 2)
	   {
		   i_ret = 1;
		   log_evt( SSPEVT_CRITICAL,
				    SSPEVT_NOACTION,
				    EVT_NUMBASE+1,
				    "Error loading table %s", work);
	   }
	   else
	   {
		   work = GetParam(INI_SECTION_GTT,"MGT");

		   if(work)
		   {
			   // carica tree o lista da MGT
			   strcpy(tmp, work);
			   err = GT_MGT_Load(tmp);

			   if (err && err != 2)
			   {
				   i_ret = 1;

				   log_evt(SSPEVT_CRITICAL,
						   SSPEVT_NOACTION,
						   EVT_NUMBASE+2,
						   "Error loading table %s", work);
		   	   }
			   else
			   {
				   work = GetParam(INI_SECTION_GTT,"LOG-LEVEL");

				   if(work)
				   {
					   // trace level del log_
					   logl = (int)atoi(work);

					   if( logl > LOG_DEBUG )
					   {
						   log_param( logl,
									   LOG_UNBUFFERED,
									   "" );
					   }
					   else
					   {
						   log_param( logl,
									   LOG_STAT,
									   "" );
					   }

					   work = GetParam(INI_SECTION_GTT,"STAT-TIMEOUT"); // in minuti

					   if(work)
						   l_TimeOut = (long)(atol(work) * 60); // in secondi
					   else
						   i_ret = 1;
				   }
				   else
					   i_ret = 1;
			   }
		   }
		   else
		   {
			   i_ret = 1;
		   }
	   }
   }
   else
   {
	   i_ret = 1;
   }

   return i_ret;
}

static void InitializeProc(void)
{
	short   i_proch[20];
	short   i_maxlen = sizeof (ac_my_process_name);
	short   i_maxlen_node = sizeof(ac_node_name);
	char	*work;

	memset(ac_my_process_name,0x00,sizeof(ac_my_process_name));

	PROCESSHANDLE_GETMINE_ (i_proch);
	PROCESSHANDLE_DECOMPOSE_ ( i_proch,&i_my_cpu,
							   ,,
							   ac_node_name,
							   i_maxlen_node,
							   &i_maxlen_node,
							   ac_my_process_name,
							   i_maxlen,
							   &i_maxlen, );

	L_CINITIALIZE(); // Added for bug statistics 27/08
	L_INITIALIZE_END (); // Added for bug statistics 27/08

	sspevt_init( EVT_APPLNAME,
				 EVT_OWNER,
				 EVT_ADMNUM,
				 EVT_VERSION );

	log_evt( SSPEVT_NORMAL,
			 SSPEVT_NOACTION,
			 EVT_NUMBASE,
			 "GTT Service STARTED" );

	work = GetParam("LOG","LOG-PATH");

	if(work)
	{
	   strcpy(logf,work);

	   work = GetParam(INI_SECTION_GTT,"LOG-PREFIX");

	   if(work)
		   strcpy(logp,work);
	   else
		   strcpy( logp,ac_my_process_name + 1);

	   work = GetParam(INI_SECTION_GTT,"LOG-DAYS");

	   if(work)
	   {
		   logd = atoi(work);

		   log_init( logf,
					 logp,
					 logd );

		   log_param_filecreate ( 1024 /*filecreate_primary_extent_size*/,
								  1024 /*filecreate_secondary_extent_size*/,
								  900 /*filecreate_maximum_extents */ );

		   log_(LOG_DEBUG,"Log Started. volume:[%s], prefix:[%s], days:[%d], level:[%d]",
					   logf,
					   logp,
					   logd,
					   logl);

		   BeginTxRxSection();

		   if (RxSetUp("RX-DEFINE"))
		   {
			   log_(LOG_ERROR,"[RX-DEFINE] missing");

			   exit(1);
		   }

		   // imposto TX dinamica
		   TxSetDynamic("TX-GTTSERV","MTS_STD","0;0;0;0");

		   EndTxRxSection();

		   //
		   ParamReloadProc(); // va dopo la log_init perchè contiene la log_param
		   //

		   if (!InitStats())
		   {
			   if( SetTimerBump_(l_TimeOut,TAG_BUMP ))
			   {
				   log_(LOG_ERROR,"SIGNALTIMEOUT error - Bump stat" );
			   }
			   else
				   log_(LOG_DEBUG,"Stats timeout set to [%d] min.",(short)(l_TimeOut/60));
		   }
	   }
    }
}

static short ManageUserMessages( char *inmsg,
								 short msg_length,
								 short *i_reply_to_do )
{
   short 	err;
   short 	sPCF;
   short 	sPC;
   char 	tmpaddr[6];
   char 	sGT[MAX_ADDRESS_LEN_MNG];
   char 	sMGT[MAX_ADDRESS_LEN_MNG];
   char 	pkey[MAX_ADDRESS_LEN_MNG];
   long 	ltt;
   tblpcgt 	*ptable;
   treeval 	*ptree;

   err = 0;
   *i_reply_to_do = 1; // Reply to do

   StatAdd(RICHIESTE_RICEVUTE,1);

   memcpy(&GTT_Msg, inmsg, msg_length);

   log_(LOG_DEBUG,"Message received...");

   llBeginTime = JULIANTIMESTAMP(0);

   // IPCAddress è stato passato
   if (!(GTT_Msg.result_address.choice == 0x01 ||
       GTT_Msg.result_address.choice == 0x02 ||
       GTT_Msg.result_address.choice == 0x03))
   {
	   *i_reply_to_do = 0; // Reply has been done
	   err = 1;
	   // REPLYX();
	   // NO ==> REPLY con errore 3 (Invalid IPC_Address)
	   GTT_Msg.result_code = RCINVALIDIPCADDR;

	   llEndTime = JULIANTIMESTAMP(0);
	   REPLYX((const char *)&GTT_Msg, sizeof(GTT_Msg));

	   log_evt(SSPEVT_CRITICAL,
    		   SSPEVT_NOACTION,
    		   EVT_NUMBASE+7,
    		   "Invalid result IPCAddress");

	   StatAdd(RISPOSTE_ERRORE_SU_REPLY,1);

	   log_(LOG_DEBUG,"Invalid result IPCAddress.END");
   }

   // Verifico la richiesta
   while (!err) // ciclo fittizio per controllo del flusso
   {
      // SI ==> REPLY per liberare e continuo
//      REPLYX();
      log_(LOG_DEBUG,"Valid result IPCAddress");

      // operazione richiesta
      if (GTT_Msg.op_code != OCQUERY)
      {
         // invio errore 4 (invalid op_code)
         GTT_Msg.result_code = RCINVALIDOPCODE;
         err = 1;

         log_(LOG_DEBUG,"Invalid op_code[%d].END",GTT_Msg.op_code);

         break;
      }

      // estraggo il tipo di interrogazione
      // e verifico se è congruente con le informazioni fornite
      switch (GTT_Msg.translation_type)
      {
         case TTYPEPC:
         {
            // combinazioni valide
            if (GTT_Msg.query_data.natureOfAddress == NAINT &&
                GTT_Msg.query_data.numberingPlan == NPGT)
            {
               // cerco direttamente PC ho già SSN
               // estraggo GT da query_data
               memset(sGT,0x00,MAX_ADDRESS_LEN_MNG);
               memcpy(sGT,GTT_Msg.query_data.address.value,GTT_Msg.query_data.address.length);

               log_(LOG_DEBUG,"Translation request GT[%s] ==> PC",sGT);

               ptable = SeekGT(sGT);

               if (!ptable)
               {
                  err = 1;
                  // errore 1 (Data Not found)
                  GTT_Msg.result_code = RCDATANOTFOUND;
                  log_(LOG_DEBUG,"GT not found.END");

                  break;
               }

               // imposto query_response
               GTT_Msg.query_response.natureOfAddress = NANAT;
               GTT_Msg.query_response.numberingPlan   = NPPC;
               memset(GTT_Msg.query_response.address.value, 0x00,sizeof(GTT_Msg.query_response.address.value));
               memcpy(GTT_Msg.query_response.address.value, &(ptable->PC), sizeof(ptable->PC));
               GTT_Msg.query_response.address.length = sizeof(ptable->PC);
               err = 0;

               log_(LOG_DEBUG,"Data found. PCF[%d] - PC[%d]",NANAT,ptable->PC);
            }
            else if (GTT_Msg.query_data.natureOfAddress == NAINT &&
                     GTT_Msg.query_data.numberingPlan == NPMGT)
            {
               // cerco direttamente PC e con PC cerco per avere SSN
               // estraggo MGT da query_data
               memset(sMGT,0x00,MAX_ADDRESS_LEN_MNG);
               memcpy(sMGT,GTT_Msg.query_data.address.value,GTT_Msg.query_data.address.length);

               log_(LOG_DEBUG,"Translation request MGT[%s] ==> PC",sMGT);

               memset(pkey,0x00,MAX_ADDRESS_LEN_MNG);
               memcpy(pkey,sMGT,strlen(sMGT));
               ptree = SeekMGT(pkey);

               if (!ptree)
               {
                  err = 1;
                  // errore 1 (Data Not found)
                  GTT_Msg.result_code = RCDATANOTFOUND;
                  log_(LOG_DEBUG,"MGT not found.END");

                  break;
               }
               // uso PC trovato per avere SSN
               sPCF = ptree->PCF;
               sPC  = ptree->PC;
               ptable = SeekPC(sPCF, sPC);
               if (!ptable)
               {
                  err = 1;
                  // errore 1 (Data Not found)
                  GTT_Msg.result_code = RCDATANOTFOUND;
                  log_(LOG_DEBUG,"PC not found.END");

                  break;
               }

               // imposto query_response
               GTT_Msg.query_response.natureOfAddress = NANAT;
               GTT_Msg.query_response.numberingPlan   = NPPC;
               memset(GTT_Msg.query_response.address.value, 0x00,sizeof(GTT_Msg.query_response.address.value));
               memcpy(GTT_Msg.query_response.address.value, &(ptable->PC), sizeof(ptable->PC));
               GTT_Msg.query_response.address.length = sizeof(ptable->PC);

               // Dual IMSI
               GTT_Msg.c_dualimsi_flag = ptree->c_dualimsi_flag;

               if( ptree->c_dualimsi_flag == 0x01 )
            	   log_(LOG_DEBUG,"DUAL IMSI flag set - Data found but PCF[%d] - PC[%d] are ignored",ptable->PCF,ptable->PC);
			   else
				   log_(LOG_DEBUG,"Data found: PCF[%d] - PC[%d]",ptable->PCF,ptable->PC);

               err = 0;
            }
            else
            {
               err = 1;
               // errore 1 (Invalid Translation Type)
               GTT_Msg.result_code = RCINVALIDTTYPE;
            }

            break;
         }
         case TTYPEGT:
         {
            // combinazioni valide
            if (GTT_Msg.query_data.natureOfAddress == NANAT &&
                GTT_Msg.query_data.numberingPlan == NPPC)
            {
               // cerco direttamente GT ho già SSN
               // estraggo PCF e PC da query_data
               sPCF = NANAT;
               memcpy(&sPC, GTT_Msg.query_data.address.value, GTT_Msg.query_data.address.length);

               log_(LOG_DEBUG,"Translation request PCF[%d] - PC[%d] ==> GT",sPCF,sPC);

               ptable = SeekPC(sPCF, sPC);

               if (!ptable)
               {
                  err = 1;
                  // errore 1 (Data Not found)
                  GTT_Msg.result_code = RCDATANOTFOUND;
                  log_(LOG_DEBUG,"PC not found.END");

                  break;
               }

               // imposto query_response
               GTT_Msg.query_response.natureOfAddress = NAINT;
               GTT_Msg.query_response.numberingPlan   = NPGT;
               memset(GTT_Msg.query_response.address.value, 0x00,sizeof(GTT_Msg.query_response.address.value));
               memcpy(GTT_Msg.query_response.address.value, ptable->GT, strlen(ptable->GT));
               GTT_Msg.query_response.address.length = (unsigned short)strlen(ptable->GT);
               err = 0;

               log_(LOG_DEBUG,"Data found: GT[%s]",GTT_Msg.query_response.address.value);
            }
            else if (GTT_Msg.query_data.natureOfAddress == NAINT &&
                     GTT_Msg.query_data.numberingPlan == NPMGT)
            {
               // cerco direttamente PC e con questo cerco GT e ho anche SSN
               // estraggo MGT da query_data
               memset(sMGT,0x00,MAX_ADDRESS_LEN_MNG);
               memcpy(sMGT,GTT_Msg.query_data.address.value,GTT_Msg.query_data.address.length);

               log_(LOG_DEBUG,"Translation request MGT[%s] ==> GT",sMGT,sPC);

               memset(pkey,0x00,MAX_ADDRESS_LEN_MNG);
               memcpy(pkey,sMGT,strlen(sMGT));
               ptree = SeekMGT(pkey);

               if (!ptree)
               {
                  err = 1;
                  // errore 1 (Data Not found)
                  GTT_Msg.result_code = RCDATANOTFOUND;
                  log_(LOG_DEBUG,"MGT not found.END");

                  break;
               }
               // uso PC trovato per cercare in tabella
               sPCF = ptree->PCF;
               sPC  = ptree->PC;
               ptable = SeekPC(sPCF, sPC);
               if (!ptable)
               {
                  err = 1;
                  // errore 1 (Data Not found)
                  GTT_Msg.result_code = RCDATANOTFOUND;
                  log_(LOG_DEBUG,"PC not found.END");

                  break;
               }

               // imposto query_response
               GTT_Msg.query_response.natureOfAddress = NAINT;
               GTT_Msg.query_response.numberingPlan   = NPGT;
               memset(GTT_Msg.query_response.address.value, 0x00,sizeof(GTT_Msg.query_response.address.value));
               memcpy(GTT_Msg.query_response.address.value, ptable->GT, strlen(ptable->GT));
               GTT_Msg.query_response.address.length = (unsigned short)strlen(ptable->GT);

               // Dual IMSI
               GTT_Msg.c_dualimsi_flag = ptree->c_dualimsi_flag;

               err = 0;

               log_(LOG_DEBUG,"Data found: GT[%s]",GTT_Msg.query_response.address.value);
            }
            else
            {
               // errore 1 (Invalid Translation Type)
               GTT_Msg.result_code = RCINVALIDTTYPE;
               err = 1;
               log_(LOG_DEBUG,"Invalid translation request [%d].END",GTT_Msg.translation_type);
            }

            break;
         }

         case TTYPEGTGT:
		 {
			// combinazioni valide
			if (GTT_Msg.query_data.natureOfAddress == NAINT &&
			    GTT_Msg.query_data.numberingPlan == NPGT)
			{
				err = 0;
				// cerco direttamente PC ho già SSN
				// estraggo GT da query_data
				memset(sGT,0x00,MAX_ADDRESS_LEN_MNG);
				memcpy(sGT,GTT_Msg.query_data.address.value,GTT_Msg.query_data.address.length);

				log_(LOG_DEBUG,"%s: No Translation request for GT[%s]",
						__FUNCTION__,
						sGT);

				ptable = SeekGT(sGT);

				if (!ptable)
				{
				   GTT_Msg.result_code = RCDATANOTFOUND;
				   log_(LOG_DEBUG,"%s: GT not found. Incoming GT[%s] is returned as is",
						   __FUNCTION__,
						   sGT);

				   err = 1;
				}
				else
				{
					log_(LOG_DEBUG,"%s: Data found: GT[%s|TON-0x%2.2X|NPI-0x%2.2X]",
							__FUNCTION__,
							sGT,
							NAINT,
							NPGT);
				}

				// imposto query_response with incoming GT
				GTT_Msg.query_response = GTT_Msg.query_data;
			 }
			 else
			 {
				err = 1;
				// errore 1 (Invalid Translation Type)
				GTT_Msg.result_code = RCINVALIDTTYPE;
			 }

			 break;
		 }

         default:
         {
        	err = 1;
            // errore 1 (Invalid Translation Type)
            GTT_Msg.result_code = RCINVALIDTTYPE;

            log_(LOG_DEBUG,"Invalid translation request [%d].END",GTT_Msg.translation_type);

            break;
         }
      }
      // imposto op_code per risposta
      GTT_Msg.op_code = OCRESPONSE;

      if (!err)
      {
    	  GTT_Msg.result_code = RCSUCCESS;

    	  // imposto gli ssn
    	  GTT_Msg.SSN_1 = ptable->SSN_1;
    	  GTT_Msg.SSN_2 = ptable->SSN_2;
    	  GTT_Msg.SSN_3 = ptable->SSN_3;
    	  GTT_Msg.SSN_4 = ptable->SSN_4;
    	  GTT_Msg.SSN_5 = ptable->SSN_5;
      }

      // estraggo l'indirizzo di risposta e spedisco
      if (GTT_Msg.result_address.choice == 0x01)   // MTS_STD
      {
         sprintf(tmpaddr,"%d;%d;%d;%d",
                 GTT_Msg.result_address.address.mts_address.cpu_req,
                 GTT_Msg.result_address.address.mts_address.task_id,
                 GTT_Msg.result_address.address.mts_address.server_class,
                 GTT_Msg.result_address.address.mts_address.cpu);

         TxSetDynamic("TX-GTTSERV","MTS_STD",tmpaddr);

         log_(LOG_DEBUG,"Set result addr MTS_STD. cpu_req[%d] - task_id[%d] - server_class[%d] - cpu[%d]",
				  GTT_Msg.result_address.address.mts_address.cpu_req,
				  GTT_Msg.result_address.address.mts_address.task_id,
				  GTT_Msg.result_address.address.mts_address.server_class,
				  GTT_Msg.result_address.address.mts_address.cpu);

      }
      else if (GTT_Msg.result_address.choice == 0x02)   // MTS_PROC)
      {
         sprintf(tmpaddr,"%s",
                 GTT_Msg.result_address.address.process_name.procname);
                 //GTT_Msg.result_address.address.process_name.cpu,
                 //GTT_Msg.result_address.address.process_name.pin);

         TxSetDynamic("TX-GTTSERV","MTS_PROC",tmpaddr);
         log_(LOG_DEBUG,"Set result addr MTS_PROC. proc_name[%5.5s]",
				  GTT_Msg.result_address.address.process_name.procname);
				  //GTT_Msg.result_address.address.process_name.cpu,
				  //GTT_Msg.result_address.address.process_name.pin);
      }
      else // MTS_EPROC
      {
         //sprintf(tmpaddr,"%d;%s;%d;%d",
    	  sprintf(tmpaddr,"%d;%s",
				  GTT_Msg.result_address.address.extend_process_name.sysnum,
				  GTT_Msg.result_address.address.extend_process_name.procname);
				// GTT_Msg.result_address.address.extend_process_name.cpu,
				// GTT_Msg.result_address.address.extend_process_name.pin);

          TxSetDynamic("TX-GTTSERV","MTS_EPROC",tmpaddr);
          log_(LOG_DEBUG,"Set result addr MTS_EPROC. sysnum[%d] - proc_name[%4.4s]",
				  GTT_Msg.result_address.address.extend_process_name.sysnum,
				  GTT_Msg.result_address.address.extend_process_name.procname);
				 // GTT_Msg.result_address.address.extend_process_name.cpu,
				 // GTT_Msg.result_address.address.extend_process_name.pin);
      }

      llEndTime = JULIANTIMESTAMP(0);

      err = MsgSend( "TX-GTTSERV",
    		  	  	 (char*)&GTT_Msg,
    		  	  	 sizeof(GTT_Msg) );

      if (!err)
      {

         StatAdd(RISPOSTE_SEND_OK,1);
         if (GTT_Msg.result_code == RCSUCCESS)
            StatAdd(RISPOSTE_POSITIVE,1);
         else
            StatAdd(RISPOSTE_NEGATIVE,1);

         log_(LOG_DEBUG,"Send OK.END");
      }
      else
      {
         StatAdd(RISPOSTE_SEND_KO,1);
         log_(LOG_ERROR,"Err.[%d] - IPC Failure.END",err);
      }

      break;
   }

   // calcolo tempo impiegato per statistica
   ltt = (long)((llEndTime - llBeginTime) / 1000);  // per avere i msec
   if (ltt <= 5)
      StatAdd(TRANSAZIONI_ENTRO_5_MSEC,1);
   else if (ltt > 5 && ltt <= 10)
      StatAdd(TRANSAZIONI_ENTRO_10_MSEC,1);
   else if (ltt > 10 && ltt <= 25)
      StatAdd(TRANSAZIONI_ENTRO_25_MSEC,1);
   else if (ltt > 25 && ltt <= 50)
      StatAdd(TRANSAZIONI_ENTRO_50_MSEC,1);
   else if (ltt > 50 && ltt <= 75)
      StatAdd(TRANSAZIONI_ENTRO_75_MSEC,1);
   else if (ltt > 75 && ltt <= 100)
      StatAdd(TRANSAZIONI_ENTRO_100_MSEC,1);
   else if (ltt > 100 && ltt <= 250)
      StatAdd(TRANSAZIONI_ENTRO_250_MSEC,1);
   else if (ltt > 250 && ltt <= 500)
      StatAdd(TRANSAZIONI_ENTRO_500_MSEC,1);
   else if (ltt > 500 && ltt <= 750)
      StatAdd(TRANSAZIONI_ENTRO_750_MSEC,1);
   else if (ltt > 750 && ltt <= 1000)
      StatAdd(TRANSAZIONI_ENTRO_1_SEC,1);
   else if (ltt > 1000 && ltt <= 2000)
      StatAdd(TRANSAZIONI_ENTRO_2_SEC,1);
   else if (ltt > 2000 && ltt <= 3000)
      StatAdd(TRANSAZIONI_ENTRO_3_SEC,1);
   else  // > 3000 = 3sec
      StatAdd(TRANSAZIONI_OLTRE_3_SEC,1);

   return err;
}

//
// Manage system message
//
short ManageSysMessages( char *ac_msg )
{
    short           i_ret = 0;
    short			i_res = 0;
    short			i_tmp_reload_param;
    IO_SYS_TIMEOUT	*signal;
    SYS_COMMAND     *cmd;

    signal = (IO_SYS_TIMEOUT *)ac_msg;

    switch( signal->id )
    {
        case SYS_MSG_TIME_TIMEOUT:
        {
        	log_(LOG_DEBUG,"System Timeout Message: Sock[%d] Tag[%ld]",
							signal->i_socket,
							signal->l_tag);

			switch ( signal->l_tag )
			{
                case TAG_RELOAD_PARAM:
                {
                	log_(LOG_DEBUG,"...Refresh parameters executed.");

                	ParamReloadProc();

                    break;
                }

                case TAG_BUMP:
				{
					FlushStat();

					log_(LOG_DEBUG,"Flush Stats timeout executed, a new one started in [%d] min.",l_TimeOut/60);

					if( SetTimerBump_(l_TimeOut,TAG_BUMP ))
						log_(LOG_ERROR,"SIGNALTIMEOUT error - Bump stat" );

					break;
				}
            }

            break;
        }

        case SYS_MSG_COMMAND:
		{
			cmd = (SYS_COMMAND *)ac_msg;
			cmd->ac_cmd[cmd->i_cnt]=0;

			if( !strcmp(cmd->ac_cmd,"PARAMREFRESH") )
			{
				log_(LOG_DEBUG2,"- REFRESHPARAM request recv. -");

				i_tmp_reload_param = (short)(JULIANTIMESTAMP(0)%100);

				if( i_tmp_reload_param < 3 )
					i_tmp_reload_param = 7;

				// shifting JULIANTIMESTAMP(0) + [2 - 30"]
				if( i_res = SIGNALTIMEOUT_((long)( 30 * i_tmp_reload_param),0,TAG_RELOAD_PARAM) )
				{
					log_(LOG_ERROR,"SIGNALTIMEOUT Err.[%d] - Reload param",i_res );
				}
			}
			else
				log_(LOG_ERROR,"- Unhandle command[%s] request recv. -",cmd->ac_cmd);

			break;
		}

        case SYS_MSG_STOP_1:
        case SYS_MSG_STOP_2:
        {
        	i_ret = 1;

            // prima di uscire devo cancellare l'albero
			log_(LOG_DEBUG,"SHUTDOWN request recv.");

			FlushStat();
			CloseMGT();
			log_close();

			exit(0);

            break;
        }
    }

    return i_ret;

} // End Of Procedure


static void FlushStat(void)
{
   L_STAT_BUMP();
}

static short InitStats(void)
{
	char 	*wrk_str;
	short 	err;

	if ((wrk_str = GetParam(INI_SECTION_GTT,"STAT-REGSET")) == NULL)
	{
		log_evt(SSPEVT_NORMAL,
				SSPEVT_NOACTION,
				EVT_NUMBASE+3,
				"Error STAT-REGSET not defined.");
	}
	else
	{
		memset(g_RegSet, ' ',sizeof(g_RegSet)); // filled with spaces
		memcpy(g_RegSet, wrk_str,strlen(wrk_str));
	}

	if ((wrk_str = GetParam(INI_SECTION_GTT,"STAT-GROUP")) == NULL)
	{
		log_evt(SSPEVT_NORMAL,
				SSPEVT_NOACTION,
				EVT_NUMBASE+4,
				"Error STAT-GROUP not defined.");
	}
	else
	{
		g_StatGroup = (short)atoi((const char*)wrk_str);
	}

	if ((wrk_str = GetParam(INI_SECTION_GTT,"STAT-MAXREGS")) == NULL)
	{
		log_evt(SSPEVT_NORMAL,
				SSPEVT_NOACTION,
				EVT_NUMBASE+5,
				"Error STAT-MAXREGS not defined.");
	}
	else
	{
		g_MaxRegs = (short)atoi((const char*)wrk_str);
	}

	err = L_STAT_OPEN(g_StatGroup, g_MaxRegs);

	if (err != P2_ST_NOERROR)
	{
		log_evt(SSPEVT_NORMAL,
				SSPEVT_NOACTION,
				EVT_NUMBASE+6,
				"Error L_STAT_OPEN failed.");
	}
	else
	{
		log_(LOG_DEBUG,"Open stats: Group[%d] - maxregs[%d] - regset[%.16s]",
	   			g_StatGroup,
	   			g_MaxRegs,
	   			g_RegSet);
	}

	return err;
}

// ATTENZIONE ! Questa funzione è corretta, la documentazione riportava
// i flag di add e replace invertiti
//static short StatReplace(short sIndex, long lValue)
//{
//   short err;
//   err = L_STAT_ENTRY(g_StatGroup, g_RegSet, sIndex, 1, lValue);
//   if (err == P2_ST_BUFFER_FULL)
//   {
//      L_STAT_BUMP();
//      err = L_STAT_ENTRY(g_StatGroup, g_RegSet, sIndex, 1, lValue);
//   }
//   return err;
//}

// ATTENZIONE ! Questa funzione è corretta, la documentazione riportava
// i flag di add e replace invertiti
static short StatAdd(short sIndex, long lValue)
{
	short i_err;

	i_err = L_STAT_ENTRY( g_StatGroup,
						  g_RegSet,
						  sIndex,
						  0,
						  lValue );

	if (i_err == P2_ST_BUFFER_FULL)
	{
		L_STAT_BUMP();

		i_err = L_STAT_ENTRY( g_StatGroup,
						      g_RegSet,
						      sIndex,
						      0,
						      lValue );
	}

	if(i_err != 0)
	{
		log_(LOG_ERROR,"%s: Err.[%d] L_STAT_ENTRY",
				__FUNCTION__,
				i_err);
	}

	return i_err;
}

//
// calcola l'intervallo di tempo tra due bump
//
static long stat_timerval ( long i_stat_interval )
{
    long		i_cents_wait;
    long long	L_interval;

    L_interval = (long long)((1000000 * (long long)i_stat_interval));

    i_cents_wait = (long)(L_interval - ((long long)(JULIANTIMESTAMP(0) % L_interval) ) );

    if( !i_cents_wait )
        i_cents_wait = (long)(i_stat_interval * 100);
    else
    {
        i_cents_wait /= 10000;
        if(i_cents_wait > 200)
        	i_cents_wait += 60;
        else
        	i_cents_wait += 200;
    }

    return i_cents_wait;
}

short SetTimerBump_( long l_stat_bump_interval, // in seconds
                     long l_tag )

{
      short i_ret = 0;
      long  timerval;

      timerval = (long)stat_timerval( l_stat_bump_interval );

      if( timerval < 300 )
          timerval += 300;

      if( SIGNALTIMEOUT_( timerval ,
                          0 ,
                          l_tag ) )
      {
          i_ret = 1;
      }

      return i_ret;
}
