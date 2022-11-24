using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Text;
using System.Web;
using System.Web.Caching;
using BPLG.CryptoService;

namespace BPLG.Authentication
{
    /// <summary>
    /// La classe AuthenticationManager_Mixed viene utilizzata in quei contesti in cui un'applicazione
    /// deve permettere sia l'autenticazione integrata e sia quella basata su Login page. In questo caso 
    /// in questa classe si verificano tutte e due e si autentica l'utente in base a come le credenziali
    /// vengono fornite
    /// </summary>
    class AuthenticationManager_Mixed : AuthenticationManager_Credential
    {
        #region MEMBER
        /// <summary>
        /// Questo parametro indica se l'utente è già loggato nel sito o se non ha
        /// effettuato la Login o l'autenticazione integrata.
        /// </summary>
        protected bool m_AlreadyLogged = false;
        #endregion MEMBER

        #region CTOR
        /// <summary>
        /// Il costruttore si occupa di settare alcuni valori generici e tentare l'autenticazione integrata nel
        /// caso in cui il parametro UserName sia settato.
        /// </summary>
        /// <param name="SecurityType">
        /// Tipo di Security con il quale si deve lavorare. Se entrati in questa classe
        /// la security deve essere DBAZMMIXED
        /// </param>
        /// <param name="ConnectionString">Connection String per il database Profili e Risorse</param>
        /// <param name="ApplicationIdentity">Id dell'applicazione caller</param>
        /// <param name="UserName">
        /// UserName ottenuto dalla factory. Se settato vuol dire che siamo nel caso di
        /// autenticazione integrata altrimenti abbiamo un'autenticazione basata su dati utente
        /// </param>
        public AuthenticationManager_Mixed(string SecurityType, string ConnectionString, string ApplicationIdentity, string UserName = null)
        {
            m_strConnString = ConnectionString;
            m_IDApplication = ApplicationIdentity;
            m_DBSecurityType = SecurityType;
            m_IsIntegrated = true;

            #region SET USER BASED ON WINDOWS AUTHENTICATION
            if ((!IsLogged()) && (!string.IsNullOrEmpty(UserName)))
            {
                IntegratedLogging(UserName);
            }
            #endregion SET USER BASED ON WINDOWS AUTHENTICATION
        }
        #endregion CTOR

        #region METHODS
        private void IntegratedLogging(string UserName) 
        {
            UserDetail.UserName = UserName;
            UserDetail.OriginallyUserName = UserName;

            DataTable userInfo = Database.DBHelper.GetDataTableFormStoredProcedure(
                                            RescueConnection()
                                            , "[Autorizzazioni].[spUserInfo]"
                                            , "ResultTable"
                                            , new SqlParameter[] { new SqlParameter("@sLogin", UserName) });
            if ((userInfo != null) && (userInfo.Rows.Count == 1))
            {
                UserDetail.UserName = UserName;
                UserDetail.Name = Convert.ToString(userInfo.Rows[0]["sNome"]);
                UserDetail.Surname = Convert.ToString(userInfo.Rows[0]["sCognome"]);
                UserDetail.DisplayName = Convert.ToString(userInfo.Rows[0]["sNomeCompleto"]);
                UserDetail.Email = Convert.ToString(userInfo.Rows[0]["sEmail"]);
                UserDetail.GiorniRimanentiPassword = userInfo.Rows[0]["nNumeroGiorniScadenzaPassword"] != DBNull.Value ? Convert.ToInt32(userInfo.Rows[0]["nNumeroGiorniScadenzaPassword"]) : 0;
                UserDetail.ImmagineUtente = (userInfo.Rows[0]["vbImmagineUtente"] != DBNull.Value) ? System.Text.Encoding.UTF8.GetBytes(userInfo.Rows[0]["vbImmagineUtente"].ToString()) : null;
                UserDetail.MimeType = Convert.ToString(userInfo.Rows[0]["sImmagineUtenteMimeType"]);
                UserDetail.IdUtente = Convert.ToString(userInfo.Rows[0]["nIdUtente"]);

                RequestCookieCreation();
                m_AlreadyLogged = true;
                
            }
        }
        #endregion METHODS

        #region OVERRIDED METHODS
        public override sealed bool IsLogged()
        {
            bool retValLogin = false;
            try
            {
                #region GESTIONE DEI DATI TRAMITE IL COOKIE
                HttpCookie cookie = HttpContext.Current.Request.Cookies["AuthenticationPlanning"];
                if (cookie != null)
                {
                    string Impersonated = cookie.Values["Impersonated"] as string;
                    string SessionId = HttpContext.Current.Session.SessionID;

                    if ((string.IsNullOrEmpty(Impersonated)) || (Impersonated == SessionId))
                    {
                        #region RECUPERO DEI DATI DAL COOKIE
                        UserDetail.UserName = CryptoUtilities.Decrypt(cookie.Values["userLogged"].ToString());

                        DataTable userInfo = Database.DBHelper.GetDataTableFormStoredProcedure(
                                                            RescueConnection()
                                                            , "[Autorizzazioni].[spUserInfo]"
                                                            , "ResultTable"
                                                            , new SqlParameter[] { new SqlParameter("@sLogin", UserDetail.UserName) });
                        
                        if ((userInfo != null) && (userInfo.Rows.Count == 1))
                        {
                            UserDetail.Name = Convert.ToString(userInfo.Rows[0]["sNome"]);
                            UserDetail.Surname = Convert.ToString(userInfo.Rows[0]["sCognome"]);
                            UserDetail.DisplayName = Convert.ToString(userInfo.Rows[0]["sNomeCompleto"]);
                            UserDetail.Email = Convert.ToString(userInfo.Rows[0]["sEmail"]);
                            UserDetail.GiorniRimanentiPassword = userInfo.Rows[0]["nNumeroGiorniScadenzaPassword"] != DBNull.Value ? Convert.ToInt32(userInfo.Rows[0]["nNumeroGiorniScadenzaPassword"]) : 0;
                            UserDetail.ImmagineUtente = (userInfo.Rows[0]["vbImmagineUtente"] != DBNull.Value) ? System.Text.Encoding.UTF8.GetBytes(userInfo.Rows[0]["vbImmagineUtente"].ToString()) : null;
                            UserDetail.MimeType = Convert.ToString(userInfo.Rows[0]["sImmagineUtenteMimeType"]);
                            UserDetail.IdUtente = Convert.ToString(userInfo.Rows[0]["nIdUtente"]);

                            if (string.IsNullOrEmpty(Impersonated))
                            {
                                RequestCookieCreation();
                            }
                            else 
                            {
                                RequestCookieCreation(true);
                            }
                            
                            m_AlreadyLogged = true;

                        }
                        #endregion RECUPERO DEI DATI DAL COOKIE
                        retValLogin = true;
                    }
                    else 
                    {
                        if (m_IsIntegrated)
                        {
                            IntegratedLogging(UserDetail.UserName);
                            retValLogin = true;
                        }
                    }
                }
                else 
                {
                    if (m_IsIntegrated) 
                    {
                        IntegratedLogging(UserDetail.UserName);
                        retValLogin = true;
                    }
                }
                #endregion GESTIONE DEI DATI TRAMITE IL COOKIE
            }
            catch (Exception Ex)
            {
            }
            return retValLogin;
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
