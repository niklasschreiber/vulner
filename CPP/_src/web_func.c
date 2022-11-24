//---------------------< Include files >-------------------------------------
#pragma nolist
#include <unistd.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <errno.h>
#include <time.h>
#include <ctype.h>
#include <tal.h>
#include <usrlib.h>
#include <cextdecs.h(JULIANTIMESTAMP, INTERPRETTIMESTAMP, CONVERTTIMESTAMP, COMPUTETIMESTAMP )>
#include <cextdecs.h(FILE_CREATE_,FILE_PURGE_,FILE_OPEN_,FILE_SETPOSITION_)>
#include <cextdecs.h(FILE_CLOSE_,WRITEX,FILE_GETINFO_)>
#include <cextdecs.h (PROCESSHANDLE_GETMINE_, PROCESSHANDLE_DECOMPOSE_)>
#include <stdarg.h>
#include <pwd.h>

#include <sspfunc.h>
#include <sspdefs.h>

// log sicurezza
#include "sspevt.h"
#include "SLog.h"
#include "cgi.h"

#include "tfs2.h"
#include "tfs3.h"
#include "web_func.h"

/* --------------------------------------------------------------------------*/
void Display_TOP(char *txt)
{
	if( disp_Top == 1)
		return;

    printf("Content-type: text/html\n\n");
    disp_Top = 1;

    // senza questa riga explorer non visualizza correttabente le datatable
    printf("<!DOCTYPE HTML PUBLIC '-//W3C//DTD HTML 4.01//EN' 'http://www.w3.org/TR/html4/strict.dtd'>");

    printf( "<HTML>\n");
 	printf( "<HEAD>\n\n");
    printf( "<TITLE>\n\n");
	printf( "</TITLE>\n\n");

	printf("<meta charset='UTF-8'>\n");

	// **************************  CSS  **************************************************************
	printf( "<link rel='stylesheet' href='/services/plugins/jquery/tables.css'>\n");
	printf( "<link rel='stylesheet' href='/services/plugins/jquery/ui/themes/tim/jquery-ui.css'>\n");
	printf( "<link rel='stylesheet' href='/services/plugins/jquery/chosen/chosen.css'>\n");
	printf( "<link rel='stylesheet' href='/services/plugins/jquery/datetimepicker/jquery.datetimepicker.css'></script>\n");

	printf( "<link rel='stylesheet' href='tfs2.css'>\n");

	// **************************  Script JS ************************************************************
	printf( "<script src='/services/plugins/jquery/jquery.js'></script>\n");
	printf( "<script src='/services/plugins/jquery/ui/themes/tim/jquery-ui.js'></script>\n");
	printf( "<script src='/services/plugins/jquery/jquery.dataTables.js'></script>\n");
	printf( "<script src='/services/plugins/jquery/datetimepicker/jquery.datetimepicker.js'></script>\n");

	printf( "<script src='/services/plugins/jquery/chosen/chosen.jquery.js'></script>\n");
	printf( "<script src='/services/plugins/jquery/chosen/prism.js'></script>\n");

	printf( "<script type='text/javascript' src='/services/plugins/jquery/jquery.alphanumeric.js'></script>\n");
	printf( "<script type='text/javascript' src='/services/plugins/jquery/genericJQfunction.js'></script>\n");

	printf("<script Language=Javascript SRC='tfs2.js'></script>\n");

	// **********************************************************************************************************

	printf("<script>");
	// in greentab-num la prima colonna viene gestita come numerico
	printf("$(document).ready(function() {\n\
					oTable = $('#greentab').dataTable({\n\
						'bJQueryUI': true,\n\
						'iDisplayLength': 25,\n\
						'sPaginationType': 'full_numbers'\n\
					});\n\
					oTable = $('#greentab-num').dataTable({\n\
						'columnDefs': [\n\
						{ 'type': 'numeric-comma', targets: 0 }],\n\
						'bJQueryUI': true,\n\
						'iDisplayLength': 25,\n\
						'sPaginationType': 'full_numbers'\n\
					});\n\
			        oTable2 = $('#nosort').dataTable(\n\
					{\n\
						'bSort': false,\n\
						'bJQueryUI': true,\n\
						'iDisplayLength': 25,\n\
						'sPaginationType': 'full_numbers'\n\
					});\n");
		printf( "oTable3 = $('#noFeature').dataTable( {\n\
					'bJQueryUI': true,\n\
			        'bPaginate': false,\n\
					'bLengthChange': false,\n\
					'bFilter': false,\n\
					'bSort': false,\n\
					'bInfo': false,\n\
					'bAutoWidth': false } );\n ");
	printf("});\n\
			</script>\n");  // fine ready e script

	// *******************  gestione calendario ***********************************************
	printf("<script>\n");
		printf("$(function() {\n");

		printf("$.each($('.onlytimepic'), function() {\n\
				$(this).datetimepicker({\n\
						datepicker:false,\n\
						format:'H:i',\n\
						step:5\n});\n\
					});");

		printf("$.each($('.datetimepic'), function() {\n\
				$(this).datetimepicker({\n\
						format:'d/m/Y H:i:s'});\n\
				});");

		printf("$('#onlydate').datepicker({\n\
				dateFormat: 'dd/mm/yy'\n });\n");

		printf("});\n");
	printf("</script>\n");

	// *********************    finestre di dialogo  *********************************************
	printf("<script>\n");
		printf("$(document).ready(function(){\n");

		printf("$('#checkLenWin').dialog({\n\
				modal: true,\n\
				buttons: {\n\
					'Close': function() {\n\
					 $( this ).dialog( 'close' );\n\
					 window.history.back(-1);\n\
									   }\n\
					  }\n\
				});\n");

		printf("$('#confirmWin').dialog({\n\
				modal: true,\n\
				autoOpen: false,\n\
				buttons: {\n\
				'Cancel': function() {\n\
						$( this ).dialog( 'close' );\n\
						},\n\
				'Confirm': function(){\n\
						onclickdialog($('#url').text());\n\
					   }\n\
					}\n\
			  });\n");

		printf("});\n");

		printf("function onclickdialog(url)   {\n\
				 location=url;\n\
				  }\n");
	printf("</script>\n");

	// ************************  chosen  ****************************************
	printf("<script>\n");
		printf("$(document).ready(function() {\n\
				var config = {\n\
						  '.chosen-select'           : {},\n\
						  '.chosen-select-deselect'  : {allow_single_deselect:true},\n\
						  '.chosen-select-no-single' : {disable_search_threshold:10},\n\
						  '.chosen-select-no-results': {no_results_text:'Oops, nothing found!'},\n\
						  '.chosen-select-width'     : {width:'95%%'}\n\
						}\n\
						for (var selector in config) {\n\
						  $(selector).chosen(config[selector]);\n\
						}\n");

		printf(" $.each($('.noSearch'), function() {\n\
						$(this).chosen({\n\
						'disable_search': true });\n\
						});\n");
		 ;
		printf("});\n");	// fine ready e script
	printf("</script>\n");


	/* **********************************************************************
	$('.sample1').alphanumeric();				 Allow only alphanumeric characters
	$('.sample2').alphanumeric({allow:".,-"});	Allow only alphanumeric characters, and some exceptions like dot(.), comma (,) and  minus(-)
	$('.sample3').alpha({nocaps:true});			Allow only lowercase alpha characters
	$('.sample4').numeric();					Allow only numeric characters
	$('.sample5').numeric({allow:"."});			Allow only numeric characters, and some exceptions like dot (.)
	$('.sample6').alphanumeric({ichars:'.1a'});	Make a custom rule and define only certain characters to prevent, like dot (.), one (1), and a (a)
	************************************************************************** */
	printf("<script>");
		printf("$(document).ready(function() {\n");
		printf(" $('.numeric').numeric();	\n\
				 $('.alphanumeric').alphanumeric({allow:'.,-'}); \n\
				})\n");
	printf("</script>\n");

 	printf( "</HEAD>\n\n");

	// ****************************************************************************************************
 	printf( "<body >\n	");
	printf("<BR>\n");
	if(txt[0] != 0)
		printf("<h2><center>%s</center></h2>\n", txt);
	fflush(stdout);
}
/* --------------------------------------------------------------------------*/
void Display_BOTTOM(void)
{
	printf("<SCRIPT LANGUAGE='JavaScript'>\n\
				 document.body.style.cursor='default';\n\
			</SCRIPT>");

  	printf("</BODY>\n");
    printf("</HTML>\n");
}

