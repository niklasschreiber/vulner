using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;
using System.Web;
using System.Web.Caching;
using BPLG.CryptoService;
using BPLG.Logging;
using BPLG.Organigramma;

namespace BPLG.Authentication
{
    /// <summary>
    /// La classe AuthenticationManager è la Base class di una serie di classi che permettono
    /// le autenticazioni degli utenti basate su 
    ///     - Windows Authentication tramite la classe AuthenticationManager_Integrated
    ///     - Login Authentication tramite la classe AuthenticationManager_Credential
    ///     - Cookie Authentication tramite la classe AuthenticationManager_Cookie
    ///     - Mixed Authentication tramite la classe AuthenticationManager_Mixed
    /// Lo sviluppatore non si dovrà preoccupare di quale classe utilizzare in quanto, tramite il
    /// parametro SecurityType verra servita l'istanza di classe specifica al tipo di autenticazione
    /// richiesta
    /// </summary>
    abstract class AuthenticationManager : IAuthenticationManager
    {
        #region PRIVATE CLASS MEMBER
        protected string m_strConnString = "";
        protected string m_IDApplication = "";
        protected string m_DBSecurityType = "";
        protected bool m_bolCacheEnabled = false;
        protected int m_CacheExpireDelay = 5;
        protected UserDetails m_UserDetail = new UserDetails();
        protected bool m_IsIntegrated = false;
        protected Logger m_LoggerLibrary = null;
        #endregion PRIVATE CLASS MEMBER

        #region PROPERTIES
        /// <summary>
        /// Dettagli relativi all'utente loggato. Questa classe contiene 
        /// delle property in cui sono memorizzati i dati utente
        /// </summary>
        public UserDetails UserDetail
        {
            get { return m_UserDetail; }
        }
        public bool IsIntegrated
        {
            get
            {
                return m_IsIntegrated;
            }
        }
        #endregion PROPERTIES

        #region BASE CLASS METHODS
        /// <summary>
        /// Questo metodo verifica se l'utente ha la permission per effettuare una determinata
        /// funzione. La permission viene passata dal caller e viene verificato sul db che si abbiano
        /// le policy per utilizzarla.
        /// </summary>
        /// <param name="strOperation">Operation di cui si vuole sapere se si ha o meno la permission</param>
        /// <param name="UserParameter">Utente da testare</param>
        /// <param name="UserData">Objcet contenente i dati dell'utente</param>
        /// <returns>True se l'utente ha la permission richiesta</returns>
        [Obsolete("Questo metodo non deve più essere utilizzato con la nuova struttura")]
        public bool HasPermission(string strOperation, string UserParameter, AuthenticationPolicy.UserData UserData)
        {
            bool allowed = false;
            if ((m_DBSecurityType == "DBAZMLOGIN") && (!IsLogged()))
                return false;
            else
            {
                if ((HttpContext.Current.Cache[UserDetail.UserName + "|" + strOperation] == null) || (!m_bolCacheEnabled))
                {
                    //SqlConnection con = Database.DBHelperCollection.Instance(m_strConnString).OpenConnection();
                    SqlParameter retParam = new SqlParameter("@Result", null);
                    retParam.DbType = System.Data.DbType.Int32;
                    retParam.Direction = System.Data.ParameterDirection.ReturnValue;


                    //SqlParameter[] par = new SqlParameter[5];
                    //par[0] = new SqlParameter("@nIdUtente", UserData == AuthenticationPolicy.UserData.UserLogin ? UserParameter : null);
                    //par[0] = new SqlParameter("@sCodiceApplicazione", "");
                    //par[1] = new SqlParameter("@sFunzionalitaApplicativa", strOperation);

                    //par[4] = new SqlParameter("@Result", null);
                    //par[4].DbType = System.Data.DbType.Int16;
                    //par[4].Direction = System.Data.ParameterDirection.Output;

                    Database.DBHelper.ExecuteStoredProcedure(RescueConnection()
                                    , "[Autorizzazioni].[spHasPermission]"
                                    , null
                                    , new SqlParameter[] 
                                        { 
                                            new SqlParameter("@nIdUtente", UserData == AuthenticationPolicy.UserData.UserId ? UserParameter : null)
                                            , new SqlParameter("@sCodiceApplicazione", "")
                                            , new SqlParameter("@sFunzionalitaApplicativa", strOperation)
                                            , retParam
                                        });

                    allowed = retParam.Value as int? != null ? Convert.ToBoolean(retParam.Value) : false;

                    if (m_bolCacheEnabled)
                    {
                        HttpContext.Current.Cache.Insert(
                                                UserDetail.UserName + "|" + strOperation,
                                                allowed,
                                                null, DateTime.Now.AddMinutes(m_CacheExpireDelay), Cache.NoSlidingExpiration);
                    }
                    else
                    {
                        return Convert.ToBoolean(allowed);
                    }
                }
                return (Convert.ToBoolean(HttpContext.Current.Cache[UserDetail.UserName + "|" + strOperation]));
            }
        }

