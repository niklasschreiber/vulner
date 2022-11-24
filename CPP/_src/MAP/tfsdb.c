//------------------------------------------------------------------------------
//   PROJECT : Traffic Steering - v 1.00
//------------------------------------------------------------------------------
//
//   File Name   : tfsdb.c
//   Created     : 14-12-2005
//   Last Change : 13-04-2015
//
//------------------------------------------------------------------------------
//   Description
//   -----------
//
//------------------------------------------------------------------------------
//   Functions
//   ------------------
//------------------------------------------------------------------------------

//---------------------< Defitions >-----------------------------------------
//---------------------< External Function Prototypes >----------------------
//---------------------< Internal Function Prototypes >----------------------
//---------------------< Include files >----------------------------------------
#pragma nolist
#include <stdio.h>
#include <stdlib.h>
#include <stddef.h>
#include <memory.h>
#include <string.h>
#include <strings.h>
#include <time.h>
#include <ctype.h>
#include <cextdecs.h (DELAY)>
#include <ssplog.h>
#include <sspfunc.h>
#include "tfsdb.h"
#pragma list

//
// 1 - found
// 0 - not found
//
short Find_Prefix( PREFIX_LIST *prefix_list,
		   	   	   char *ac_sccp_address )
{
    short       i_ret = 0;
    PREFIX_EL	*dummy = prefix_list->p_first;

    while ( dummy )
    {
        if ( !memcmp( ac_sccp_address,
                      dummy->ac_prefix,
                      (short)strlen(dummy->ac_prefix)) )
        {
            i_ret = 1;

            break;
        }

        dummy = dummy->next;
    }

    return i_ret;
}

//
// Free memory
//
void Unload_Prefix_List( PREFIX_LIST *prefix_list )
{
    PREFIX_EL	*dummy = prefix_list->p_first;

    if ( dummy != NULL )
    {
        do
        {
            dummy = prefix_list->p_first->next;
            free( prefix_list->p_first );
            prefix_list->p_first = dummy;
        } while ( prefix_list->p_first );
    }
}

//
// load prefix element list from file ascii
//
// Return : 0 - ok
//          1 - ko
//
short Load_Prefix_List( char *ac_path_prefix_file,
                     	PREFIX_LIST *prefix_list )
{
    short		i_ret;
	int 		i_nrerr;
    int			i_ready;
    int			i_cnt;
    char		ac_line[255];
    PREFIX_EL	*dummy;
	FILE		*pr_file = NULL;

    i_ret   = 1;
    i_ready = 0;
    i_nrerr = 0;

    //
    // Initialize values
    //
    prefix_list->i_nrb_prefix_defined  = 0;
    prefix_list->p_first      		   = NULL;
    prefix_list->p_current    		   = NULL;

	//
    // Open services file
    //
    while ( pr_file == NULL && i_nrerr < 2 )
    {
        pr_file = fopen( ac_path_prefix_file, "r" );

        if ( pr_file == NULL )
        {
            //
            // Err. while opening prefix list file
            //
            DELAY(200); // 2"
            i_nrerr++;
        }
		else
			i_ret = 0;
    }

    if ( pr_file )
    {
		//
		// Read the configuration into the configuration buffer
		//
		while( !i_ready )
		{
			memset(ac_line,0x00, sizeof(ac_line));

			if ( fgets( ac_line,
						sizeof(ac_line),
						pr_file ) != NULL )
			{
				//
				//  strip all comments, carriage returns and new lines
				if ( strchr( ac_line, '#' ) != NULL )
					*strchr( ac_line, '#' ) = 0;
				if ( strchr( ac_line, '\r' ) != NULL )
					*strchr( ac_line, '\r' ) = 0;
				if ( strchr( ac_line, '\n' ) != NULL )
					*strchr( ac_line, '\n' ) = 0;

				//
				//  Strip all trailing spaces
				//
				for ( i_cnt = (int)strlen( ac_line ); ((i_cnt > 0) && isspace(ac_line[i_cnt - 1])); i_cnt--)
					ac_line[i_cnt - 1] = 0;

				//
				//  Check if the line was empty, just return  if so
				//
				if ( ac_line[0] != 0 )
				{
					dummy = calloc(1, sizeof( PREFIX_EL ) );

					if ( dummy == NULL )
					{
						i_ret = 1;

						log_(LOG_ERROR,"%s: No memory free found",__FUNCTION__); // No memory free found

						break;
					}
					else
					{
						dummy->next  = NULL;
						strncpy( dummy->ac_prefix,
								 ac_line,
								 sizeof(dummy->ac_prefix)-1 );

						dummy->i_status = 1;

						if ( prefix_list->p_first == NULL )
						{
							prefix_list->p_first       			= dummy;
							prefix_list->p_current     			= dummy;
							prefix_list->i_nrb_prefix_defined   = 0;
						}
						else
						{
							prefix_list->p_current->next = dummy;
							prefix_list->p_current       = dummy;
						}

						prefix_list->i_nrb_prefix_defined += 1;
					}
				}
			}
			else
				i_ready = 1;
		}

		prefix_list->p_current = NULL;
		fclose( pr_file );
	}

    if ( !prefix_list->i_nrb_prefix_defined )
    {
		log_( LOG_ERROR,"%s: Prefix file[%s] is empty",
				__FUNCTION__,
				ac_path_prefix_file);

        i_ret = 1;
    }
    else
    {
		log_(LOG_INFO,"%s: Nbr. of prefix elements loaded [%d] from prefix file[%s]",
				__FUNCTION__,
				prefix_list->i_nrb_prefix_defined,
				ac_path_prefix_file);

		i_ret = 0;

    }

    return i_ret;
}