/******************************************************************************/
/* DISPLAY_MESSAGE ************************************************************/
/******************************************************************************/
void Display_Message(short nTipo, char *sTxt, char *sMessaggio)
{
	if (disp_Top == 0)
		Display_TOP(sTxt);

	printf("<CENTER>");
	switch ( nTipo  )
	{
		/* manca parametro */
		case -1:
		{
			printf("Parameter %s is missed\n", sMessaggio);
		//	printf("<BR><BR><BR><input TYPE='button' icon='ui-icon-home' VALUE='Back' name='back' onclick='javascript:history.go(-1);return false;'>\n");
			break;
		}
		/* manca parametro */
		case -2:
		{
			printf("Parameter %s is missed\n", sMessaggio);
			printf("<BR><BR><BR><input TYPE='button' icon='ui-icon-circle-close' VALUE='Close' onclick=\"javascript:window.close()\">\n");
			break;
		}

		/* messaggio */
		case 0:
		{
			printf("<B>%s</B>\n", sMessaggio);
			break;
		}
		case 1:
		{
			printf("%s\n", sMessaggio);
			printf("<BR><BR><BR><input TYPE='button' icon='ui-icon-home' VALUE='Back' name='back' onclick='javascript:history.go(-1);return false;'>\n");

			break;
		}
		case 2:
		{
			printf("%s\n", sMessaggio);
			printf("<BR><BR><BR><input TYPE='button' icon='ui-icon-circle-close' VALUE='Close' onclick=\"javascript:window.close()\" >	\n");
			
			break;
		}

		default:
		{
			break;
		}
	}  /* switch */


	printf("<SCRIPT LANGUAGE='JavaScript'>\n\
			 document.body.style.cursor='default';\n\
			</SCRIPT>");


	printf("</center></BODY>\n");
	printf("</HTML>");

	fflush(stdout);
}



/******************************************************************************/
/* APRI_FILE	  *************************************************************/
// display = 1 visualizza messaggio
/******************************************************************************/
short Apri_File(char *nomefile, short *handle, short display, short tipo)
{
	short localhandle = -1;
	short ret = 0;
	char sTmp[500];

	ret = MBE_FILE_OPEN_( nomefile, (short)strlen(nomefile), &localhandle);

	/* errore */
	if (ret != 0)
	{
		sprintf(sTmp, "Error %d in opening file [%s]", ret, nomefile);
		if (display)
			Display_Message(tipo, "Operation result", sTmp );
	}
	else
		*handle = localhandle;

	return(ret);
}
/******************************************************************************
** Remove trailing blank in a null terminated string
******************************************************************************/
char *AlltrimString( char *str1 )
{
    char *sret = str1;
    int nn;
    int pos;

    pos = -1;

    for ( nn = (int)strlen( sret)-1; nn >= 0; nn-- )
    {
        if ( sret[nn] == ' ' )
            pos = nn;
        else
            break;
    }

    if ( pos != -1 )
        sret[pos] = 0;

	pos = 0;
    for ( nn = 0; nn < (int)strlen( sret); nn++ )
    {
        if ( sret[nn] != ' ' )
		{
            pos = nn;
			break;
		}
    }

	sret += pos;

	return( sret );
}

