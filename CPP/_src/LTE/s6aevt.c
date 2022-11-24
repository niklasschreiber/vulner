//------------------------------------------------------------------------------
//   Project : LTE-TFS v 01.00
//------------------------------------------------------------------------------
//
//   File Name   : s6aevt.c
//   Created     : 15-02-2012
//   Last Change : 16-03-2012
//
//------------------------------------------------------------------------------
//   Description
//   -----------
//
//------------------------------------------------------------------------------

#include <stdio.h>
#include <stdlib.h>
#include <memory.h>
#include <string.h>
#include <strings.h>
#include <stdarg.h>
#include <time.h>
#include <sspevt.h>
#include "s6aevt.h"

static short _i_init_ems = 0;
static EVT_MSG evt_msg[NBR_EVT_MSG_ERR];

// ---------------------------------------------------------------------------
void EVT_manage_init(void)
{
	short i;

	for( i=0; i<NBR_EVT_MSG_ERR ; i++ )
		memset(&evt_msg[i],0x00,sizeof(EVT_MSG));

	_i_init_ems = 1;
}

/** ---------------------------------------------------------------------------
*
* @param i_msg_evt 		 - in parameter - EMS Number
* @param i_nbr_alert_msg - in parameter - Nbr of alert will be showed on viewpoint
* @param i_interval_time - in parameter - time interval between two alarm msg
* @param c_ems_status    - in parameter - status of EMS alarm ( 'A' - Alarm armed | 'D' - Alarm disarmed )
* @param *ac_msg	 	 - in parameter - Description of EMS showed on viewpoint
* \note Error Returned:
* \note         0  : Ok
* \note        -1  : the EMS number exceeds the maximum EMS number range
* \note        -2  : wrong EMS status parameter value
* -----------------------------------------------------------------------------
*/
short EVT_manage( short i_msg_evt,
                  short i_nbr_alert_msg,
                  short i_interval_time,
                  char c_ems_status,
                  const char *ac_msg, ... )
{
    short 	i_ret = 0;
    short 	i_idx;
    short	i_write_ems = 0;
    char 	ac_out[256];
    va_list ap;
    time_t 	now;

    if( _i_init_ems )
    {
		switch( c_ems_status )
		{
			case EMS_STATUS_ARMED:
			{
				i_idx = (short)(i_msg_evt - E_LTFS_ARM_BASE_NUMBER);

				if( i_idx >= 0 && i_idx < NBR_EVT_MSG_ERR )
				{
					i_write_ems = 0;

					if( !i_interval_time &&
						!i_nbr_alert_msg )
					{
						i_write_ems = 1; // like normal log_evt
					}
					else
					{
						if(i_interval_time)
						{
							time(&now);

							if( (now - evt_msg[i_idx].i_first_msg_show_time > i_interval_time) ||
								!evt_msg[i_idx].i_evt_alarm )
							{
								if(i_nbr_alert_msg)
								{
									if( evt_msg[i_idx].i_nbr_msg_showed < i_nbr_alert_msg )
									{
										i_write_ems = 1;
										evt_msg[i_idx].i_nbr_msg_showed++;
									}
								}
								else
								{
									i_write_ems = 1;
								}

								evt_msg[i_idx].i_evt_alarm = i_msg_evt;
								time(&(evt_msg[i_idx].i_first_msg_show_time));
							}
						}

						if( i_nbr_alert_msg &&
							!i_write_ems )
						{
							if( evt_msg[i_idx].i_nbr_msg_showed < i_nbr_alert_msg )
							{
								i_write_ems = 1;

								evt_msg[i_idx].i_nbr_msg_showed++;
								evt_msg[i_idx].i_evt_alarm = i_msg_evt;
							}
						}
					}

					if(i_write_ems)
					{
						i_write_ems = 0;

						va_start(ap, ac_msg);
						vsprintf(ac_out, ac_msg, ap);

						log_evt( SSPEVT_CRITICAL,
								 SSPEVT_NOACTION,
								 i_msg_evt,
								 "%s", ac_out);

						va_end(ap);
					}
				}
				else
					i_ret = -1;

				break;
			}

			case EMS_STATUS_DISARMED:
			{
				i_idx = (short)(i_msg_evt - E_LTFS_DISARM_BASE_NUMBER);

				if( i_idx >= 0 && i_idx < NBR_EVT_MSG_ERR )
				{
					evt_msg[i_idx].i_evt_alarm      = 0;
					evt_msg[i_idx].c_status         = 'D';
					evt_msg[i_idx].c_filler         = 0;
					evt_msg[i_idx].i_nbr_msg_showed = 0;

					time(&(evt_msg[i_idx].i_first_msg_show_time));

					va_start(ap, ac_msg);
					vsprintf(ac_out, ac_msg, ap);

					log_evt( SSPEVT_NORMAL,
							 SSPEVT_NOACTION,
							 i_msg_evt,
							 "%s", ac_out);

					va_end(ap);
				}
				else
					i_ret = -1;

				break;
			}

			case EMS_STATUS_NORMAL:
			{
				va_start(ap, ac_msg);
				vsprintf(ac_out, ac_msg, ap);

				log_evt( SSPEVT_NORMAL,
						 SSPEVT_NOACTION,
						 i_msg_evt,
						 "%s", ac_out);

				va_end(ap);

				break;
			}

			default:
			{
				i_ret = -2;

				break;
			}
		}
    }
    else
    	i_ret = -3;

    return(i_ret);
}
