using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Text;
using System.Web;
using System.Web.Caching;
using BPLG.CryptoService;
using BPLG.Organigramma;

namespace BPLG.Authentication
{
    /// <summary>
    /// Questa classe si occupa di tutta la sezione dedicata all'autenticazione integrata.
    /// Alcuni metodi ereditati dalla classe base lanciano un errore nel caso in cui vengano
    /// usati in questa classe. In particolare tutti i metodi che permetteno di effettuare 
    /// operazioni sulla password storata sul database e sull'autenticazione con Login
    /// </summary>
    class AuthenticationManager_Integrated : AuthenticationManager_Cookieless
    {
        #region CTOR
        /// <summary>
        /// Il costruttore di questa classe ha il compito di settare alcuni parametri di base e di
        /// recuperare, tramite lo UserName ottenuto dalla Windows Authentication i vari dati dell'utente
        /// recuperandoli dal database.
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
        public AuthenticationManager_Integrated(string SecurityType, string ConnectionString, string ApplicationIdentity, string UserName)
        {
            m_strConnString = ConnectionString;
            m_IDApplication = ApplicationIdentity;
            m_DBSecurityType = SecurityType;

            UserDetail.OriginallyUserName = UserName;

            //SqlConnection con = Data.DBHelper.OpenConnection(m_strConnString);
            DataTable userInfo = Database.DBHelper.GetDataTableFormStoredProcedure(
                                            RescueConnection()
                                            , "[Autorizzazioni].[spUserInfo]"
                                            , "ResultTable"
                                            , new SqlParameter[] { new SqlParameter("@sLogin", UserName) });
            if ((userInfo != null) && (userInfo.Rows.Count == 1))
            {
                UserDetail.UserName = UserName;
                UserDetail.DisplayName = Convert.ToString(userInfo.Rows[0]["sNomeCompleto"]);
                UserDetail.IdUtente = Convert.ToString(userInfo.Rows[0]["nIdUtente"]);

                RequestCookieCreation();
            }
        }
        #endregion CTOR

        #region OVERRIDED METHODS
        /// <summary>
        /// Questo metodo ritorna sempre true in quanto l'utente è autenticato tramite 
        /// Windows Authentication
        /// </summary>
        /// <returns>Sempre true</returns>
        public override sealed bool IsLogged()
        {
            return true;
        }

        /// <summary>
        /// Questo metodo ritorna sempre l'utente come già loggato in quanto trattasi di 
        /// autenticazione basata su credenziali di Windows
        /// </summary>
        /// <returns>Sempre UserLoggedStatus.AlreadyLogged</returns>
        public override sealed AuthenticationPolicy.UserLoggedStatus LoggedStatus()
        {
            return AuthenticationPolicy.UserLoggedStatus.AlreadyLogged;
        }

        /// <summary>
        /// Questo metodo restituisce un'istanza dell'interfaccia che permetterà
        /// all'utente di utilizare i metodi della chain di classi
        /// </summary>
        /// <returns>Interfaccia della classe specifica all'interno della chain di ereditarietà</returns>
        public override sealed IAuthenticationManager GetInstance()
        {
            return this;
        }
        #endregion OVERRIDED METHODS
    }
}
