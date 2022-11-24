using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Text;
using System.Threading;
using System.Web;
using System.Web.Caching;
using BPLG.CryptoService;
using BPLG.Logging;

namespace BPLG.Authentication
{
    /// <summary>
    /// Questa classe si occupa di gestire le autenticazioni dell'applicazione chiamante basata su
    /// cookie. In particolare, questa classe si aspetta che esista un cookie su disco e tramite questo
    /// otterà i dati di cui necessita per identificare l'utente.
    /// </summary>
    class AuthenticationManager_Cookie : AuthenticationManager
    {
        #region CTOR
        public AuthenticationManager_Cookie(string dbSecurityType, string strConnString, string idApplication)
        {
            m_strConnString = strConnString;
            m_IDApplication = idApplication;
            m_DBSecurityType = dbSecurityType;

            if (m_LoggerLibrary == null)
            {
                m_LoggerLibrary = LoggerFactory.CreateLogger();
            }
        }
        #endregion CTOR

        #region METHODS
        #endregion METHODS

        #region OVERRIDED METHODS
        /// <summary>
        /// This method is in charge to check if the user is or not already logged. in this class, this method will
        /// perform an escalation of autheticated mode. For first it will be checked if exists in the application cache
        /// the user logged, if yes, no further operation will be performed, in case the cache does not contains information,
        /// it will be placed a check on the domain cookie. The domain cookie will be opened and it will be rescue the user and
        /// in this case will be assumed that the user is authenticated. If not even the domain cookie exists, this method 
        /// will return a false value. It will be the website in charge of call the application content will create the cookie
        /// </summary>
        /// <returns>True if user is logged otherwise false</returns>
        public override sealed bool IsLogged()
        {
            try
            {
#if DEBUG
                m_LoggerLibrary.Write(Logger.LogTypeMessage.Information, "Entrato nella IsLogged()");
#endif
                HttpCookie cookie = HttpContext.Current.Request.Cookies["AuthenticationPlanning"];
                if (cookie != null)
                {
#if DEBUG
                    m_LoggerLibrary.Write(Logger.LogTypeMessage.Information, "IsLogged - Il coockie non è nullo");
#endif
                    string Impersonated = cookie.Values["Impersonated"] as string;
                    string SessionId = HttpContext.Current.Session.SessionID;

                    if ((string.IsNullOrEmpty(Impersonated)) || (Impersonated == SessionId))
                    {
#if DEBUG
                        m_LoggerLibrary.Write(Logger.LogTypeMessage.Information, "IsLogged - Imersonated è nullo o uguale");
#endif
                        UserDetail.UserName = CryptoUtilities.Decrypt(cookie.Values["userLogged"].ToString());

                        DataTable userInfo = Database.DBHelper.GetDataTableFormStoredProcedure(
                                                            RescueConnection()
                                                            , "[Autorizzazioni].[spUserInfo]"
                                                            , "ResultTable"
                                                            , new SqlParameter[] { new SqlParameter("@sLogin", UserDetail.UserName) });
                        if (userInfo.Rows.Count > 0)
                        {
                            if (userInfo.Rows[0]["nIdUtente"] != null)
                            {
                                UserDetail.DisplayName = Convert.ToString(userInfo.Rows[0]["sNomeCompleto"]);
                                UserDetail.IdUtente = Convert.ToString(userInfo.Rows[0]["nIdUtente"]);
#if DEBUG
                                m_LoggerLibrary.Write(Logger.LogTypeMessage.Information, "IsLogged - Recuperato utente [" + UserDetail.DisplayName + "]");
#endif
                                if (m_LoggerLibrary != null)
                                {
                                    m_LoggerLibrary.Username = UserDetail.UserName;
                                }
                            }
                        }
                        return true;
                    }
                    else
                    {
#if DEBUG
                        m_LoggerLibrary.Write(Logger.LogTypeMessage.Information, "IsLogged - Il coockie non è nullo ma impersonated non è vuoto");
#endif
                        if (string.IsNullOrEmpty((ConfigurationManager.AppSettings["RemoteLoginPage"])))
                        {
                            throw new Exception("[MANAGED] - Impossible to authenticate user. There is no portal for authentication configured");
                        }
                        HttpContext.Current.Response.Redirect(string.Format(ConfigurationManager.AppSettings["RemoteLoginPage"], HttpContext.Current.Request.Url.ToString()), true);
                        return false;
                    }
                }
                else
                {
#if DEBUG
                    m_LoggerLibrary.Write(Logger.LogTypeMessage.Information, "IsLogged - Il coockie è nullo, vengo ridirezionato");
#endif
                    if (string.IsNullOrEmpty((ConfigurationManager.AppSettings["RemoteLoginPage"])))
                    {
                        throw new Exception("[MANAGED] - Impossible to authenticate user. There is no portal for authentication configured");
                    }
                    HttpContext.Current.Response.Redirect(string.Format(ConfigurationManager.AppSettings["RemoteLoginPage"], HttpContext.Current.Request.Url.ToString()), true);
                    return false;
                }
            }
            catch (ThreadAbortException TAEx) { return false; }
            catch (Exception Ex)
            {
#if DEBUG
                m_LoggerLibrary.Write(Logger.LogTypeMessage.Information, "IsLogged - Sono entrato nell'eccezione: " + Ex.Message);
#endif
                throw Ex;
            }
            
        }

