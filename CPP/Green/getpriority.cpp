int Awstats::executeUpdate(const char * pName)
{
    const char * pWorking = m_sWorkingDir.c_str();
    char achBuf[8192];
    safe_snprintf( achBuf, 8192, "%s/add-ons/awstats",
            HttpGlobals::s_pServerRoot );
    if ( HttpGlobals::s_psChroot )
        pWorking += HttpGlobals::s_psChroot->len();
    if ( chdir( achBuf ) == -1 )
    {
        LOG_ERR(( "Cannot change to dir [%s]: %s", achBuf, strerror( errno ) ));
        return -1;
    }
    if ( m_iMode == AWS_STATIC )
    {
        safe_snprintf( achBuf, 8192,
            "tools/awstats_buildstaticpages.pl -awstatsprog=wwwroot/cgi-bin/awstats.pl"
            " -dir='%s/html' -update "
            "-configdir='%s/conf' "
            "-config='%s' -lang=en", pWorking, pWorking,
            pName );
    }
    else if ( m_iMode == AWS_DYNAMIC )
    {
        safe_snprintf( achBuf, 8192,
            "wwwroot/cgi-bin/awstats.pl -update -configdir='%s/conf' -config='%s'",
                pWorking, pName );
    }
    else
    {
        LOG_ERR(( "Unknown update method %d", m_iMode ));
        return -1;
    }
    
    setpriority( PRIO_PROCESS, 0, getpriority( PRIO_PROCESS, 0) + 4 );
    int ret = system( achBuf );
    return ret;
}
static TACommandVerdict getpriority_cmd(TAThread thread,TAInputStream stream)
{
   int which;
   int who  ;
   int res  ;

   // Prepare
   which = readInt( & stream );
   who   = readInt( & stream );
   errno = 0;

   // Execute
   START_TARGET_OPERATION(thread);
   res = getpriority( which, who );
   END_TARGET_OPERATION(thread);

   // Response
   writeInt( thread, res   );
   writeInt( thread, errno );
   sendResponse( thread );

   return taDefaultVerdict;
}