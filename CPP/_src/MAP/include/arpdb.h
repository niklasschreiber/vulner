//------------------------------------------------------------------------------
//   PROJECT : Traffic Steering - v 1.00
//------------------------------------------------------------------------------
//
//   File Name   : arpdb.h
//   Created     : 02-05-2014
//   Last Change : 02-05-2014
//
//------------------------------------------------------------------------------
//   Description
//   -----------
//
//------------------------------------------------------------------------------
#ifndef __ARPDB_H
#define __ARPDB_H

#include "db.h"
#include "db_const.h"

// **************************************************************************************************
// ROAMING UNBLUNDING

enum { FOUND_REC,
       NOT_FOUND_REC } _rec_status;

#pragma fieldalign shared2 arp_el_struct
typedef struct arp_el_struct
{
    struct arp_el_struct    *next;
    short					i_arp_id;
    long					pc_map_proxy;
    short                  	i_status;
} ARP_EL;

#pragma fieldalign shared2 arp_list_struct
typedef struct arp_list_struct
{
    short       i_nrb_arp_defined;  // # of element in list
    ARP_EL      *p_first;       	// Pointer to the first element
    ARP_EL      *p_current;     	// Pointer to the current element
} ARP_LIST;

short Load_ARP_List( char *ac_path_arp_file,
					ARP_LIST *arp_list );

short Find_ARP( ARP_LIST *arp_list,
		   	   	short i_arp_id,
		   	   	long *L_pc_map_proxy );

void Unload_ARP_List( ARP_LIST *arp_List );

// **************************************************************************************************

#endif