        public override sealed AuthenticationPolicy.UserLoggedStatus LoggedStatus()
        {
            try
            {
                HttpCookie cookie = HttpContext.Current.Request.Cookies["AuthenticationPlanning"];
                if (cookie != null)
                {
                    string Impersonated = cookie.Values["Impersonated"] as string;
                    string SessionId = HttpContext.Current.Session.SessionID;

                    if ((string.IsNullOrEmpty(Impersonated)) || (Impersonated == SessionId))
                    {
                        UserDetail.UserName = CryptoUtilities.Decrypt(cookie.Values["userLogged"].ToString());

                        DataTable userInfo = Database.DBHelper.GetDataTableFormStoredProcedure(
                                                            RescueConnection()
                                                            , "[Autorizzazioni].[spUserInfo]"
                                                            , "ResultTable"
                                                            , new SqlParameter[] { new SqlParameter("@sLogin", UserDetail.UserName) });
                        if (userInfo.Rows.Count > 0)
                        {
                            if (userInfo.Rows[0]["nIdUtente"] != null)
                            {
                                UserDetail.DisplayName = Convert.ToString(userInfo.Rows[0]["sNomeCompleto"]);
                                UserDetail.IdUtente = Convert.ToString(userInfo.Rows[0]["nIdUtente"]);
                                return AuthenticationPolicy.UserLoggedStatus.AlreadyLogged;
                            }
                        }
                        return AuthenticationPolicy.UserLoggedStatus.NotAuthorized;
                    }
                    else
                    {
                        if (string.IsNullOrEmpty((ConfigurationManager.AppSettings["RemoteLoginPage"])))
                        {
                            throw new Exception("[MANAGED] - Impossible to authenticate user. There is no portal for authentication configured");
                        }
                        HttpContext.Current.Response.Redirect(string.Format(ConfigurationManager.AppSettings["RemoteLoginPage"], HttpContext.Current.Request.Url.ToString()), false);
                        return AuthenticationPolicy.UserLoggedStatus.NotLogged;
                    }
                }
                else
                {
                    if (string.IsNullOrEmpty((ConfigurationManager.AppSettings["RemoteLoginPage"])))
                    {
                        throw new Exception("[MANAGED] - Impossible to authenticate user. There is no portal for authentication configured");
                    }
                    HttpContext.Current.Response.Redirect(string.Format(ConfigurationManager.AppSettings["RemoteLoginPage"], HttpContext.Current.Request.Url.ToString()), false);
                    return AuthenticationPolicy.UserLoggedStatus.NotLogged;
                }
            }
            catch (Exception Ex)
            {
                throw Ex;
            }
        }

        public override sealed IAuthenticationManager GetInstance()
        {
            return this;
        }
        #endregion OVERRIDED METHODS

        public override AuthenticationPolicy.LoginResults LoginWithResult(string strUsername, string strPassword, bool IsImpersonale = false) { return AuthenticationPolicy.LoginResults.LoginNotAllowed; }
    }
}
