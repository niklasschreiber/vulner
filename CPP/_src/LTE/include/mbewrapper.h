/*----------------------------------------------------------------------------
*   PROJECT : MBE Wrapper
*-----------------------------------------------------------------------------
*
*   File Name   : mbewrapper.h
*   Last change : 02-03-2011
*
*------------------------------------------------------------------------------
*   Description
*   -----------
*
*
*
*----------------------------------------------------------------------------*/
#ifndef _MBEWRAPPER
#define _MBEWRAPPER

#define MBE_NO_WAITED  0
#define MBE_WAITED     1	

short MbeFileOpenWrapper( char *ac_file_name,short *i_fd, char blocking);
short MbeFileReadWrapper( short i_fnum,char *ac_rec,short i_reclen );
short MbeFileReadLWrapper( short i_fnum,char *ac_rec,short i_reclen );
short MbeFileWriteWrapper( short i_fnum,char *ac_rec,short i_reclen );
short MbeFileWriteUUWrapper( short i_fnum,char *ac_rec,short i_reclen );
short MbeUnlockRecWrapper( short i_fnum );
short MbeLockRecWrapper( short i_fnum );

#endif
