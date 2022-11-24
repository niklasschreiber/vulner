// ------------------------------------------------------------------------------
//   PROJECT : LTE-TFS v 01.00
// ------------------------------------------------------------------------------
//
//   File Name   : s_diam_tfs.c
//   Last Change : 28-03-2017
//
// ------------------------------------------------------------------------------
//   Description
//   -----------
//	23-10-2012: created
// ------------------------------------------------------------------------------
//   Functions
//   ------------------
//
// ------------------------------------------------------------------------------
#include <string.h>
#include <cssinc.cext>
#include <p2system.p2apdfh>
#include <erainc.ccpy>
#include <sspevt.h>
#include <ssplog.h>
#include "s6aevt.h"
#include "ctxl.h"

// External parameters
extern short	i_nbr_alert_msg;
extern short	i_interval_time;
/* ---------------------------------------------------------------------------------------------- */
/* Private attributes */
static long discardedTimeout = 90000;
static long lockTimeout		 = 200;
static short protectedClass	 = 0;

/* ---------------------------------------------------------------------------------------------- */
/* Private functions */
static long GetlockTimeout(void);
static short GetprotectedClass(void);
/* ---------------------------------------------------------------------------------------------- */
short SaveCTX( char *buff,			// i
               long *ctx_tag,		// o
			   short i_buff_len )	// i
{
    short ctx_err = P2_CTX_OK;
    short i_err = 0;
    long  ctx;

    ctx_err = CTX_CREATE(  &ctx,
                           GetdiscardedTimeout(),
                           GetprotectedClass() );

    if (ctx_err == P2_CTX_OK) 
    {
        ctx_err = CTX_PUT((char *)&ctx, buff, i_buff_len );

        if (ctx_err == P2_CTX_OK)
        {
            CTX_UNLOCK((char *)&ctx);

            *ctx_tag = ctx;

            log_(LOG_DEBUG2,"%s: CTX[0x%08X] created successfully",
            		__FUNCTION__,
            		ctx);
        }
        else
        {
            EVT_manage( EVTN_ERR_CTX_PUT_KO,
						0,
						i_interval_time,
						'A',
						"Putting CTX buffer - Err.[%d] - Releasing CTX [0x%08X]",
						ctx_err,
						ctx );

            log_(LOG_DEBUG2,"%s: Putting CTX buffer - Err.[%d] - Releasing CTX [0x%08X]",
            		__FUNCTION__,
            		ctx_err,
            		ctx);

            i_err = CTX_RELEASE ((void *) &ctx_tag);

            if ( i_err != P2_CTX_OK )
            {
                ctx_err = i_err;

                EVT_manage( EVTN_ERR_CTX_RELEASE_KO,
							0,
							i_interval_time,
							'A',
							"Releasing CTX [0x%08X] - Err.[%d]",
							ctx,
							ctx_err);

                log_(LOG_ERROR,"%s: Releasing CTX [0x%08X] - Err.[%d]",
                		__FUNCTION__,
                		ctx,
                		ctx_err);
            }
        }
    }
    else
    {
        EVT_manage( EVTN_ERR_CTX_CREATE_KO,
					0,
					i_interval_time,
					'A',
					"Creating CTX - Err.[%d]",
					ctx_err);

        log_(LOG_ERROR,"%s: Creating CTX - Err.[%d]",
        		__FUNCTION__,
        		ctx_err);
    }

    return (ctx_err);
}