//********************************************************************************
void GetLocalTimeStamp(long long *jts) 
{
	*jts = CONVERTTIMESTAMP( JULIANTIMESTAMP(0), 0 );
	return;
}

//********************************************************************************
// converte una data da Local in GMT (Greenwich)
//********************************************************************************
void ConvertLocal_To_GMT(long long *loc_jts, long long jts) 
{
	*loc_jts = CONVERTTIMESTAMP( jts, 2 );
	return;
}

//********************************************************************************
// converte una data da GMT in Local Time
//********************************************************************************
void ConvertGMT_To_Local(long long *loc_jts, long long jts) 
{
	*loc_jts = CONVERTTIMESTAMP( jts, 0 );
	return;
}

void CambiaCar( char *instr )
{
	char *val = "+-$&#?\"'^%*/";
	short res = -1;
	char  mod1[1000];
	char  mod2[1000];
	char  sTmp[1000];
	char  modAppo[1000];

	memset(mod1, 0, sizeof(mod1));
	memset(mod2, 0, sizeof(mod2));
	memset(modAppo, 0, sizeof(modAppo));

	strcpy( mod1, instr );
   // strcpy( mod2, mod1 );

	do
    {
        res = (short) strcspn(mod1, val);

        if ( res != strlen(mod1) )
        {
            //sprintf( &(mod2[res]), "%%%X%s", mod1[res], &(mod1[res+1]) );
            //strcpy( mod1, mod2 );
			strncat(mod2, mod1, res);
            sprintf(sTmp, "%%%X", mod1[res]);
			strcat(mod2, sTmp);
            sprintf( modAppo, "%s", &(mod1[res+1]) );
			strcpy(mod1, modAppo);
        }
        else
        {
			strcat(mod2, mod1);
            break;
        }

	} while (1);

	strcpy( instr, mod2 );
}
/* --------------------------------------------------------------------------*/
char *Togli_Spazi(char *str)
{
	int i = 0;

	for ( i = (int) strlen(str)-1; i>=0; i-- )
	{
		if (isspace(str[i]))
		{
			str[i] = '\0';
		}
		else
			break;

	}
	return(str);
}
/******************************************************************************/
/* User_is_RW			 **********************************************************/
/******************************************************************************/
short User_is_RW(void) 
{
	char	*ptrc;
	char	user_rw[300];
	char	remote_user[200];
	short	ret;

	/*******************
	* controllo utente
	********************/
	/* legge dal file config la lista di utenti abilitati in RW */
	if ( (ptrc = getenv( "USER_RW" ) ) != NULL )
		sprintf( user_rw, "%s,", ptrc );
	else
		//strcpy(user_rw, "user.mgr,");
		return(1);

	/* legge l'utente corrente (passato da webserver) */
	if ( (ptrc = getenv( "REMOTE_USER" ) ) != NULL )
	{
		/* aggiunge una virgola in fondo */
		sprintf( remote_user, "%s,", ptrc );
	}
	else
		strcpy(remote_user, "user.readonly,");

	/* se l'utente è nella lista... è abilitato in RW */
	if (strstr(user_rw, remote_user ) != NULL) 
	   ret = 1;
	else 
	   ret = 0;

	return(ret);
}
// ---------------------------------------
// Name:  charflip
//                                                                        
// Description:  Inverts char in a string
// ---------------------------------------
/*char *charflip( char *input, short input_length, char *output )
{
	int i, j;

	for ( i = 0; i < input_length; ++i ) 
	{
		j = input_length - 1 - i ;
		output[j] = input[i];
	}

	return output;
} */ // charflip
/******************************************************************************/
/* timestamp2string  **********************************************************/
/******************************************************************************/
char *TS2string(char stringa[], long long jts) 
{
	short jtime[8];
	if(jts == 0) return "";
	//if(!memcmp("        ",(char*)&jts,8)) return "";
	
	if ( INTERPRETTIMESTAMP(jts, jtime) == -1 )
	{
		strcpy( stringa, "" );
	}
	else
	{
		sprintf( stringa,"%02u/%02u/%04u %02u:%02u:%02u",
							jtime[2],
							jtime[1],
							jtime[0],
							jtime[3],
							jtime[4],
							jtime[5]);
	}
    return stringa;
}
/******************************************************************************/
/* timestamp2string  **********************************************************/
/******************************************************************************/
char *TS2stringAAMMGG(char stringa[], long long jts) 
{
	short jtime[8];
	if(jts == 0) return "";
	
	if ( INTERPRETTIMESTAMP(jts, jtime) == -1 )
	{
		strcpy( stringa, "" );
	}
	else
	{
		sprintf( stringa,"%04u%02u%02u%02u%02u%02u",
							jtime[0],
							jtime[1],
							jtime[2],
							jtime[3],
							jtime[4],
							jtime[5]);
	}
    return stringa;
}

