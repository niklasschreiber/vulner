//------------------------------------------------------------------------------
//   Project : GLR Hermes - Auxiliary Network Services
//------------------------------------------------------------------------------
//
//   File Name   : ctxl.c
//   Created     : 15-02-2012
//   Last Change : 28-02-2012
//
//------------------------------------------------------------------------------
//   Description
//   -----------
//
//------------------------------------------------------------------------------
#ifndef _CTX_H_
#define _CTX_H_

#include <p2system.p2apdfh>

short SaveCTX( char *buff,				
               long *ctx_tag,			
			   short i_buff_len );

short LoadCTX( long ctx_tag,
               char *buff,
			   short i_buff_len );

short CTXSignalTimeout( long ctx_tag,
                        short *i_tag,
                        long timeout,
                        P2_MTS_TAG_DEF mtsadd );

short CTXCancelTimeout( long ctx_tag, short i_tag );

short CTXReleaseContext(long ctx_tag);

short CTXExtendLifetimeOfContext( long ctx_tag,
                                  long timeout );

short CTXCheckContext(long ctx_tag);

void SetdiscardedTimeout(long timeout);

void SetlockTimeout(long timeout);

void SetprotectedClass(short pclass);

long GetdiscardedTimeout(void);

#endif