/* ---------------------------------------------------------------------------------------------- */
short LoadCTX( long ctx_tag,		// i
               char *buff,			// o
			   short i_buff_len )	// i
{
    short ctx_err	= P2_CTX_OK;
    short i_err		= 0;

    ctx_err = CTX_LOCK((char *)&ctx_tag, GetlockTimeout());

    if (ctx_err == P2_CTX_OK)
    {
        ctx_err = CTX_GET((char *)&ctx_tag, buff, i_buff_len);

        if (ctx_err == P2_CTX_OK)
        {
            CTX_UNLOCK((char *)&ctx_tag);

            log_(LOG_DEBUG2,"%s: Getting buffer with CTX[0x%08X] successfully",
            		__FUNCTION__,
            		ctx_tag);
        }
        else
        {
        	if(ctx_err != 7)
        	{
				EVT_manage( EVTN_ERR_CTX_GET_KO,
							0,
							i_interval_time,
							'A',
							"Getting buffer with CTX[0x%08X] - Err.[%d] - Releasing",
							ctx_tag,
							ctx_err );
        	}

        	log_(LOG_DEBUG2,"%s: Getting buffer with CTX[0x%08X] - Err.[%d] - Releasing",
						__FUNCTION__,
						ctx_tag,
						ctx_err );

            i_err = CTX_RELEASE ((void *) &ctx_tag);

            if ( i_err != P2_CTX_OK )
            {
                CTX_UNLOCK((char *)&ctx_tag);

                if(i_err != 7)
                {
					EVT_manage( EVTN_ERR_CTX_RELEASE_KO,
								0,
								i_interval_time,
								'A',
								"Releasing CTX [0x%08X] - Err.[%d]",
								ctx_tag,
								i_err);

					log_(LOG_ERROR,"%s: Releasing CTX [0x%08X] - Err.[%d]",
							__FUNCTION__,
							ctx_tag,
							i_err);
                }
                else
                {
                	log_(LOG_WARNING,"%s: Releasing CTX [0x%08X] - Err.[%d]",
							__FUNCTION__,
							ctx_tag,
							i_err);
                }

                ctx_err = i_err;
            }
        }
    }
    else
    {
    	if(ctx_err !=7)
    	{
			EVT_manage( EVTN_ERR_CTX_LOCK_KO,
						0,
						i_interval_time,
						'A',
						"Locking CTX [0x%08X] - Err.[%d]",
						ctx_tag,
						ctx_err );

			log_(LOG_ERROR,"%s: Locking CTX[0x%08X] - Err.[%d]",
					__FUNCTION__,
					ctx_tag,
					ctx_err);
    	}
    	else
    	{
    		log_(LOG_WARNING,"%s: Locking CTX[0x%08X] - Err.[%d]",
					__FUNCTION__,
					ctx_tag,
					ctx_err);
    	}
    }

    return(ctx_err);
}

/* --------------------------------------------------------------------------------------------- */
short CTXSignalTimeout( long ctx_tag,			// i
                        short *i_tag,			// o
                        long TX_timeout,		// i
                        P2_MTS_TAG_DEF mtsadd )	// i
{
    short ctx_err = P2_CTX_OK;
    short sadd;
	
    memcpy(&sadd, &mtsadd, sizeof(short));

    ctx_err = CTX_LOCK((char *)&ctx_tag, GetlockTimeout());

    if (ctx_err == P2_CTX_OK)
    {
        ctx_err = CTX_SIGNALTIMEOUT( (void *) &ctx_tag,
                                     TX_timeout,
                                     ,			// param1
                                     ,			// param2
                                     i_tag,		// timeout tag
                                     sadd );	// mts address

		if (ctx_err == P2_CTX_OK)
            log_(LOG_DEBUG2,"%s: Creating CTX [0x%08X] Signaltimeout successfully - Timeout Tag[0x%08X]",
            		__FUNCTION__,
            		ctx_tag,
            		*i_tag);
        else
        {
            EVT_manage( EVTN_ERR_CTX_SIGNALTIMEOUT_KO,
						0,
						i_interval_time,
						'A',
						"Creating CTX Signaltimeout [0x%08X] - Err.[%d]",
						ctx_tag,
						ctx_err );

            log_(LOG_ERROR,"%s: Creating CTX Signaltimeout [0x%08X] - Err.[%d]",
            		__FUNCTION__,
            		ctx_tag,
            		ctx_err);
        }

        CTX_UNLOCK((char *)&ctx_tag);
    }
    else
    {
        EVT_manage( EVTN_ERR_CTX_LOCK_KO,
					0,
					i_interval_time,
					'A',
					"Locking CTX [0x%08X] - Err.[%d]",
					ctx_tag,
					ctx_err );

        log_(LOG_ERROR,"%s: Locking CTX[0x%08X] - Err.[%d]",
        		__FUNCTION__,
        		ctx_tag,
        		ctx_err);
    }

    return (ctx_err);
}

