//----------------------------------------------------------------------------
//   PROJECT : MBEDB - WRAPPER
//-----------------------------------------------------------------------------
//
//   File Name   : mbewrapper.c
//   Last Change : 19-02-2015
//
//------------------------------------------------------------------------------
//   Description
//   -----------
//------------------------------------------------------------------------------
//   Functions
//   ------------------
//------------------------------------------------------------------------------
//
//
//----------------------------------------------------------------------------

//---------------------< Include files >-------------------------------------
#pragma nolist
#include <stdio.h>
#include <stdlib.h>
#include <stddef.h>
#include <fcntl.h>
#include <memory.h>
#include <string.h>
#include <strings.h>
#include <tal.h>
#include <usrlib.h>
#include <ssplog.h>
#include <mbedb.h>
#include "mbewrapper.h"
#pragma list

static char MBEblocking;

// ----------------------------------------------------------------------------
// Name:  MbeFileOpen_nw
//
// Description:  Opens MBE files, return fnum is ok(err = 0)
// ----------------------------------------------------------------------------
short MbeFileOpenWrapper( char *ac_file_name,short *i_fd, char blocking)
{
    short   err = 0;

	MBEblocking = blocking;

	if(MBEblocking)
	{
	    err = MBE_FILE_OPEN_ ( ac_file_name,(short) strlen (ac_file_name),i_fd );

	    if( err )
		{
			log_( LOG_WARNING, "%s: Err.[%d] - MBE_FILE_OPEN_",
					__FUNCTION__,
					err );
		}
	}
	else
	{
		err = MbeFileOpen_nw(ac_file_name, i_fd);
	}

	return( err );
}  // MbeFileOpen_nw

// ----------------------------------------------------------------------------
// Name:  MbeFileRead_nw
//
// Description:  Perform a MBE_READX, return 0 is ok, !0 if error
// ----------------------------------------------------------------------------
short MbeFileReadWrapper( short i_fnum,char *ac_rec,short i_reclen )
{
    short   err = 0;

	if(MBEblocking)
	{
	    err = MBE_READX( i_fnum,ac_rec,i_reclen,&i_reclen);

	    if ( err &&
			 err != 1 )
		{
			log_(LOG_ERROR,"%s: Err.[%d] in MBE_READX",
					__FUNCTION__,
					err );
		}
	}
	else
	{
		err = MbeFileRead_nw(i_fnum,ac_rec,i_reclen);
	}

    return( err );
}  // MbeFileRead_nw

// ----------------------------------------------------------------------------
// Name:  MbeFileReadL_nw
//
// Description:  Perform a MBE_READLOCKX, return 0 is ok, !0 if error
// ----------------------------------------------------------------------------
short MbeFileReadLWrapper( short i_fnum,char *ac_rec,short i_reclen )
{
    short   err = 0;

	if(MBEblocking)
	{
	    err = MBE_READLOCKX( i_fnum,ac_rec,i_reclen,&i_reclen);

	    if ( err &&
			 err != 1 )
		{
			log_(LOG_ERROR,"%s: Err.[%d] in MBE_READX",
					__FUNCTION__,
					err );
		}
	}
	else
	{
		err = MbeFileReadL_nw(i_fnum,ac_rec,i_reclen);
	}

    return( err );
}  // MbeFileReadLWrapper

// ----------------------------------------------------------------------------
// Name:  MbeFileWrite_nw
//
// Description:  Perform a MBE_WRITEX, return 0 is ok, !0 if error
// ----------------------------------------------------------------------------
short MbeFileWriteWrapper( short i_fnum,char *ac_rec,short i_reclen )
{
    short   err = 0;

	if(MBEblocking)
	{
	    err = MBE_WRITEX( i_fnum,ac_rec,i_reclen);

	    if ( err )
		{
			log_(LOG_ERROR,"%s: Err.[%d] in MBE_WRITEX",
					__FUNCTION__,
					err );
		}
	}
	else
	{
		err = MbeFileWrite_nw(i_fnum,ac_rec,i_reclen);
	}

    return( err );
}  // MbeFileWrite_nw

// ----------------------------------------------------------------------------
// Name:  MbeFileWriteUU_nw
//
// Description:  Perform a MBE_WRITEUPDATEUNLOCKX, return 0 is ok, !0 if error
// ----------------------------------------------------------------------------
short MbeFileWriteUUWrapper( short i_fnum,char *ac_rec,short i_reclen )
{
    short   err = 0;

	if(MBEblocking)
	{
	    err = MBE_WRITEUPDATEUNLOCKX( i_fnum,ac_rec,i_reclen);

	    if ( err )
		{
			log_(LOG_ERROR,"%s: Err.[%d] in MBE_WRITEUPDATEUNLOCKX",
					__FUNCTION__,
					err );
		}
	}
	else
	{
		err = MbeFileWriteUU_nw(i_fnum,ac_rec,i_reclen);
	}

    return( err );
}  // MbeFileWriteUUWrapper

// ----------------------------------------------------------------------------
// Name:  MbeUnlockRec_nw
//
// Description:  Perform a MBE_UNLOCKREC, return 0 is ok, !0 if error
// ----------------------------------------------------------------------------
short MbeUnlockRecWrapper( short i_fnum )
{
    short   err = 0;

	if(MBEblocking)
	{
	    err = MBE_UNLOCKREC( i_fnum);

	    if ( err )
	    {
	    	log_(LOG_ERROR,"%s: Err.[%d] in MBE_UNLOCKREC",
	    			__FUNCTION__,
	    			err );
	    }
	}
	else
	{
		err = MbeUnlockRec_nw(i_fnum);
	}

    return( err );
}  // MbeUnlockRecWrapper

// ----------------------------------------------------------------------------
// Name:  MbeLockRec_nw
//
// Description:  Perform a MBE_LOCKREC, return 0 is ok, !0 if error
// ----------------------------------------------------------------------------
short MbeLockRecWrapper( short i_fnum )
{
    short   err = 0;

	if(MBEblocking)
	{
	    err = MBE_LOCKREC( i_fnum);

	    if ( err )
		{
			log_(LOG_ERROR,"%s: Err.[%d] in MBE_LOCKREC",
					__FUNCTION__,
					err );
		}
	}
	else
	{
		err = MbeLockRec_nw(i_fnum);
	}

    return( err );
}  // MbeLockRecWrapper