/******************************************************************************/
/* string2TS  **********************************************************/
/******************************************************************************/
long long string2TS(char *stringa) 
{
	short jtime[8];
	char sTmp[50];

	//"GG/MM/AAAA HH:MM:SS
    //"0123456789012345678

	memset( sTmp, 0, 5 );
	memcpy( sTmp, stringa+0, 2 );
	jtime[2] = (short) atoi(sTmp);

	memset( sTmp, 0, 5 );
	memcpy( sTmp, stringa+3, 2 );
	jtime[1] = (short) atoi(sTmp);

	memset( sTmp, 0, 5 );
	memcpy( sTmp, stringa+6, 4 );
	jtime[0] = (short) atoi(sTmp);

	memset( sTmp, 0, 5 );
	memcpy( sTmp, stringa+11, 2 );
	jtime[3] = (short) atoi(sTmp);

	memset( sTmp, 0, 5 );
	memcpy( sTmp, stringa+14, 2 );
	jtime[4] = (short) atoi(sTmp);

	memset( sTmp, 0, 5 );
	memcpy( sTmp, stringa+17, 2 );
	jtime[5] = (short) atoi(sTmp);

	jtime[6] = 0;
	jtime[7] = 0;

	return( COMPUTETIMESTAMP(jtime) );
}
/******************************************************************************/
/* string2TS  **********************************************************/
/******************************************************************************/
long long stringAAMMGG2TS(char *stringa) 
{
	short jtime[8];
	char sTmp[50];

	//"AAAAMMGGHHMMSS
    //"0123456789012345678

	memset( sTmp, 0, 5 );
	memcpy( sTmp, stringa, 4 );
	jtime[0] = (short) atoi(sTmp);

	memset( sTmp, 0, 5 );
	memcpy( sTmp, stringa+4, 2 );
	jtime[1] = (short) atoi(sTmp);

	memset( sTmp, 0, 5 );
	memcpy( sTmp, stringa+6, 2 );
	jtime[2] = (short) atoi(sTmp);

	memset( sTmp, 0, 5 );
	memcpy( sTmp, stringa+8, 2 );
	jtime[3] = (short) atoi(sTmp);

	memset( sTmp, 0, 5 );
	memcpy( sTmp, stringa+10, 2 );
	jtime[4] = (short) atoi(sTmp);

	memset( sTmp, 0, 5 );
	memcpy( sTmp, stringa+12, 2 );
	jtime[5] = (short) atoi(sTmp);

	jtime[6] = 0;
	jtime[7] = 0;

	return( COMPUTETIMESTAMP(jtime) );
}

void GetTimeStamp(long long *jts) 
{
	*jts = JULIANTIMESTAMP(0);
	return;
}

//*******************************************************
// Conversione da numerico a stringa[4]
void shortToHex(unsigned short usval, char *hexbuf)
{
char hexTab[] = "0123456789ABCDEF";

    hexbuf[0] = hexTab[usval >> 12];
    hexbuf[1] = hexTab[(usval >> 8) & 0x0F];
    hexbuf[2] = hexTab[(usval >> 4) & 0x0F];
    hexbuf[3] = hexTab[usval & 0x0F];
}
//********************************************************************************
char luhnvalue(char *card)
{
      unsigned char tmp, sum, i, j;
      sum = i = j = 0;
 
      // Last digit is the first odd digit
      while (card[i] >= '0' && card[i] <= '9') i++;
 
      while (i--)
      {
          tmp = card[i] & 0x0F; 
 
          // This is an odd digit
          if (!(j++ & 1))
          {
              // Twice the odd digit is greater than 9 => sum the individual digits, e.g. 16 -> 1 + (16-10)
              if ((tmp<<=1) > 9)
              {
                  tmp -= 10;
                  sum++;
              }
          }
          sum += tmp;
      } 
 
      return (10 - (sum % 10)) %10 + '0';
}


//*************************************************************************************
char *SistemaApice(char stringa[],char *sPaese)
{
int i = 0;
int k = 0;


	for( i=0; i < strlen(sPaese); i++,k++)
	{
		if (sPaese[i] == '\'')
		{
			stringa[k] = '\\';
			k++;
		}
		stringa[k] = sPaese[i];
	}

	return stringa;
}