/* ---------------------------------------------------------------------------------------------- */
short CTXCancelTimeout( long ctx_tag,   // i
						short i_tag )	// i
{
    short ctx_err = P2_CTX_OK;

	ctx_err = CTX_LOCK((char *)&ctx_tag, GetlockTimeout());

    if (ctx_err == P2_CTX_OK)
    {
        ctx_err = CTX_CANCELTIMEOUT((void *)  &ctx_tag, i_tag);

        if (ctx_err != P2_CTX_OK)
        {
            EVT_manage( EVTN_ERR_CTX_CANCELTIMEOUT_KO,
						0,
						i_interval_time,
						'A',
						"Canceltimeout with CTX [0x%08X] - Err.[%d]",
						ctx_tag,
						ctx_err);

            log_(LOG_WARNING,"%s: Canceltimeout with CTX [0x%08X] - Err.[%d]",
            		__FUNCTION__,
            		ctx_tag,
                    ctx_err);
        }
        else
        	log_(LOG_DEBUG2,"%s: Canceltimeout successfully with CTX [0x%08X]",
        			__FUNCTION__,
        			ctx_tag);

        CTX_UNLOCK((char *)&ctx_tag);
    }
    else
    {
        EVT_manage( EVTN_ERR_CTX_LOCK_KO,
					0,
					i_interval_time,
					'A',
					"Locking CTX [0x%08X] - Err.[%d]",
					ctx_tag,
					ctx_err );

        log_(LOG_ERROR,"%s: Locking CTX[0x%08X] - Err.[%d]",
        		__FUNCTION__,
        		ctx_tag,
        		ctx_err);
    }

    return (ctx_err);
}

/* -------------------------------------------------------------------------------------------------- */
short CTXReleaseContext( long ctx_tag ) // i
{
    short    ctx_err;

    ctx_err = CTX_LOCK ((void *) &ctx_tag, -1);

    if (ctx_err != P2_CTX_OK )
    {
        EVT_manage( EVTN_ERR_CTX_LOCK_KO,
					0,
					i_interval_time,
					'A',
					"Locking CTX [0x%08X] - Err.[%d]",
					ctx_tag,
					ctx_err );

        log_(LOG_DEBUG2,"%s: Locking CTX[0x%08X] - Err.[%d]",
        		__FUNCTION__,
        		ctx_tag,
        		ctx_err);
    }
    else
    {
        ctx_err = CTX_RELEASE ((void *) &ctx_tag);

        if ( ctx_err != P2_CTX_OK )
        {
        	if(ctx_err !=7)
        	{
				EVT_manage( EVTN_ERR_CTX_RELEASE_KO,
							0,
							i_interval_time,
							'A',
							"Releasing CTX [0x%08X] - Err.[%d]",
							ctx_tag,
							ctx_err);

				log_(LOG_ERROR,"%s: Releasing CTX [0x%08X] - Err.[%d]",
						__FUNCTION__,
						ctx_tag,
						ctx_err);
        	}
        	else
        	{
        		log_(LOG_WARNING,"%s: Releasing CTX [0x%08X] - Err.[%d]",
						__FUNCTION__,
						ctx_tag,
						ctx_err);
        	}
        }
        else
        	log_(LOG_DEBUG2,"%s: Releasing successfully - CTX [0x%08X]",
        			__FUNCTION__,
        			ctx_tag);
    }

    return (ctx_err);
}

/* -------------------------------------------------------------------------------------------------- */
short CTXExtendLifetimeOfContext( long ctx_tag,	    // i
                                  long timeout )	// i
{
    short segment;

    return ( CTX_CHECK((void *) &ctx_tag, &segment, timeout) );
}

/* -------------------------------------------------------------------------------------------------- */
short CTXCheckContext(long ctx_tag)	// i
{
    short segment;
    
    return ( CTX_CHECK((void *) &ctx_tag, &segment, -1) );
}

/* -------------------------------------------------------------------------------------------------- */
void SetdiscardedTimeout(long timeout)	// i
{
    discardedTimeout = timeout;
    return;
}

/* -------------------------------------------------------------------------------------------------- */
void SetlockTimeout(long timeout)		// i
{
    lockTimeout = timeout;
    return;
}

/* -------------------------------------------------------------------------------------------------- */
void SetprotectedClass(short pclass)	// i
{
    protectedClass = pclass;
    return;
}

/* -------------------------------------------------------------------------------------------------- */
long GetdiscardedTimeout(void)
{
    return discardedTimeout;
}

/* Private functions */
/* -------------------------------------------------------------------------------------------------- */
static long GetlockTimeout(void)
{
    return lockTimeout;
}

/* -------------------------------------------------------------------------------------------------- */
static short GetprotectedClass(void)
{
    return protectedClass;
}
/* -------------------------------------------------------------------------------------------------- */
