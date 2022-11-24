//------------------------------------------------------------------------------
//   PROJECT : Traffic Steering - Inbound/OutBound Relay Server - v 1.02
//------------------------------------------------------------------------------
//
//   File Name   : tfsstat.c
//   Created     : 27-09-2004
//   Last Change : 03-06-2013
//
//------------------------------------------------------------------------------
//   Description
//   -----------
//
//------------------------------------------------------------------------------
//   Functions
//   ------------------
//------------------------------------------------------------------------------

//---------------------< Include files >----------------------------------------

#include <strings.h>
#include <stdio.h>
#include <p2system.p2apdfh>
#include <erainc.ccpy>
#include <cssinc.cext>
#include <cextdecs.h (JULIANTIMESTAMP)>
#include <sspstat.h>
#include "tfsdef.h"
#include "tfsstat.h"

void SetThroughputStat( long long ts,
                        char c_for )
{
    long long i_diff = (long long)(JULIANTIMESTAMP(0) - ts);

    if( i_diff >= 0 )
    {
        switch( c_for )
        {
            case MAPIN_GTT_RELAY:
            {
                if( i_diff <= 5000 ) // <= 5/1000"
                    AddStat(STAT_MAPIRO_PREFIX_REGS,"MAPIR",TOT_MAPIN_GTT_MAPRELAY_5_MILL);
                else if( i_diff <= 10000 ) // <= 10/1000"
                    AddStat(STAT_MAPIRO_PREFIX_REGS,"MAPIR",TOT_MAPIN_GTT_MAPRELAY_10_MILL);
                else if( i_diff <= 25000 ) // <= 25/1000
                    AddStat(STAT_MAPIRO_PREFIX_REGS,"MAPIR",TOT_MAPIN_GTT_MAPRELAY_25_MILL);
                else if( i_diff <= 50000 ) // <= 50/1000
                    AddStat(STAT_MAPIRO_PREFIX_REGS,"MAPIR",TOT_MAPIN_GTT_MAPRELAY_50_MILL);
                else if( i_diff <= 75000 ) // <= 75/1000"
                    AddStat(STAT_MAPIRO_PREFIX_REGS,"MAPIR",TOT_MAPIN_GTT_MAPRELAY_75_MILL);
                else if( i_diff <= 100000 ) // <= 100/1000"
                    AddStat(STAT_MAPIRO_PREFIX_REGS,"MAPIR",TOT_MAPIN_GTT_MAPRELAY_100_MILL);
                else if( i_diff <= 250000 ) // <= 250/1000"
                    AddStat(STAT_MAPIRO_PREFIX_REGS,"MAPIR",TOT_MAPIN_GTT_MAPRELAY_250_MILL);
                else if( i_diff <= 500000 ) // <= 500/1000"
                    AddStat(STAT_MAPIRO_PREFIX_REGS,"MAPIR",TOT_MAPIN_GTT_MAPRELAY_500_MILL);
                else if( i_diff <= 750000 ) // <= 750/1000"
                    AddStat(STAT_MAPIRO_PREFIX_REGS,"MAPIR",TOT_MAPIN_GTT_MAPRELAY_750_MILL);
                else if( i_diff <= 1000000) // <= 1"
                    AddStat(STAT_MAPIRO_PREFIX_REGS,"MAPIR",TOT_MAPIN_GTT_MAPRELAY_1_SEC);
                else if( i_diff <= 2000000 ) // <= 2"
                    AddStat(STAT_MAPIRO_PREFIX_REGS,"MAPIR",TOT_MAPIN_GTT_MAPRELAY_2_SEC);
                else if( i_diff <= 3000000 ) // <= 3"
                    AddStat(STAT_MAPIRO_PREFIX_REGS,"MAPIR",TOT_MAPIN_GTT_MAPRELAY_3_SEC);
                else if( i_diff > 3000000 ) // > 3"
                    AddStat(STAT_MAPIRO_PREFIX_REGS,"MAPIR",TOT_MAPIN_GTT_MAPRELAY_MAG_3_SEC);

                break;
            }

            case MAPIN_TS_MAPOUT:
            {
                if( i_diff <= 5000 ) // <= 5/1000"
                    AddStat(STAT_MAPIRO_PREFIX_REGS,"MAPIR",TOT_MAPIN_TS_MAPOUT_5_MILL);
                else if( i_diff <= 10000 ) // <= 10/1000"
                    AddStat(STAT_MAPIRO_PREFIX_REGS,"MAPIR",TOT_MAPIN_TS_MAPOUT_10_MILL);
                else if( i_diff <= 25000 ) // <= 25/1000
                    AddStat(STAT_MAPIRO_PREFIX_REGS,"MAPIR",TOT_MAPIN_TS_MAPOUT_25_MILL);
                else if( i_diff <= 50000 ) // <= 50/1000
                    AddStat(STAT_MAPIRO_PREFIX_REGS,"MAPIR",TOT_MAPIN_TS_MAPOUT_50_MILL);
                else if( i_diff <= 75000 ) // <= 75/1000"
                    AddStat(STAT_MAPIRO_PREFIX_REGS,"MAPIR",TOT_MAPIN_TS_MAPOUT_75_MILL);
                else if( i_diff <= 100000 ) // <= 100/1000"
                    AddStat(STAT_MAPIRO_PREFIX_REGS,"MAPIR",TOT_MAPIN_TS_MAPOUT_100_MILL);
                else if( i_diff <= 250000 ) // <= 250/1000"
                    AddStat(STAT_MAPIRO_PREFIX_REGS,"MAPIR",TOT_MAPIN_TS_MAPOUT_250_MILL);
                else if( i_diff <= 500000 ) // <= 500/1000"
                    AddStat(STAT_MAPIRO_PREFIX_REGS,"MAPIR",TOT_MAPIN_TS_MAPOUT_500_MILL);
                else if( i_diff <= 750000 ) // <= 750/1000"
                    AddStat(STAT_MAPIRO_PREFIX_REGS,"MAPIR",TOT_MAPIN_TS_MAPOUT_750_MILL);
                else if( i_diff <= 1000000) // <= 1"
                    AddStat(STAT_MAPIRO_PREFIX_REGS,"MAPIR",TOT_MAPIN_TS_MAPOUT_1_SEC);
                else if( i_diff <= 2000000 ) // <= 2"
                    AddStat(STAT_MAPIRO_PREFIX_REGS,"MAPIR",TOT_MAPIN_TS_MAPOUT_2_SEC);
                else if( i_diff <= 3000000 ) // <= 3"
                    AddStat(STAT_MAPIRO_PREFIX_REGS,"MAPIR",TOT_MAPIN_TS_MAPOUT_3_SEC);
                else if( i_diff > 3000000 ) // > 3"
                    AddStat(STAT_MAPIRO_PREFIX_REGS,"MAPIR",TOT_MAPIN_TS_MAPOUT_MAG_3_SEC);

                break;
            }

            case MAPOUT_GTT_MAPOUT:
            {
                if( i_diff <= 5000 ) // <= 5/1000"
                    AddStat(STAT_MAPIRO_PREFIX_REGS,"MAPOUT",TOT_MAPOUT_GTT_MAPOUT_5_MILL);
                else if( i_diff <= 10000 ) // <= 10/1000"
                    AddStat(STAT_MAPIRO_PREFIX_REGS,"MAPOUT",TOT_MAPOUT_GTT_MAPOUT_10_MILL);
                else if( i_diff <= 25000 ) // <= 25/1000
                    AddStat(STAT_MAPIRO_PREFIX_REGS,"MAPOUT",TOT_MAPOUT_GTT_MAPOUT_25_MILL);
                else if( i_diff <= 50000 ) // <= 50/1000
                    AddStat(STAT_MAPIRO_PREFIX_REGS,"MAPOUT",TOT_MAPOUT_GTT_MAPOUT_50_MILL);
                else if( i_diff <= 75000 ) // <= 75/1000"
                    AddStat(STAT_MAPIRO_PREFIX_REGS,"MAPOUT",TOT_MAPOUT_GTT_MAPOUT_75_MILL);
                else if( i_diff <= 100000 ) // <= 100/1000"
                    AddStat(STAT_MAPIRO_PREFIX_REGS,"MAPOUT",TOT_MAPOUT_GTT_MAPOUT_100_MILL);
                else if( i_diff <= 250000 ) // <= 250/1000"
                    AddStat(STAT_MAPIRO_PREFIX_REGS,"MAPOUT",TOT_MAPOUT_GTT_MAPOUT_250_MILL);
                else if( i_diff <= 500000 ) // <= 500/1000"
                    AddStat(STAT_MAPIRO_PREFIX_REGS,"MAPOUT",TOT_MAPOUT_GTT_MAPOUT_500_MILL);
                else if( i_diff <= 750000 ) // <= 750/1000"
                    AddStat(STAT_MAPIRO_PREFIX_REGS,"MAPOUT",TOT_MAPOUT_GTT_MAPOUT_750_MILL);
                else if( i_diff <= 1000000) // <= 1"
                    AddStat(STAT_MAPIRO_PREFIX_REGS,"MAPOUT",TOT_MAPOUT_GTT_MAPOUT_1_SEC);
                else if( i_diff <= 2000000 ) // <= 2"
                    AddStat(STAT_MAPIRO_PREFIX_REGS,"MAPOUT",TOT_MAPOUT_GTT_MAPOUT_2_SEC);
                else if( i_diff <= 3000000 ) // <= 3"
                    AddStat(STAT_MAPIRO_PREFIX_REGS,"MAPOUT",TOT_MAPOUT_GTT_MAPOUT_3_SEC);
                else if( i_diff > 3000000 ) // > 3"
                    AddStat(STAT_MAPIRO_PREFIX_REGS,"MAPOUT",TOT_MAPOUT_GTT_MAPOUT_MAG_3_SEC);

                break;
            }
        }
    }
}

// set MSC stat: count the nbr of total BEGIN per OPC
void SetMSCStat( int i_opc,
                 short i_idx )
{
    char    ac_full_reg_name[11];

    sprintf(ac_full_reg_name,"%s%d",STAT_MSC_PREFIX_REGS,i_opc);

    AddStat(ac_full_reg_name,"MAPIR",i_idx);
}

short SetTimerBump_( long l_stat_bump_interval, // in seconds
                     long l_tag )

{
      short i_ret = 0;
      long  timerval;

      timerval = (long)stat_timerval( l_stat_bump_interval );

      if( timerval < 300 )
          timerval += 300;

      if( SIGNALTIMEOUT_( timerval ,
                          0 ,
                          l_tag ) )
      {
          i_ret = 1;
      }

      return i_ret;
}
