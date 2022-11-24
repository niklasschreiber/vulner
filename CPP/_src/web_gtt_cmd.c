#if (_TNS_E_TARGET)
T0000H06_21JUN2018_KTSTEA10_01() {};
#elif (_TNS_X_TARGET)
T0000L16_21JUN2018_KTSTEA10_01() {};
#endif

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <tal.h>
#include <cextdecs.h (FILE_OPEN_, FILE_CLOSE_)>
#include <cextdecs.h (WRITEREADX)>

#include "sspdefs.h"
#include "sspfunc.h"
#include "ssplog.h"

#include <cgi.h>
#include "tfs2.h"
#include "web_func.h"


/*----------------------------------------------------------------------*/
void   Invia_cmd(void);
static short PassProcess_Open( short *filenumber);
static short PassProcess_Close(short filenumber);
static short SendMsgToGuardian(short filenumber, char msgoss[], short size);
short  get_commands(char *ini_file);
void   Crea_Ins(void);

/*----------------------------------------------------------------------*/
char	*p_script_name;

/*----------------------------------------------------------------------*/
/* struttura per l'elenco dei comandi */
#pragma fieldalign shared2 __lista_cmd
typedef struct __lista_cmd
{
   char			comando[256];
} lista_cmd;
lista_cmd	elenco[50];

/* strutture per il messaggio */
typedef struct MsgFromOSS
{
	short	taskID;
	short	ServerClass;
	char	cpu[16];
	char	command[256];
}MsgFromOSS;

/***********************************************************************************************************/
int main(int argc, char *argv[])
{
	char * wrk_str;
	char dummy[256];
	int	 ret;

    disp_Top = 0;

	/*---------------------------------------*/
	/* assegna alla CGI l'utente loggato     */
	/*---------------------------------------*/
	ret = cgi_session_verify(dummy);

	if (ret == 0)
	{
		printf ("<center><font color='red'>%s</font></center>", dummy);
		return(0);
	}

	/*---------------------------------------*/
	/* LETTURA VARIABILI D'AMBIENTE		     */
	/*---------------------------------------*/
	/**** NOME INI */
	if ( (wrk_str = getenv( "INI_FILE" ) ) != NULL )
		strcpy(ini_file, wrk_str);
	else
	{
		Display_Message(-1, "", "INI_FILE");

		return(0);
	}

	/*--------------------------------
	   Init per LOG Sicurezza
	 --------------------------------*/
	memset(&log_spooler, 0, sizeof(log_spooler));
	if ( InitSLOG() )
		return(0);
	sprintf(log_spooler.NomeDB, "GTT command");	// max 20 char

	/* Legge OPERAZIONE da eseguire */
	if ( (wrk_str = cgi_param( "OPERAZIONE" ) ) == NULL )
	{
		Display_Message(-1, "", "OPERAZIONE");
		return(0);
	}

	// Nome cgi
	p_script_name = getenv("SCRIPT_NAME");

	/*--------------------*/
	/* ESEGUE OPERAZIONE  */
	/*--------------------*/
	if (!strcmp(wrk_str, "CREA_INS"))
	{
		Crea_Ins();
	}
	else if (!strcmp(wrk_str, "INVIA"))
	{
		Invia_cmd();
	}

	return(0);
}

