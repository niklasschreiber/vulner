//------------------------------------------------------------------------------
//   PROJECT : Traffic Steering - v 1.00
//------------------------------------------------------------------------------
//
//   File Name   : arpdb.c
//   Created     : 02-05-2014
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
#include <ctype.h>
#include <ssplog.h>
#include <mbedb.h>
#include "arpdb.h"
#include "db.h"
#pragma list

// ********************************************************
static short OpenARPdb( char *ac_path_db );

static void CloseARPdb( char *ac_path_db );

static short SetPos_A_Prim( void );

static short GetARPRec( ROAMUN_arp_profile *arp_rec );

// ********************************************************
static short i_fd_db_arp_rec; // File Handle
// ********************************************************
//
// Open DBase
//
// ********************************************************
static short OpenARPdb( char *ac_path_db )
{
    short i_ret;

    if( i_ret = MbeFileOpen_nw( ac_path_db,
    							&i_fd_db_arp_rec ) )
    {
        log_(LOG_ERROR,"%s - ARP DBase[%s] has not been opened - Err.[%d]",
        	__FUNCTION__,
        	ac_path_db,
			i_ret);
    }
    else
    {
        log_(LOG_DEBUG,"%s - ARP DBase[%s] has been opened",
        	__FUNCTION__,
        	ac_path_db);
    }

    return (i_ret);
}

// ********************************************************
//
// close ARP DBase
//
// ********************************************************
static void CloseARPdb( char *ac_path_db )
{
    // close DBase
    MbeFileClose(i_fd_db_arp_rec);

    log_(LOG_DEBUG,"%s - ARP DBase[%s] closed",
    	__FUNCTION__,
    	ac_path_db);
}

// ********************************************************
//
// Set position with approximate key
//
// ********************************************************
static short SetPos_A_Prim( void )
{
	return( MbeFileSeek( i_fd_db_arp_rec,
						 "\0\0",
			 	 	 	 sizeof(short),
						 MBE_MODE_APPROXIMATE,
						 0) );
}

// ********************************************************
//
// Get ARP record
//
// ********************************************************
static short GetARPRec( ROAMUN_arp_profile *arp_rec )
{
    short    i_ret;
    short    i_res;

    i_res = MbeFileRead_nw( i_fd_db_arp_rec,
                            (char *)arp_rec,
                            sizeof(ROAMUN_arp_profile) );

    switch( i_res )
    {
        case NOT_FOUND_REC:
        {
            i_ret = NOT_FOUND_REC;

            break;
        }

        case FOUND_REC:
        {
            i_ret = FOUND_REC; // OK !

            break;
        }

        default:
        {
            i_ret = i_res;

            break;
        }
    }

    return(i_ret);
}

// *************************************************************************************
//
// 1 - found
// 0 - not found
//
short Find_ARP( ARP_LIST *arp_list,
		   	   	short i_id,
		   	   	long *L_pc_map_proxy )
{
    short   i_ret = 0;
    ARP_EL	*dummy = arp_list->p_first;

    *L_pc_map_proxy = -1L;

    while ( dummy )
    {
        if ( i_id == dummy->i_arp_id )
        {
            i_ret = 1;
            *L_pc_map_proxy = dummy->pc_map_proxy;

            break;
        }

        dummy = dummy->next;
    }

    return i_ret;
}

//
// Free memory
//
void Unload_ARP_List( ARP_LIST *arp_list )
{
    ARP_EL	*dummy = arp_list->p_first;

    if ( dummy != NULL )
    {
        do
        {
            dummy = arp_list->p_first->next;
            free( arp_list->p_first );
            arp_list->p_first = dummy;
        } while ( arp_list->p_first );
    }
}

//
// load ARP element list from ARP Dbase
//
// Return : 0 - ok
//          1 - ko
//
short Load_ARP_List( char *ac_path_arp_db,
                     ARP_LIST *arp_list )
{
    short				i_ret;
	short 				i_err;
	short				Stop;
    ARP_EL				*dummy;
    ROAMUN_arp_profile 	arp_rec;

    i_ret = 1;
    i_err = 0;
    Stop  = 0;

	//
	// Initialize values
	//
	arp_list->i_nrb_arp_defined = 0;
	arp_list->p_first      		= NULL;
	arp_list->p_current    		= NULL;

	if( strlen(ac_path_arp_db) > 0 )
	{
		//
		// Open ARP Dbase
		//
		if ( !(i_err = OpenARPdb( ac_path_arp_db )) )
		{
			// Set Key Approximate
			if ( !(i_err = SetPos_A_Prim()) )
			{
				//
				// Read the configuration into the configuration buffer
				//
				while( !Stop )
				{
					switch( i_err = GetARPRec( &arp_rec ) )
					{
						case FOUND_REC:
						{
							dummy = calloc(1, sizeof( ARP_EL ) );

							if ( dummy == NULL )
							{
								i_ret = 1;
								Stop  = 1;

								log_(LOG_ERROR,"%s - No memory free found -",__FUNCTION__); // No memory free found

								break;
							}
							else
							{
								dummy->next  		= NULL;
								dummy->i_arp_id 	= arp_rec.profile_id; // got from DBase
								dummy->pc_map_proxy = arp_rec.pc_map_proxy;
								dummy->i_status 	= 1; // Element has been validated

								if ( arp_list->p_first == NULL )
								{
									arp_list->p_first   		= dummy;
									arp_list->p_current     	= dummy;
									arp_list->i_nrb_arp_defined = 0;
								}
								else
								{
									arp_list->p_current->next = dummy;
									arp_list->p_current       = dummy;
								}

								arp_list->i_nrb_arp_defined += 1;
							}

							break;
						}

						case NOT_FOUND_REC:
						{
							Stop = 1;

							break;
						}

						default:
						{
							Stop = 1;

							break;
						}
					}
				}

				arp_list->p_current = NULL;
				CloseARPdb( ac_path_arp_db );

				if ( !arp_list->i_nrb_arp_defined )
				{
					log_(LOG_WARNING,"%s - ARP Db[%s] is empty",
						__FUNCTION__,
						ac_path_arp_db);

					i_ret = 0;
				}
				else
				{
					i_ret = 0;

					log_(LOG_DEBUG,"%s - Nbr. of ARP items loaded [%d] from ARP Db[%s]",
						__FUNCTION__,
						arp_list->i_nrb_arp_defined,
						ac_path_arp_db);
				}
			}
			else
			{
				log_(LOG_ERROR,"%s - Err.[%d] - Key positioning ARP Db[%s]",
					__FUNCTION__,
					i_err,
					ac_path_arp_db);

				i_ret = i_err;
			}
		}
		else
		{
			log_(LOG_ERROR,"%s - Err.[%d] - Opening ARP Db[%s]",
				__FUNCTION__,
				i_err,
				ac_path_arp_db);

			i_ret = i_err;
		}
    }
    else
    {
    	log_(LOG_ERROR,"%s - Opening ARP Db - Path name is null",
			__FUNCTION__);

		i_ret = 1;
    }

    return i_ret;
}
