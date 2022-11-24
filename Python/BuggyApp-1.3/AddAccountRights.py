def __init__(self):
  try:
      import win32api, win32security

      username = win32api.GetUserNameEx(win32api.NameSamCompatible)
      print 'granting "logon as a service" rights to ' + username
      policy_handle = win32security.LsaOpenPolicy(None, win32security.POLICY_ALL_ACCESS)
      sid_obj, domain, tmp = win32security.LookupAccountName(None, username)
      win32security.LsaAddAccountRights( policy_handle, sid_obj, ('SeServiceLogonRight',) )
      win32security.LsaClose( policy_handle )
  except:
      print 'Exception granting user the SeServiceLogonRight:'
      print ''.join(traceback.format_exception(*sys.exc_info()))
      
def SpnRegister(
        serviceAcctDN,    # DN of the service's logon account
        spns,             # List of SPNs to register
        operation,         # Add, replace, or delete SPNs
           ):
    assert type(spns) not in [str, unicode] and hasattr(spns, "__iter__"), \
           "spns must be a sequence of strings (got %r)" % spns
    # Bind to a domain controller. 
    # Get the domain for the current user.
    samName = win32api.GetUserNameEx(win32api.NameSamCompatible)
    samName = samName.split('\\', 1)[0]

    if not serviceAcctDN:
        # Get the SAM account name of the computer object for the server.
        serviceAcctDN = win32api.GetComputerObjectName(win32con.NameFullyQualifiedDN)
    logger.debug("SpnRegister using DN '%s'", serviceAcctDN)

    # Get the name of a domain controller in that domain.
    info = win32security.DsGetDcName(
                domainName=samName,
                flags=dscon.DS_IS_FLAT_NAME |
                      dscon.DS_RETURN_DNS_NAME |
                      dscon.DS_DIRECTORY_SERVICE_REQUIRED)
    # Bind to the domain controller.
    handle = win32security.DsBind( info['DomainControllerName'] )

    # Write the SPNs to the service account or computer account.
    logger.debug("DsWriteAccountSpn with spns %s")
    win32security.DsWriteAccountSpn(
            handle,         # handle to the directory
            operation,   # Add or remove SPN from account's existing SPNs
            serviceAcctDN,        # DN of service account or computer account
            spns) # names

    # Unbind the DS in any case (but Python would do it anyway)
    handle.Close()
