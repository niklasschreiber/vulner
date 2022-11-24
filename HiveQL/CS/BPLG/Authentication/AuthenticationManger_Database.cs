using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace BPLG.Authentication
{
    class AuthenticationManger_Database : AuthenticationManager_Credential
    {
        #region CTOR
        public AuthenticationManger_Database(string dbSecurityType, string strConnString, string idApplication)
        {
            m_strConnString = strConnString;
            m_IDApplication = idApplication;
            m_DBSecurityType = dbSecurityType;
        }
        #endregion CTOR

        #region OVERRIDED METHODS
        /// <summary>
        /// Questo metodo si occupa di restituire un valore informando il caller
        /// se l'utente è attualmente loggato.
        /// </summary>
        /// <returns>Indicatore dell'avvenuto login dell'utente</returns>
        public override sealed bool IsLogged()
        {
            return m_bolLoggedIn;
        }

        public override sealed AuthenticationPolicy.UserLoggedStatus LoggedStatus()
        {
            return (IsLogged()) ? AuthenticationPolicy.UserLoggedStatus.AlreadyLogged : AuthenticationPolicy.UserLoggedStatus.NotLogged;
        }

        public override sealed IAuthenticationManager GetInstance()
        {
            return this;
        }
        #endregion OVERRIDED METHODS
    }
}
