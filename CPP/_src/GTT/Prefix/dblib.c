// ------------------------------------------------------
//
// Last Change: 16-01-2014
// ------------------------------------------------------
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <tal.h>
#include <usrlib.h>
#include <cextdecs.h>
#include "dblib.h"

static int dberr_Guardian = 0;

void DBOpen(char *filename, short *filenumber)
{
   struct LString FName;

   FName.len = (int)strlen(filename);
   memcpy(FName.text,filename,FName.len);

   if (FPDB_Open(FName, filenumber) != FPDB_SUCCESS)
      exit(1);
}

enum retvalues DBClose(short filenumber)
{
	if( ( dberr_Guardian = MBE_FILE_CLOSE_(filenumber) ) == 0)
		return FPDB_SUCCESS;

	return FPDB_UNRECOVERABLE;
}

enum retvalues DBInsert(short filenumber, void *buffer, short buffer_length)
{
	short written;
    long dd_status;
    short err_tmp;

    dd_status = MBE_WRITEX(	filenumber,
							(char *) buffer,
							buffer_length, &written);

    if( _status_eq(dd_status))
    {
    	if(written == buffer_length)
    		return FPDB_SUCCESS;
    }
    else
    {
         MBE_FILE_GETINFO_(filenumber, &err_tmp);
         dberr_Guardian = (int) err_tmp;

         switch(dberr_Guardian)
         {
         	 case 10:                        /*   Key alraedy present */
         		 return FPDB_RECOVERABLE;
         	 default:
         		 break;
         }
    }

    return FPDB_UNRECOVERABLE;
}

enum retvalues DBUpdateUnlock(short filenumber, void *buffer, short buffer_length)
{
   long dd_status;

   dd_status = MBE_WRITEUPDATEUNLOCKX( filenumber,
                                       (char *) buffer,
                                       buffer_length );

	if( _status_eq(dd_status))
	{
		return FPDB_SUCCESS;
	}               /* IF WRITE...  */
	else
	{
		short err_tmp;

		MBE_FILE_GETINFO_(filenumber, &err_tmp);
		dberr_Guardian = (int) err_tmp;
		MBE_UNLOCKREC(filenumber);

		return FPDB_UNRECOVERABLE;
	}               /* ELSE WRITE... */
}

enum retvalues DBUpdateKeepLock(short filenumber, void *buffer, short buffer_length)
{
	long dd_status;

	dd_status = MBE_WRITEUPDATEX (	filenumber,
									(char *) buffer,
									buffer_length);

	if( _status_eq(dd_status))
	{
		return FPDB_SUCCESS;
	}               /* IF WRITE...  */
	else
	{
		short err_tmp;

		MBE_FILE_GETINFO_(filenumber, &err_tmp);
		FPDB_setGErrorCode((int) err_tmp);
		return FPDB_UNRECOVERABLE;
	}               /* ELSE WRITE... */
}

enum retvalues DBUnlockRecord(short filenumber)
{
    long dd_status;

	dd_status = MBE_UNLOCKREC(filenumber);

	if( _status_eq(dd_status))
	{
		return FPDB_SUCCESS;
	}               /* IF WRITE...  */
	else
	{
		short err_tmp;

		MBE_FILE_GETINFO_(filenumber, &err_tmp);
		FPDB_setGErrorCode((int) err_tmp);

		return FPDB_UNRECOVERABLE;
	}               /* ELSE WRITE... */

}

enum retvalues DBUnlockFile(short filenumber)
{
   //return (FPDB_RemoveFileLocks(filenumber));
	return FPDB_UNRECOVERABLE;
}