        /// <summary>
        /// Questo metodo verifica la permission per l'utente correntemente loggato.
        /// </summary>
        /// <param name="strOperation">Operation di cui verificare la permission</param>
        /// <returns>True se l'utente ha la permission richiesta</returns>
        [Obsolete("Questo metodo non deve più essere utilizzato con la nuova struttura")]
        public bool HasPermission(string strOperation)
        {
            return HasPermission(strOperation, UserDetail.IdUtente, AuthenticationPolicy.UserData.UserId);
        }

        /// <summary>
        /// Questo metodo crea un cookie sul disco con lo UserName come campo per poter
        /// autorizzare l'utente senza dover riottenere le credenziali dalla Windows Authentication
        /// o dalla Login Page
        /// </summary>
        protected void RequestCookieCreation(bool IsImpersonate = false)
        {
            try
            {
                if (HttpContext.Current.Response.Cookies["AuthenticationPlanning"] != null) 
                {
                    HttpContext.Current.Response.Cookies.Remove("AuthenticationPlanning");
                }

                HttpCookie myCookie = new HttpCookie("AuthenticationPlanning");
                myCookie.Values.Add("userLogged", CryptoUtilities.Encrypt(UserDetail.UserName));
                if (IsImpersonate)
                {
                    myCookie.Values.Add("Impersonated", HttpContext.Current.Session.SessionID);
                }
                myCookie.Expires = DateTime.Now.AddMinutes(10);
                HttpContext.Current.Response.Cookies.Add(myCookie);
            }
            catch (Exception Ex)
            {
                throw;
            }

        }

        protected SqlConnection RescueConnection()
        {
            return Database.DBHelperCollection.Instance(m_strConnString).OpenConnection();
        }
        #endregion BASE CLASS METHODS

        #region VIRTUAL METHODS
        /// <summary>
        /// Questo metodo permette di effettuare un Login attraverso una user e una
        /// password. Se il tipo di autenticazione è DBAZMDOMAIN questo metodo 
        /// lancierà un'eccezione
        /// </summary>
        /// <param name="strUsername">Nome utente, corrisponde alla User Login</param>
        /// <param name="strPassword">Password utente</param>
        /// <returns>Enumeration per indicare lo stato della Login</returns>
        public virtual AuthenticationPolicy.LoginResults LoginWithResult(string strUsername, string strPassword, bool IsImpersonale = false)
        {
            throw new System.Security.Authentication.AuthenticationException("Login is not allowed with this kind of secutiry type");
        }

        /// <summary>
        /// Questo metodo permette di effettuare un cambio password attraverso la vecchia
        /// password e una nuova che viene scelta dall'utente. Effettua il cambio password 
        /// sull'utente corrente loggato
        /// </summary>
        /// <param name="oldPassword">Vecchia password inserita dell'utente</param>
        /// <param name="newPassword">Nuova password inserita dall'utente</param>
        /// <returns>True se il cambio password si è concluso con successo</returns>
        public virtual AuthenticationPolicy.PasswordChange CambioPassword(string oldPassword, string newPassword)
        {
            throw new System.Security.Authentication.AuthenticationException("Change Password operation is not allowed with this kind of secutiry type");
        }

