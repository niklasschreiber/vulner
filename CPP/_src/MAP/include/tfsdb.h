//------------------------------------------------------------------------------
//   PROJECT : Traffic Steering - v 1.00
//------------------------------------------------------------------------------
//
//   File Name   : tfsdb.h
//   Created     : 14-12-2005
//   Last Change : 13-06-2012
//
//------------------------------------------------------------------------------
//   Description
//   -----------
//
//------------------------------------------------------------------------------
#ifndef __TFSDB_H
#define __TFSDB_H

#define MAX_PREFIX_ADDRESS_LEN	32

#pragma fieldalign shared2 prefix_el_struct
typedef struct prefix_el_struct
{
    struct prefix_el_struct    *next;
    char						ac_prefix[MAX_PREFIX_ADDRESS_LEN + 1 ];
    short                   	i_status;
} PREFIX_EL;

#pragma fieldalign shared2 vlr_list_struct
typedef struct vlr_list_struct
{
    short           i_nrb_prefix_defined;   // # of element in list
    PREFIX_EL      *p_first;       			// Pointer to the first element
    PREFIX_EL      *p_current;     			// Pointer to the current element
} PREFIX_LIST;

// **************************************************************************************************

short Load_Prefix_List( char *ac_path_prefix_file,
						PREFIX_LIST *prefix_list );

short Find_Prefix( PREFIX_LIST *prefix_List,
				   char *ac_sccp_address );

void Unload_Prefix_List( PREFIX_LIST *prefix_List );

// **************************************************************************************************

#endif