/***********************************************************************************************************/
void Invia_cmd(void)
{
	char * ptr;
	char  sTmp[50];
	short ret = 0;
	short filenumber;
	MsgFromOSS 	msgoss;

	memset(&msgoss, 0x00, sizeof(MsgFromOSS));

	/*************************
	* legge parametri
	*************************/
	ptr = cgi_param("TASKID");
	msgoss.taskID = (short)atoi(ptr);

	ptr = cgi_param("SRVCLS");
	msgoss.ServerClass = (short)atoi(ptr);

	ptr = cgi_param("COMANDO");
	strcpy( msgoss.command, ptr );

	/*------------------------------*/
	/* LOG SICUREZZA				*/
	/*------------------------------*/
	sprintf(log_spooler.ParametriRichiesta, "TaskId=%d;SrvClass=%d", msgoss.taskID, msgoss.ServerClass);
	strcpy(log_spooler.TipoRichiesta, "UPD");			// LIST, VIEW, NEW, UPD, DEL
	LOGResult = SLOG_OK;

	/* riempie il campo CPU di ZERI */
	memset( msgoss.cpu, '0', sizeof(msgoss.cpu) );
	/* legge le CPU */
	if ( (ptr = cgi_param("CPU00")) != NULL )
		msgoss.cpu[15] = '1';
	if ( (ptr = cgi_param("CPU01")) != NULL )
		msgoss.cpu[14] = '1';
	if ( (ptr = cgi_param("CPU02")) != NULL )
		msgoss.cpu[13] = '1';
	if ( (ptr = cgi_param("CPU03")) != NULL )
		msgoss.cpu[12] = '1';
	if ( (ptr = cgi_param("CPU04")) != NULL )
		msgoss.cpu[11] = '1';
	if ( (ptr = cgi_param("CPU05")) != NULL )
		msgoss.cpu[10] = '1';
	if ( (ptr = cgi_param("CPU06")) != NULL )
		msgoss.cpu[9] = '1';
	if ( (ptr = cgi_param("CPU07")) != NULL )
		msgoss.cpu[8] = '1';
	if ( (ptr = cgi_param("CPU08")) != NULL )
		msgoss.cpu[7] = '1';
	if ( (ptr = cgi_param("CPU09")) != NULL )
		msgoss.cpu[6] = '1';
	if ( (ptr = cgi_param("CPU10")) != NULL )
		msgoss.cpu[5] = '1';
	if ( (ptr = cgi_param("CPU11")) != NULL )
		msgoss.cpu[4] = '1';
	if ( (ptr = cgi_param("CPU12")) != NULL )
		msgoss.cpu[3] = '1';
	if ( (ptr = cgi_param("CPU13")) != NULL )
		msgoss.cpu[2] = '1';
	if ( (ptr = cgi_param("CPU14")) != NULL )
		msgoss.cpu[1] = '1';
	if ( (ptr = cgi_param("CPU15")) != NULL )
		msgoss.cpu[0] = '1';

	/*************************
	* apre processo a cui inviare
	*************************/
	ret = PassProcess_Open( &filenumber );

	if(ret)
	{
		sprintf(sTmp, "Process Open Failed - Error <%d>", ret);
		Display_Message(0, "", sTmp);

	}
	else
	{
		/*************************
		* invia messaggio
		*************************/
		ret = SendMsgToGuardian(filenumber,(char *) &msgoss, (short) sizeof(MsgFromOSS));
		if(ret)
		{
			sprintf(sTmp, "Messagge Sent Failed - Error <%d>", ret);
			Display_Message(0, "", sTmp);
		}
		else
			Display_Message(0, "", "Messagge Sent Successfully");

		PassProcess_Close(filenumber);
	}

	if(ret)
		LOGResult = SLOG_ERROR;

	/*------------------------------*/
	/* LOG SICUREZZA				*/
	/*------------------------------*/
	log_spooler.EsitoRichiesta = LOGResult;
	Log2Spooler(&log_spooler, EVT_ON_ERROR);

	return;
}

/***********************************************************************************************************/
static short PassProcess_Open( short *filenumber)
{

	int		ret;
	int		found=1;
	char	dummy[256];
	char    proc_name[10];

	ret = get_profile_string( ini_file, "GTT", "PROCESS", &found, dummy );
	if ( ret == 0 && found==1 )
	{
		strcpy(proc_name, dummy);

		if( ( FILE_OPEN_( proc_name, (short) strlen(proc_name), filenumber, 0, 0, , , ) ) == 0)
			return 0;
	}

	return 1;
}

/***********************************************************************************************************/
static short SendMsgToGuardian(short filenumber, char msgoss[], short size)
{
	short bytesread;
	_cc_status  CC;

	CC = WRITEREADX( filenumber,
						 msgoss,
						 size,
						 size,
						 &bytesread
						);

	if(_status_ne(CC))
		return 1;

	return 0;
}

/***********************************************************************************************************/
static short PassProcess_Close(short filenumber)
{
	if( ( FILE_CLOSE_(filenumber) ) == 0)
		return 0;

	return 1;
}

/******************************************************************************/
/* get_commands    ************************************************************/
/******************************************************************************/
short get_commands(char *ini_file)
{
	short   i = 0;
	int		ret;
	int		found=1;
	char	dummy[256];
	char	*ptr_cmd;

	/*------------------------------*/
	/* LETTURA da file INI  */
	/*------------------------------*/
	ret = get_profile_string( ini_file, "GTT", "COMMANDS", &found, dummy );
	if ( ret == 0 && found==1 )
	{
		ptr_cmd = strtok(dummy, ",;|");
		while (ptr_cmd)
		{
			strcpy(elenco[i].comando, ptr_cmd);
			i++;

			ptr_cmd = strtok((char *)NULL, ",;|");
		}
	}

	/* torna l'ultimo indice utile */
	return((short)(i-1));
}