        /// <summary>
        /// Questo metodo permette il reset della password. Il reset della password creerà una password
        /// temporanea basata su TIMESTAMP hashato in formato SHA512 per memorizzare un token univoco da
        /// ripresentare all'utente sulla mail col link attraverso il quale l'utente potrà procedere a
        /// reimpostare la propria password
        /// </summary>
        /// <param name="userName">UserName inserito dall'utente</param>
        /// <returns>True se l'operazione è andata a buon fine oppure false in caso non sia riuscita</returns>
        public virtual AuthenticationPolicy.PasswordReset ResetPassword(out string TimeStampPassword, string UserName = null)
        {
            throw new System.Security.Authentication.AuthenticationException("Reset Password operation is not allowed with this kind of secutiry type");
        }

        public virtual bool PasswordComplexityCheck(string passwordToCheck)
        {
            bool retValue = false;
            const string PatternFull = @"^(?=.*[a-z]){0}{1}{2}.{{{3},{4}}}$";
            const string ForceUpperCase = @"(?=.*[A-Z])";
            const string ForceNumber = @"(?=.*\d)";
            const string ForceSpecial = @"(?=.*[^\da-zA-Z])";


            StringBuilder patternPassword = new StringBuilder();
            //SqlConnection con = Database.DBHelperCollection.Instance(m_strConnString).OpenConnection();

            DataTable configInfo = Database.DBHelper.GetDataTableFormStoredProcedure(RescueConnection(), "[Autorizzazioni].[spConfigurazioni]");
            if ((configInfo != null) && (configInfo.Rows.Count == 1))
            {
                string patternFinal = string.Format(PatternFull
                                        , Convert.ToBoolean(configInfo.Rows[0]["bForzaMaiuscole"]) ? ForceUpperCase : ""
                                        , Convert.ToBoolean(configInfo.Rows[0]["bForzaNumeri"]) ? ForceNumber : ""
                                        , Convert.ToBoolean(configInfo.Rows[0]["bForzaNumeri"]) ? ForceSpecial : ""
                                        , Convert.ToInt32(configInfo.Rows[0]["nLunghezzaMinimaPassword"]) > 0 ? Convert.ToString(configInfo.Rows[0]["nLunghezzaMinimaPassword"]) : "0"
                                        , Convert.ToInt32(configInfo.Rows[0]["nLunghezzaMassimaPassword"]) > 0 ? Convert.ToString(configInfo.Rows[0]["nLunghezzaMassimaPassword"]) : "");

                retValue = Regex.IsMatch(passwordToCheck, patternFinal);
            }
            return retValue;
        }
        #endregion VIRTUAL METHODS

        #region OVERRIDABLE CLASS METHODS
        /// <summary>
        /// Questo metodo restituisce un flag che indica se l'utente è o meno loggato all'applicativo.
        /// </summary>
        /// <example>
        /// Questo esempio mostra come utilizzare il metodo
        /// <code>
        /// class TestClass
        /// {
        ///     static int Main()
        ///     {
        ///         bool isLogged = General.Authentication.IsLogged();
        ///     }
        /// }
        /// </code>
        /// </example>
        /// <returns>True se l'utente risulta loggato</returns>
        public abstract bool IsLogged();

        public abstract AuthenticationPolicy.UserLoggedStatus LoggedStatus();

        /// <summary>
        /// Questo metodo restituisce un'istanza dell'interfaccia che permetterà
        /// all'utente di utilizare i metodi della chain di classi
        /// </summary>
        /// <returns>Interfaccia della classe specifica all'interno della chain di ereditarietà</returns>
        public abstract IAuthenticationManager GetInstance();
        #endregion OVERRIDABLE CLASS METHODS
    }
}
