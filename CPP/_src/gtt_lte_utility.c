#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <cextdecs.h (INTERPRETTIMESTAMP)>

#include "utility.h"

/*-----------------------------------------------------------------------------
* get_profile_string - Lettura valore sezione->entry dal file specificato
*
* Input:    filenname       Nome del file in cui ricercare il valore
*           section_name    Nome della sezione da ricercare
*           entry_name      Nome della entry da ricercare
*
* Output:   found           1 = entry trovata; 0 = entry non trovata
*           value_read      Valore letto dal file
*
* Ritorn:   SSP_FALSE           Ok
*           SSP_TRUE            Errore
*
*----------------------------------------------------------------------------*/
int get_profile_string( char *filename, char *section_name, char *entry_name, int  *found, char *value_read )
{
    int     rc = 0;
    int     entry_found = SSP_FALSE;
    int     correct_section = SSP_FALSE;
    FILE    *fdes;
    char    section_name_with_brackets[SSP_BUFFER_LEN];
    char    entry_name_with_equal[SSP_BUFFER_LEN];
    char    line[SSP_BUFFER_LEN];
 
    /*
    ** Inizializzazione
    */
    rc = 0;
    *found = SSP_FALSE;

	/*
    ** Apertura file
    */
    fdes = fopen( filename, "r" );
    
	if ( fdes == NULL )
        rc = 1;
    else
    {
        /*
        ** Preparazione stringhe da ricercare:
        ** "[section]"
        ** "entry="
        */
        strcpy( section_name_with_brackets, "[" );
        strcat( section_name_with_brackets, section_name );
        strcat( section_name_with_brackets, "]" );
 
        strcpy( entry_name_with_equal, entry_name );
        strcat( entry_name_with_equal, "=" );
 
        /*
        ** Ricerca Entry.
        */
        while( fgets( line, SSP_BUFFER_LEN-1, fdes ) && !entry_found )
        {
            entry_found = SSP_FALSE;
            /*
            ** Individuazione Sezione corretta
            */
            if ( line[0] == '[' )
            {
                if ( !strncmp( line, section_name_with_brackets, strlen(section_name_with_brackets) ) )
                {
                    correct_section = SSP_TRUE;
                }
                else
                {
                    correct_section = SSP_FALSE;
                }
            }
 
            /*
            ** Entry_name deve iniziale all'inizio della linea.
            */
 
            if ( correct_section )
            {
                entry_found = !strncmp( line, entry_name_with_equal, strlen( entry_name_with_equal ) );
 
                if ( entry_found )
                {
                    char *pos_start;
                    char *pos_return;
 
                    pos_start = strchr(line, '=') + 1;
                    /*
                    ** se '\n' finale sostituzione con '\0'
                    */
                    pos_return = strchr( pos_start, '\n' );
 
                    if ( pos_return )
                        *pos_return = '\0';
 
                    if ( value_read )
                        strcpy( value_read, pos_start );
                }
                else
                {
                    entry_found = SSP_FALSE;
                }
            }
 
            /**************************************************************/
        }
 
        if ( found )
            *found = entry_found ? SSP_TRUE : SSP_FALSE;
    }
 
    /*
    ** Chiusura file.
    */
    if ( rc == 0 )
    {
        if( fclose( fdes ) )
            rc = 2;
    }
 
    return( rc );
 
} // get_profile_string


/******************************************************************************/
/* Rovescia   *****************************************************************/
/******************************************************************************/
void Rovescia(char *acInput, char *acOutput)
{
	short i;
	short lung = (short)strlen(acInput);

	for (i=0; i<lung; i++)
	{
		acOutput[i] = acInput[(lung-1)-i];
	}

	acOutput[lung] = 0;

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
/* timestamp2string  **********************************************************/
/******************************************************************************/
char *timestamp2string(char stringa[], long long jts)
{
	short jtime[8];

	if(jts == 0) return "";

	INTERPRETTIMESTAMP(jts, jtime);
	sprintf( stringa,"%04u/%02u/%02u %02u:%02u:%02u",
				jtime[0],
				jtime[1],
				jtime[2],
				jtime[3],
				jtime[4],
				jtime[5]);

	return stringa;
}