/******************************************************************************/
/*  CREA_INS      *************************************************************/
/******************************************************************************/
void Crea_Ins(void)
{
	short   i, x;
	short   isTaskID = 0;
	short   isServerClass = 0;
	int		ret;
	int		found=1;
	char	dummy[256];

	/*------------------------------*/
	/* LETTURA da file INI  */
	/*------------------------------*/
	ret = get_profile_string( ini_file, "GTT", "TASK-ID", &found, dummy );
	if ( ret == 0 && found==1 )
	{
		isTaskID = (short)atoi(dummy);
	}

	ret = get_profile_string( ini_file, "GTT", "SERVER-CLASS", &found, dummy );
	if ( ret == 0 && found==1 )
	{
		isServerClass = (short)atoi(dummy);
	}

	/* carica i comandi */
	i = get_commands(ini_file);

	/*------------------------------*/
	/* Creazione Pagina HTML        */
	/*------------------------------*/
	Display_TOP("Send a Command");

	printf("		<fieldset ><legend> Command&nbsp;</legend>\n");
	printf("		<br><center>\n");
	printf("		<FORM name='insert' METHOD=POST ACTION='%s' onsubmit='return Controlla()'>					\n", p_script_name);
	printf("			<INPUT TYPE='hidden' name='OPERAZIONE' value='INVIA'>										\n");
	printf("			<TABLE>																						\n");
	printf("				<TR height=45>																			\n");
	printf("					<TH align=right>Task ID:</TH>														\n");
	printf("					<TD colspan=9><INPUT TYPE='text' SIZE='10' MAXLENGTH='5' NAME='TASKID' VALUE='%d'>&nbsp;</TD>	\n", isTaskID);
	printf("				</TR>																					\n");
	printf("				<TR height=45>																			\n");
	printf("					<TH align=right>Server Class:</TH>													\n");
	printf("					<TD colspan=9><INPUT TYPE='text' SIZE='10' MAXLENGTH='5' NAME='SRVCLS' VALUE='%d'>&nbsp;</TD>	\n", isServerClass);
	printf("				</TR>																					\n");
	printf("				<TR align=right>																		\n");
	printf("					<TH align=right>CPU:</TH>															\n");
	printf("					<td>0 <INPUT TYPE='checkbox' NAME='CPU00'>&nbsp;&nbsp;</td>							\n");
	printf("					<td>1 <INPUT TYPE='checkbox' NAME='CPU01'>&nbsp;&nbsp;</td>							\n");
	printf("					<td>2 <INPUT TYPE='checkbox' NAME='CPU02'>&nbsp;&nbsp;</td>							\n");
	printf("					<td>3 <INPUT TYPE='checkbox' NAME='CPU03'>&nbsp;&nbsp;</td>							\n");
	printf("					<td>4 <INPUT TYPE='checkbox' NAME='CPU04'>&nbsp;&nbsp;</td>							\n");
	printf("					<td>5 <INPUT TYPE='checkbox' NAME='CPU05'>&nbsp;&nbsp;</td>							\n");
	printf("					<td>6 <INPUT TYPE='checkbox' NAME='CPU06'>&nbsp;&nbsp;</td>							\n");
	printf("					<td>7 <INPUT TYPE='checkbox' NAME='CPU07'>&nbsp;&nbsp;</td>							\n");
	printf("					<TD><input TYPE='button' icon='ui-icon-plusthick' VALUE='&nbsp;Selected All&nbsp;&nbsp;' style='width:50px' onclick='Select_All(true)'></TD>		\n");
	printf("				</TR>																					\n");
	printf("				<TR align=right>																		\n");
	printf("					<TH align=right>&nbsp;</TH>															\n");
	printf("					<td>8 <INPUT TYPE='checkbox' NAME='CPU08'>&nbsp;&nbsp;</td>							\n");
	printf("					<td>9 <INPUT TYPE='checkbox' NAME='CPU09'>&nbsp;&nbsp;</td>							\n");
	printf("					<td>10 <INPUT TYPE='checkbox' NAME='CPU10'>&nbsp;&nbsp;</td>						\n");
	printf("					<td>11 <INPUT TYPE='checkbox' NAME='CPU11'>&nbsp;&nbsp;</td>						\n");
	printf("					<td>12 <INPUT TYPE='checkbox' NAME='CPU12'>&nbsp;&nbsp;</td>						\n");
	printf("					<td>13 <INPUT TYPE='checkbox' NAME='CPU13'>&nbsp;&nbsp;</td>						\n");
	printf("					<td>14 <INPUT TYPE='checkbox' NAME='CPU14'>&nbsp;&nbsp;</td>						\n");
	printf("					<td>15 <INPUT TYPE='checkbox' NAME='CPU15'>&nbsp;&nbsp;</td>						\n");
	printf("					<TD><input TYPE='button' icon='ui-icon-minusthick' VALUE='Unselected All' style='width:50px' onclick='Select_All(false)'></TD>			\n");
	printf("				</TR>																					\n");
	printf("				<TR height=45>																			\n");
	printf("					<TH align=right>Command:</TH>														\n");
	printf("					<TD colspan=9>																		\n");
	printf("						<SELECT NAME='COMANDO' class='chosen-select'>															\n");
	for (x=0; x<=i; x++)
		printf("					<option value='%s'>%s</option>													\n", elenco[x].comando, elenco[x].comando);
	if ( i<0 )
		printf("					<option value=' '>---</option>													\n");
	printf("						</SELECT>																		\n");
	printf("					</TD>																				\n");
	printf("				</TR>																					\n");
	printf("			</TABLE></center> \n");
	printf("			</fieldset>																						\n");
	printf("			<BR><BR><center>\n");
	//printf("			<input TYPE='button' icon='ui-icon-home'  VALUE='Back' onclick='javascript:history.back()'>\n");
	printf("			<input TYPE='submit' icon='ui-icon-play' VALUE='Send Command'>&nbsp;\n");
	printf("			<input TYPE='reset'  icon='ui-icon-arrowrefresh-1-n' VALUE='Reset'>	\n");
	printf("		</center>\n");
	printf("		</FORM>	\n");
	printf("	</BODY>	\n");
	printf("</HTML>	\n");

	return;
}