//*****************************************************
// trasforma un path oss in guardian
// da /G/dsmscm/ppp/file
// in $dsmscm.ppp.file
//*****************************************************
void Oss2GuardianPath( char *ac_in, char *ac_gua )
{
	char *ptr;
	char ac_oss[100];

	strcpy(ac_oss, ac_in);

	strcpy( ac_gua, "$" );

	ptr = strtok( ac_oss+3, "/" );
	if (ptr!= NULL)
	{
		strcat( ac_gua, ptr );
		strcat( ac_gua, "." );

		ptr = strtok( NULL, "/" );
		if (ptr!= NULL)
		{
			strcat( ac_gua, ptr );
			strcat( ac_gua, "." );
			ptr = strtok( NULL, "/" );
			if (ptr!= NULL)
			{
				strcat( ac_gua, ptr );
			}
		}
	}
	
	return;
}
//*****************************************************
// trasforma un path oss in guardian
// da $dsmscm.ppp.file
// in /G/dsmscm/ppp/file
//*****************************************************
void Guardian2OssPath( char *ac_in, char *ac_gua )
{
	char *ptr;
	char ac_oss[100];

	strcpy(ac_oss, ac_in);

	strcpy( ac_gua, "/G/" );

	ptr = strtok( ac_oss+1, "." );
	if (ptr!= NULL)
	{
		strcat( ac_gua, ptr );
		strcat( ac_gua, "/" );

		ptr = strtok( NULL, "." );
		if (ptr!= NULL)
		{
			strcat( ac_gua, ptr );
			strcat( ac_gua, "/" );
			ptr = strtok( NULL, "." );
			if (ptr!= NULL)
			{
				strcat( ac_gua, ptr );
			}
		}
	}
	
	return;
}
//----------------------------------------------------------------------------------------------------
void Lettura_FileIni()
{
	int		found;
	char	sTmp[500];
	char	ac_wrk_str[1024];

	memset(acFileOperatori_Rem, 0x00, sizeof(acFileOperatori_Rem));
	memset(acFileOperatori_Loc, 0x00, sizeof(acFileOperatori_Loc));
	memset(acFilePaesi_Rem, 0x00, sizeof(acFilePaesi_Rem));
	memset(acFilePaesi_Loc, 0x00, sizeof(acFilePaesi_Loc));
	memset(acFileOperGT_Rem, 0x00, sizeof(acFileOperGT_Rem));
	memset(acFileOperGT_Loc, 0x00, sizeof(acFileOperGT_Loc));
	memset(acFileOperGT_Bord_Rem, 0x00, sizeof(acFileOperGT_Bord_Rem));
	memset(acFileOperGT_Bord_Loc, 0x00, sizeof(acFileOperGT_Bord_Loc));
	memset(acFilePreRules_Rem, 0x00, sizeof(acFilePreRules_Rem));
	memset(acFilePreRules_Loc, 0x00, sizeof(acFilePreRules_Loc));
	memset(acFileNostdtac_Rem, 0x00, sizeof(acFileNostdtac_Rem));
	memset(acFileNostdtac_Loc, 0x00, sizeof(acFileNostdtac_Loc));
	memset(acFileSoglie_Rem,  0x00, sizeof(acFileSoglie_Rem));
	memset(acFileSoglie_Loc,  0x00, sizeof(acFileSoglie_Loc));
	memset(acFileBord_CID_Rem, 0x00, sizeof(acFileBord_CID_Rem));
	memset(acFileBord_CID_Loc, 0x00, sizeof(acFileBord_CID_Loc));


	memset(acFileImsi, 0x00, sizeof(acFileImsi));
	memset(acFileImsiDat, 0x00, sizeof(acFileImsiDat));
//	memset(acFileImsiLte, 0x00, sizeof(acFileImsiLte));
	memset(acFileImsiGsm_E_Loc, 0x00, sizeof(acFileImsiGsm_E_Loc));
	memset(acFileImsiGsm_E_Rem, 0x00, sizeof(acFileImsiGsm_E_Rem));
	memset(acFileImsiDat_E_Loc, 0x00, sizeof(acFileImsiDat_E_Loc));
	memset(acFileImsiDat_E_Rem, 0x00, sizeof(acFileImsiDat_E_Rem));

	memset(ac_car_table, 0x00, sizeof(ac_car_table));
	memset(acFileApply_PS, 0x00, sizeof(acFileApply_PS));
	memset(acFileApply_ST,  0x00, sizeof(acFileApply_ST));
	memset(acFileImpianti, 0x00, sizeof(acFileImpianti));
	memset(acFileMGT,  0x00, sizeof(acFileMGT));


    // ==========================================================================================
	// GENERAL
	// ==========================================================================================
	//*********************************** OPERATORI ***************************************
	get_profile_string(ini_file, "GENERIC", "DB-REM-OPER-PATH", &found, acFileOperatori_Rem);
	if (found == SSP_FALSE)
	{
		sprintf(sTmp, "Error read file: %s - DB-REM-OPER-PATH", ini_file);
		Display_Message(-1, "", sTmp);
		exit(1);
	}

	get_profile_string(ini_file, "GENERIC", "DB-LOC-OPER-PATH", &found, acFileOperatori_Loc);
	if (found == SSP_FALSE)
	{
		sprintf(sTmp, "Error read file: %s - DB-LOC-OPER-PATH", ini_file);
		Display_Message(-1, "", sTmp);
		exit(1);
	}
	//************************************** OPER GT ***************************************
	get_profile_string(ini_file, "GENERIC", "DB-REM-OPERGT-PATH", &found, acFileOperGT_Rem);
	if (found == SSP_FALSE)
	{
		sprintf(sTmp, "Error read file: %s - DB-REM-OPERGT-PATH", ini_file);
		Display_Message(-1, "", sTmp);
		exit(1);
	}
		get_profile_string(ini_file, "GENERIC", "DB-LOC-OPERGT-PATH", &found, acFileOperGT_Loc);
	if (found == SSP_FALSE)
	{
		sprintf(sTmp, "Error read file: %s - DB-LOC-OPERGT-PATH", ini_file);
		Display_Message(-1, "", sTmp);
		exit(1);
	}
	//************************************** OPER  BORDER GT ***************************************
	get_profile_string(ini_file, "GENERIC", "DB-REM-BORDGT-PATH", &found, acFileOperGT_Bord_Rem);
	if (found == SSP_FALSE)
	{
		sprintf(sTmp, "Error read file: %s - DB-REM-BORDGT-PATH", ini_file);
		Display_Message(-1, "", sTmp);
		exit(1);
	}
		get_profile_string(ini_file, "GENERIC", "DB-LOC-BORDGT-PATH", &found, acFileOperGT_Bord_Loc);
	if (found == SSP_FALSE)
	{
		sprintf(sTmp, "Error read file: %s - DB-LOC-BORDGT-PATH", ini_file);
		Display_Message(-1, "", sTmp);
		exit(1);
	}

	//************************************** COUNTRIES  ***************************************

	get_profile_string(ini_file, "GENERIC", "DB-REM-COUNTRIES-PATH", &found, acFilePaesi_Rem);
	if (found == SSP_FALSE)
	{
		sprintf(sTmp, "Error read file: %s - DB-REM-COUNTRIES-PATH", ini_file);
		Display_Message(-1, "", sTmp);
		exit(1);
	}
	get_profile_string(ini_file, "GENERIC", "DB-LOC-COUNTRIES-PATH", &found, acFilePaesi_Loc);
	if (found == SSP_FALSE)
	{
		sprintf(sTmp, "Error read file: %s - DB-LOC-COUNTRIES-PATH", ini_file);
		Display_Message(-1, "", sTmp);
		exit(1);
	}
	//************************************** SOGLIE ***************************************
	get_profile_string(ini_file, "GENERIC", "DB-REM-THRESHOLDS-PATH", &found, acFileSoglie_Rem);
	if (found == SSP_FALSE)
	{
		sprintf(sTmp, "Error read file: %s - DB-REM-THRESHOLDS-PATH", ini_file);
		Display_Message(-1, "", sTmp);
		exit(1);
	}
	get_profile_string(ini_file, "GENERIC", "DB-LOC-THRESHOLDS-PATH", &found, acFileSoglie_Loc);
	if (found == SSP_FALSE)
	{
		sprintf(sTmp, "Error read file: %s - DB-LOC-THRESHOLDS-PATH", ini_file);
		Display_Message(-1, "", sTmp);
		exit(1);
	}

	//************************************** NOSTD ***************************************
	get_profile_string(ini_file, "GENERIC", "DB-REM-NOSTD-TAC-PATH", &found, acFileNostdtac_Rem);
	if (found == SSP_FALSE)
	{
		sprintf(sTmp, "Error read file: %s - DB-REM-NOSTD-TAC-PATH", ini_file);
		Display_Message(-1, "", sTmp);
		exit(1);
	}
	get_profile_string(ini_file, "GENERIC", "DB-LOC-NOSTD-TAC-PATH", &found, acFileNostdtac_Loc);
	if (found == SSP_FALSE)
	{
		sprintf(sTmp, "Error read file: %s - DB-LOC-NOSTD-TAC-PATH", ini_file);
		Display_Message(-1, "", sTmp);
		exit(1);
	}

	//************************************** PRE STEERING***************************************
	get_profile_string(ini_file, "GENERIC", "DB-REM-PSRULES-PATH", &found, acFilePreRules_Rem);
	if (found == SSP_FALSE)
	{
		sprintf(sTmp, "Error read file: %s - DB-REM-PSRULES-PATH", ini_file);
		Display_Message(-1, "", sTmp);
		exit(1);
	}
	get_profile_string(ini_file, "GENERIC", "DB-LOC-PSRULES-PATH", &found, acFilePreRules_Loc);
	if (found == SSP_FALSE)
	{
		sprintf(sTmp, "Error read file: %s - DB-LOC-PSRULES-PATH", ini_file);
		Display_Message(-1, "", sTmp);
		exit(1);
	}

	//*********************************** LAC CELL ***************************************
	get_profile_string(ini_file, "GENERIC", "DB-LOC-BORDCID-PATH", &found, acFileBord_CID_Loc);
	if (found == SSP_FALSE)
	{
		sprintf(sTmp, "Error read file: %s - DB-LOC-BORDCID-PATH", ini_file);
		Display_Message(-1, "", sTmp);
		exit(1);
	}

	get_profile_string(ini_file, "GENERIC", "DB-REM-BORDCID-PATH", &found, acFileBord_CID_Rem);
	if (found == SSP_FALSE)
	{
		sprintf(sTmp, "Error read file: %s - DB-R-BEMORDCID-PATH", ini_file);
		Display_Message(-1, "", sTmp);
		exit(1);
	}



	// ==========================================================================================
	// parametro DB IMSI
	// ==========================================================================================
	if(acParamIMSI[0] != '\0')
	{
		get_profile_string(ini_file, "GENERIC", acParamIMSI, &found, acFileImsi);
		if (found == SSP_FALSE)
		{
			sprintf(sTmp, "in <%s> - <%s>", ini_file, acParamIMSI);
			Display_Message(-1, "", sTmp);
			exit(1);
		}
	}
	else
	{
		// ==========================================================================================
		//  Usati per gestione record White List
		// ==========================================================================================
		get_profile_string(ini_file, "GENERIC", "IMSI-GSM-MBE-PATH", &found, acFileImsiGsm);
		if (found == SSP_FALSE)
		{
			sprintf(sTmp, "Error read file: %s - IMSI-GSM-MBE-PATH", ini_file);
			Display_Message(-1, "", sTmp);
			exit(1);
		}
		get_profile_string(ini_file, "GENERIC", "IMSI-GSM-ENS-LOC-PATH", &found, acFileImsiGsm_E_Loc);
		if (found == SSP_FALSE)
		{
			sprintf(sTmp, "Error read file: %s - IMSI-GSM-ENS-LOC-PATH", ini_file);
			Display_Message(-1, "", sTmp);
			exit(1);
		}
		get_profile_string(ini_file, "GENERIC", "IMSI-GSM-ENS-REM-PATH", &found, acFileImsiGsm_E_Rem);
		if (found == SSP_FALSE)
		{
			sprintf(sTmp, "Error read file: %s - IMSI-GSM-ENS-REM-PATH", ini_file);
			Display_Message(-1, "", sTmp);
			exit(1);
		}

		//   DAT
		get_profile_string(ini_file, "GENERIC", "IMSI-DAT-MBE-PATH", &found, acFileImsiDat);
		if (found == SSP_FALSE)
		{
			sprintf(sTmp, "Error read file: %s - IMSI-DAT-MBE-PATH", ini_file);
			Display_Message(-1, "", sTmp);
			exit(1);
		}
		get_profile_string(ini_file, "GENERIC", "IMSI-DAT-ENS-LOC-PATH", &found, acFileImsiDat_E_Loc);
		if (found == SSP_FALSE)
		{
			sprintf(sTmp, "Error read file: %s - IMSI-DAT-ENS-LOC-PATH", ini_file);
			Display_Message(-1, "", sTmp);
			exit(1);
		}
		get_profile_string(ini_file, "GENERIC", "IMSI-DAT-ENS-REM-PATH", &found, acFileImsiDat_E_Rem);
		if (found == SSP_FALSE)
		{
			sprintf(sTmp, "Error read file: %s - IMSI-DAT-ENS-REM-PATH", ini_file);
			Display_Message(-1, "", sTmp);
			exit(1);
		}
	}

// commentato 10-01-2017
/*	get_profile_string(ini_file, "GENERIC", "IMSI-LTE-MBE-PATH", &found, acFileImsiLte);
	if (found == SSP_FALSE)
	{
		sprintf(sTmp, "Error read file: %s - IMSI-LTE-MBE-PATH", ini_file);
		Display_Message(-1, "", sTmp);
		exit(1);
	}
*/

	get_profile_string(ini_file, "GENERIC", "CAR-TABLE-OSS", &found, ac_car_table);
	if (found == SSP_FALSE)
	{
		sprintf(sTmp, "Error read file: %s - CAR-TABLE-OSS", ini_file);
		Display_Message(-1, "", sTmp);
		exit(1);
	}

	get_profile_string(ini_file, "GENERIC", "APPLYPS", &found, acFileApply_PS);
	if (found == SSP_FALSE)
	{
		sprintf(sTmp, "Error read file: %s - APPLYPS", ini_file);
		Display_Message(-1, "", sTmp);
		exit(1);
	}
	get_profile_string(ini_file, "GENERIC", "APPLYST", &found, acFileApply_ST);
	if (found == SSP_FALSE)
	{
		sprintf(sTmp, "Error read file: %s - APPLYST", ini_file);
		Display_Message(-1, "", sTmp);
		exit(1);
	}
	get_profile_string(ini_file, "GTT", "NETWORK-NODES", &found, acFileImpianti);
	if (found == SSP_FALSE)
	{
		sprintf(sTmp, "Error read file: %s - NETWORK-NODES", ini_file);
		Display_Message(-1, "", sTmp);
		exit(1);
	}
	get_profile_string(ini_file, "GTT", "MGT", &found, acFileMGT);
	if (found == SSP_FALSE)
	{
		sprintf(sTmp, "Error read file: %s - MGT", ini_file);
		Display_Message(-1, "", sTmp);
		exit(1);
	}

	get_profile_string(ini_file, "GTT", "REM-NETWORK-NODES", &found, acFileImpianti_Rem);
	if (found == SSP_FALSE)
	{
		sprintf(sTmp, "Error read file: %s - REM-NETWORK-NODES", ini_file);
		Display_Message(-1, "", sTmp);
		exit(1);
	}
	get_profile_string(ini_file, "GTT", "REM-MGT", &found, acFileMGT_Rem);
	if (found == SSP_FALSE)
	{
		sprintf(sTmp, "Error read file: %s - REM-MGT", ini_file);
		Display_Message(-1, "", sTmp);
		exit(1);
	}

	s_mgt_by_range = 0;
	get_profile_string(ini_file, "GTT", "MGT-BY-RANGE", &found, ac_wrk_str);
	if (found == SSP_TRUE) s_mgt_by_range = (short)atoi(ac_wrk_str);


	// ==========================================================================================
	// LOG
	// ==========================================================================================
	get_profile_string(ini_file, "LOG", "LOG-PATH", &found, ac_path_log_file);
	if ((found == SSP_FALSE) || (strlen(ac_path_log_file) == 0))
	{
		sprintf(sTmp, "Error read file: %s - LOG-PATH", ini_file);
		Display_Message(-1, "", sTmp);
		exit(1);
	}

	i_trace_level = 9;
	get_profile_string(ini_file, "WEB", "LOG-LEVEL", &found, ac_wrk_str);
	if (found == SSP_TRUE)
		i_trace_level = (short)atoi(ac_wrk_str);
	else
	{
		get_profile_string(ini_file, "LOG", "LOG-LEVEL", &found, ac_wrk_str);
			if (found == SSP_TRUE) i_trace_level = (short)atoi(ac_wrk_str);
	}

	i_num_days_of_log = 2;
	get_profile_string(ini_file, "WEB", "LOG-DAYS", &found, ac_wrk_str);
	if (found == SSP_TRUE)
		i_num_days_of_log = atoi(ac_wrk_str);
	else
	{
		get_profile_string(ini_file, "LOG", "LOG-DAYS", &found, ac_wrk_str);
		if (found == SSP_TRUE) i_num_days_of_log = atoi(ac_wrk_str);
	}

	i_log_option = 15;
	get_profile_string(ini_file, "WEB", "LOG-OPTIONS", &found, ac_wrk_str);
	if (found == SSP_TRUE)
		i_log_option = (short)atoi(ac_wrk_str);
	else
	{
		get_profile_string(ini_file, "LOG", "LOG-OPTIONS", &found, ac_wrk_str);
		if (found == SSP_TRUE) i_log_option = (short)atoi(ac_wrk_str);
	}
	get_profile_string(ini_file, "WEB", "LOG-PREFIX", &found, ac_log_prefix);
	if (found == SSP_FALSE)
		strcpy(ac_log_prefix, "WEB");

	get_profile_string(ini_file, "WEB", "HEX-DEFAULT-USER-TYPES", &found, ac_hexdefuser);
	if ((found == SSP_FALSE) || (strlen(ac_hexdefuser) == 0))
		strcpy(ac_hexdefuser, "FFFFFFFF");


	return;       
}
//*******************************************************************************
//converte la stringa gg/mm/aaaa hh:mm:ss in time_t
//*******************************************************************************
time_t String2TS_time_t( char *strdata )
{
    char 	ac_YY[5];
    char 	ac_MM[3];
    char 	ac_DD[3];
    char 	ac_hh[3];
    char 	ac_mm[3];
    char 	ac_ss[3];
	struct  tm  timeStruct;


	memset(ac_DD, 0, sizeof(ac_DD));
	memset(ac_MM, 0, sizeof(ac_MM));
	memset(ac_YY, 0, sizeof(ac_YY));
	memset(ac_hh, 0, sizeof(ac_hh));
	memset(ac_mm, 0, sizeof(ac_mm));
	memset(ac_ss, 0, sizeof(ac_ss));

	memcpy(ac_DD, strdata,2);
	memcpy(ac_MM, strdata+3,2);
	memcpy(ac_YY, strdata+6,4);
	memcpy(ac_hh, strdata+11,2);
	memcpy(ac_mm, strdata+14,2);
	memcpy(ac_ss, strdata+17,2);

	timeStruct.tm_mday	= atoi( ac_DD );
	timeStruct.tm_mon	= (atoi( ac_MM )-1);
	timeStruct.tm_year	= (atoi( ac_YY )- 1900);
	timeStruct.tm_hour	= atoi( ac_hh );
	timeStruct.tm_min	= atoi( ac_mm );
	timeStruct.tm_sec	= atoi( ac_ss );
	timeStruct.tm_isdst = 0;

    return ( mktime( &timeStruct ) );
}  // ConvTS2sec
short get_process_name( char* ac_procname )
{
    short rc = 0;

    short i_proch[20];
    short i_maxlen;

    i_maxlen = SHORT_BUF;
    rc = PROCESSHANDLE_GETMINE_ (i_proch);
    rc = PROCESSHANDLE_DECOMPOSE_ ( i_proch,
                                    ,,,,,,
                                    ac_procname,
                                    i_maxlen,
                                    &i_maxlen,);

    ac_procname[i_maxlen] = '\0';

    return rc;
} // end of get_process_name
//*********************************************************************************
long long HHMM2TS(char *hh_mm) 
{
	short jtime[8];
	char sTmp[50];
	long long jts;

	jts = CONVERTTIMESTAMP( JULIANTIMESTAMP(0), 0 );
	INTERPRETTIMESTAMP(jts, jtime);

	memset( sTmp, 0, 5 );	//HH
	memcpy( sTmp, hh_mm, 2 );
	jtime[3] = (short) atoi(sTmp);

	memset( sTmp, 0, 5 );	//MM
	memcpy( sTmp, hh_mm+3, 2 );
	jtime[4] = (short) atoi(sTmp);

	jtime[5] = 0;
	jtime[6] = 0;
	jtime[7] = 0;

	return( COMPUTETIMESTAMP(jtime) );
}
/******************************************************************************
** Remove trailing blank in mezzo in a null terminated string
******************************************************************************/
void Trim_inMezzo( char *str1, char *sret)
{
    int nn,i=0;

    for ( nn = 0; nn < (int)strlen( str1); nn++ )
    {
        if ( str1[nn] != ' ' )
		{
            sret[i] = str1[nn];
			i++;
		}
    }


	return;
}
/******************************************************************************/
/* GetStringNT   **************************************************************/
/******************************************************************************/
char *GetStringNT (char *stringa, int max_length)
{
    int  i;
	char *output;

	/* alloca e svuota */
	output = calloc( 1, max_length + 1 );

	/* copia i caratteri desiderati */
	memcpy(output, stringa, max_length);
	/* NULL Termina la stringa */
	output[max_length] = 0;

	/* toglie i blank in coda */
	for (i = max_length-1; i>=0; i--)
	{
		if (output[i] == ' ')
		{
			output[i] = 0;
		}
		else
			break;
	}

    return output;
}

