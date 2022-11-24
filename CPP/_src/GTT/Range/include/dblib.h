#ifndef _DBLIBH_
#define _DBLIBH_

#include <dbmng.h>

extern void DBOpen(char *filename, short *filenumber);

extern enum retvalues DBClose(short filenumber);

extern enum retvalues DBInsert(short filenumber, void *buff, short bufflen);

extern enum retvalues DBUpdateUnlock(short filenumber, void *buff, short bufflen);

extern enum retvalues DBUpdateKeepLock(short filenumber, void *buff, short bufflen);

extern enum retvalues DBUnlockRecord(short filenumber);

extern enum retvalues DBUnlockFile(short filenumber);

#endif