/******************************************************************************/
/* InitSLOG	      *************************************************************/
/******************************************************************************/
short InitSLOG(void)
{
	char   	*tmp;
	char   	dummy[256];
	int		found  = 0;
	char	sTmp[100];
	short  	ret;
	short  	SubSysNum = 760;


	get_profile_string(ini_file, INI_EMS, "EMS-SUBSYSTEM", &found, sTmp);
	if ((found == SSP_TRUE) && (strlen(sTmp) > 0))
		SubSysNum =  (short)atoi(sTmp);

	/*******************
    ** EMS
    ********************/
	if ( sspevt_init("WOB", "TIM", SubSysNum, "A01") )
	{
		Display_Message(1, "", "Error on Event Initialize" );
		return(-1);
	}

	/*******************
	** Parte fissa della Struttura per LOG Spooler
	********************/
	log_spooler.SubsystemNumber = SubSysNum;
	log_spooler.Version = 1;

	if( (tmp = cgi_session_var("USER")) != NULL)
		strcpy(log_spooler.RemoteUser, tmp);

	if( (tmp = getenv("REMOTE_ADDR")) != NULL)
		strcpy(log_spooler.Ip, tmp);
	else
		strcpy(log_spooler.Ip, "?");

	if( (tmp = getenv("REMOTE_PORT")) != NULL)
		strcpy(log_spooler.Porta, tmp);
	else
		strcpy(log_spooler.Porta, "?");

	//	inserito nelle funzioni
	//strcpy(log_spooler.NomeDB, "Ecc_db");	// max 20 char

	/*******************
	** Test fruibilità LOG Spooler
	********************/
	strcpy(log_spooler.TipoRichiesta, "CHECK");       // LIST, VIEW, NEW, UPD, DEL, CHECK
	strcpy(log_spooler.ParametriRichiesta, " ");
	log_spooler.EsitoRichiesta = SLOG_OK;

	ret = Log2Spooler(&log_spooler, EVT_ON_ERROR);

	if ( ret != 0)
	{
		if ( ret == -1)
		{
			sprintf(dummy, "This service (ID=%d) <BR><BR> is not configured in LOG Manager DB", SubSysNum);
			Display_Message(1, "", dummy );
		}
		else if ( ret == -2)
		{
			sprintf(dummy, "Missing Parameters for LOG Manager Address");
			Display_Message(1, "", dummy );
			ret = -1;
		}
		else
		{
			sprintf(dummy, "Error %d contacting LOG Manager", ret);
			Display_Message(1, "", dummy );
			ret = -1;
		}
	}

	return(ret);
}
