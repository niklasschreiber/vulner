using System;
using System.Collections.Generic;
using System.Text;
using System.Data;
using System.Data.SqlClient;
using System.Security.Cryptography;
using System.Web;
using System.Web.Caching;
using System.Collections;
using System.Linq;

namespace BPLG.Security
{
    public enum UserData
    {
        UserId = 0,
        UserLogin = 1
    }

    public enum UserLoggedStatus
    {
        NotLogged = 0,
        AlreadyLogged = 1,
        NotAuthorized = 2
    }

    /// <summary>
    /// Classe per l'accesso alle policy dell'applicazione
    /// </summary>
    abstract class AuthorizationManager_Base : ISecurityManager
    {

        #region Membri privati di classe
        /// <summary>
        /// Indica l'eventuale schema del database organigramma per richiamare le stored procedure sotto schema
        /// </summary>
        protected string m_sSchemaName = "";
        protected string m_strConnString = "";
        protected string m_sUsername = "";
        protected string m_sDisplayname = "";
        protected string m_IDApplication = "";
        protected string m_DBSecurityType = "";
        protected string m_sEmail = "";
        protected string m_nIDUtente = "";
        protected int m_nIDServizio = 0;
        protected bool m_bolLoggedIn = false;
        protected bool m_bolCacheEnabled = false;
        protected int m_CacheExpireDelay = 5;
        #endregion

        #region Costruttori
        #endregion

        #region BASE CLASS METHODS
        /// <summary>
        /// Questa property restituisce true se si stà utilizzando l'autenticazione integrata di Windows.
        /// <para/>In caso di autenticazione tramite Login verrà restituito false
        /// </summary>
        /// <returns>
        ///     True se si utilizza l'Autenticazione integrata<para/>
        ///     False se si utilizza l'Autenticazione tramite login
        /// </returns>
        public bool IsIntegratedAuthentication
        {
            get
            {
                if ((m_DBSecurityType == "DBAZMDOMAIN") || (m_DBSecurityType == "DBAZMSERVICE"))
                    return true;
                else
                    return false;
            }
        }

        /// <summary>
        /// Restituisce l'eventuale schema del database per il richiamo delle stored procedure
        /// </summary>
        public string SchemaName
        {
            get
            {
                return m_sSchemaName.Trim();
            }
            set
            {
                m_sSchemaName = value;
            }
        }

        /// <summary>
        /// Restituisce l'eventuale schema del database più l'eventuale punto per il richiamo delle stored procedure
        /// </summary>
        public string SchemaNameAndDot
        {
            get
            {
                if (this.SchemaName.Trim() == "")
                    return "";
                else
                    return m_sSchemaName.Trim() + ".";
            }
        }

        public abstract bool IsExternalAuthenticationEnabled { get; }
        public abstract string ExternalAuthChallangeUrl { get; }



        /// <summary>
        /// This method will set the information about the cache for the operation.
        /// if the called decided to use cache, this method will inform the code to use that and
        /// it will update the expire time for this cache. If the user does not supply a valid
        /// delay for the expire time, 5 minutes will be used.
        /// </summary>
        /// <param name="value">True in order to use cache or no to exclude cache</param>
        /// <param name="ExpireDelay">Expire time in minutes</param>
        public void IsCacheEnabled(Boolean value, int ExpireDelay)
        {
            m_bolCacheEnabled = value;
            m_CacheExpireDelay = ExpireDelay > 0 ? ExpireDelay : 5;
        }

        /// <summary>
        /// This method will set the information about the cache for the operation.
        /// if the called decided to use cache, this method will inform the code to use that and
        /// it will update the expire time for this cache. If the user does not supply a valid
        /// delay for the expire time, 5 minutes will be used.
        /// </summary>
        /// <param name="value">True in order to use cache or no to exclude cache</param>
        /// <param name="ExpireDelay">Expire time in minutes</param>
        public void IsCacheEnabled(Boolean value, string ExpireDelay)
        {
            int minutes = 0;
            m_bolCacheEnabled = value;
            m_CacheExpireDelay = int.TryParse(ExpireDelay, out minutes) ? minutes : 5;
        }

        /// <summary>
        /// This method will remove all entry keys from the application cache. 
        /// Of course it will removed only the keys connected to the current user
        /// </summary>
        /// <returns>True if the remove operation has been completed without problems otherwise no</returns>
        public bool RemoveCache()
        {
            bool retValue = false;
            try
            {
                foreach (DictionaryEntry EntryValue in HttpContext.Current.Cache)
                {
                    if (EntryValue.Key.ToString().Contains(m_sUsername))
                    {
                        HttpContext.Current.Cache.Remove(EntryValue.Key.ToString());
                    }
                }
                retValue = true;
            }
            catch (Exception Ex)
            {
                retValue = false;
            }
            return retValue;
        }

        public bool CambioPassword(string idUtente, string username, string newPassword, bool Reset)
        {

            SqlConnection con = Data.DBHelper.OpenConnection(m_strConnString);

            SqlParameter[] par = new SqlParameter[4];
            par[0] = new SqlParameter("@nIDUser", idUtente == null ? m_nIDUtente : idUtente);
            par[1] = new SqlParameter("@strUserLogin", username == null ? m_sUsername : username);
            par[2] = new SqlParameter("@NewPassword", newPassword);
            par[3] = new SqlParameter("@Reset", Reset == true ? 1 : 0);

            Data.DBHelper.ExecuteStoredProcedure(con, this.SchemaNameAndDot + "spAuth_CambioPassword", null, par);

            Data.DBHelper.ReleaseConnection(con);

            return true;
        }

        public System.Data.DataTable RoleUsers(string strRoleName)
        {
            SqlConnection con = Data.DBHelper.OpenConnection(m_strConnString);
            SqlParameter[] par = new SqlParameter[2];
            par[0] = new SqlParameter("@sIDApplication", m_IDApplication);
            par[1] = new SqlParameter("@sIDRole", strRoleName);

            DataTable dtUsers = Data.DBHelper.GetDataTableFormStoredProcedure(con, this.SchemaNameAndDot + "spAuth_RoleUsers", "tblUtente", par);
            Data.DBHelper.ReleaseConnection(con);
            return dtUsers;
        }

        public System.Data.DataTable UsersList(string idUtente)
        {
            SqlConnection con = Data.DBHelper.OpenConnection(m_strConnString);

            SqlParameter[] par = new SqlParameter[1];
            par[0] = new SqlParameter("@idUtente", idUtente);

            DataTable dtUsers = Data.DBHelper.GetDataTableFormStoredProcedure(con, this.SchemaNameAndDot + "spAuth_GetUsersList", "tblUtente", par);
            Data.DBHelper.ReleaseConnection(con);
            return dtUsers;
        }

        public Organigramma.UserDetails UtenteInformation(string UserLogin)
        {
            SqlConnection con = Data.DBHelper.OpenConnection(m_strConnString);

            SqlParameter[] par = new SqlParameter[1];
            par[0] = new SqlParameter("@strUserLogin", UserLogin);

            DataTable dtUsers = Data.DBHelper.GetDataTableFormStoredProcedure(con, this.SchemaNameAndDot + "spAuth_GetUsersInfo_ByLogin", "tblUtente", par);
            Data.DBHelper.ReleaseConnection(con);

            Organigramma.UserDetails Detail = dtUsers.AsEnumerable()
                                                .Select(item => new Organigramma.UserDetails {
                                                    IdUtente = Convert.ToString(item["IdUtente"]),
                                                    DisplayName = Convert.ToString(item["UserName"]),
                                                    Surname = Convert.ToString(item["Cognome"]),
                                                    Name = Convert.ToString(item["Nome"]),
                                                    Email = Convert.ToString(item["Email"]),
                                                    Telephone = Convert.ToString(item["NumeroTelefono"])
                                                }).FirstOrDefault();

            return Detail;
        }

        public Organigramma.UserDetails UtenteInformation(string UserLogin, bool bIncludeDisabled = false)
        {
            SqlConnection con = Data.DBHelper.OpenConnection(m_strConnString);

            SqlParameter[] par = new SqlParameter[2];
            par[0] = new SqlParameter("@strUserLogin", UserLogin);
            par[1] = new SqlParameter("@bIncludeDisabled ", bIncludeDisabled);

            DataTable dtUsers = Data.DBHelper.GetDataTableFormStoredProcedure(con, this.SchemaNameAndDot + "spAuth_GetUsersInfo_ByLoginExtended", "tblUtente", par);
            Data.DBHelper.ReleaseConnection(con);

            Organigramma.UserDetails Detail = dtUsers.AsEnumerable()
                                                .Select(item => new Organigramma.UserDetails
                                                {
                                                    IdUtente = Convert.ToString(item["IdUtente"]),
                                                    DisplayName = Convert.ToString(item["UserName"]),
                                                    Surname = Convert.ToString(item["Cognome"]),
                                                    Name = Convert.ToString(item["Nome"]),
                                                    Email = Convert.ToString(item["Email"]),
                                                    Telephone = Convert.ToString(item["NumeroTelefono"])
                                                }).FirstOrDefault();

            return Detail;
        }

        public bool Login(string strUsername, string strPassword)
        {
            return (AuthenticationPolicy.LoginResults)(LoginWithResult(strUsername, strPassword)) == AuthenticationPolicy.LoginResults.LoginOK;
        }

        public int LoginWithResult(string strUsername, string strPassword)
        {

            SqlConnection con = Data.DBHelper.OpenConnection(m_strConnString);

            SqlParameter[] par = new SqlParameter[2];
            par[0] = new SqlParameter("@sUsername", strUsername);
            par[1] = new SqlParameter("@sPassword", Security.AuthenticationPolicy.Sha512Encrypt(strPassword));

            DataTable dtUser = Data.DBHelper.GetDataTableFormStoredProcedure(con, this.SchemaNameAndDot + "spAuth_Login", "tblUtente", par);
            m_bolLoggedIn = ((AuthenticationPolicy.LoginResults)(dtUser.Rows[0]["Esito"]) == AuthenticationPolicy.LoginResults.LoginOK);
            if (m_bolLoggedIn)
            {
                m_sUsername = strUsername;
                if (dtUser.Rows[0]["Nome Utente"] != null)
                {
                    m_sDisplayname = Convert.ToString(dtUser.Rows[0]["Nome Utente"]);
                }
                if (dtUser.Rows[0]["email"] != null)
                {
                    m_sEmail = Convert.ToString(dtUser.Rows[0]["email"]);
                }
                if (dtUser.Rows[0]["idUtente"] != null)
                {
                    m_nIDUtente = Convert.ToString(dtUser.Rows[0]["idUtente"]);
                }

                DataTable dtServizio = Data.DBHelper.GetDataTableFormStoredProcedure(con, this.SchemaNameAndDot + "spAuth_GetIDServizio", "tblServizio",
                new SqlParameter[]{
                        new SqlParameter("@nIDUtente", m_nIDUtente)
                    });
                if (dtServizio.Rows[0]["idStruttura"] != null)
                {
                    m_nIDServizio = Convert.ToInt16(dtServizio.Rows[0]["idStruttura"]);
                }
            }
            Data.DBHelper.ReleaseConnection(con);
            return Convert.ToInt16(dtUser.Rows[0]["Esito"]);
        }

        public string UserDisplayName(string UserParameter, UserData UserData)
        {
            if (!IsLogged())
                return string.Empty;

            SqlConnection con = Data.DBHelper.OpenConnection(m_strConnString);
            SqlParameter[] par = new SqlParameter[2];
            par[0] = new SqlParameter("@nIDUser", UserData == UserData.UserId ? UserParameter : null);
            par[1] = new SqlParameter("@strUserLogin", UserData == UserData.UserLogin ? UserParameter : null);

            DataTable dtUsers = Data.DBHelper.GetDataTableFormStoredProcedure(con, this.SchemaNameAndDot + "spAuth_UserFullName", "tblUtenti", par);
            Data.DBHelper.ReleaseConnection(con);
            if (dtUsers.Rows.Count > 0)
            {
                if (dtUsers.Rows[0]["Nome Utente"] != null)
                    return Convert.ToString(dtUsers.Rows[0]["Nome Utente"]);
                else
                    return m_sUsername;
            }
            else
                return m_sUsername;
        }

        public string UserDisplayName()
        {
            return UserDisplayName(m_sUsername, UserData.UserLogin);
        }

        public string Username()
        {
            return m_sUsername;
        }

        public string Email()
        {
            return m_sEmail;
        }

        public string IDUtente()
        {
            return m_nIDUtente;
        }

        public int IDServizio()
        {
            return m_nIDServizio;
        }

        public string IDApplicazione()
        {
            return m_IDApplication;
        }

        public bool AddRoleUser(int nIDUser, string sIDRole)
        {
            SqlConnection con = null;
            try
            {
                con = Data.DBHelper.OpenConnection(m_strConnString);

                SqlParameter[] par = new SqlParameter[4];
                par[0] = new SqlParameter("@sIDApplication", m_IDApplication);
                par[1] = new SqlParameter("@sIDRole", sIDRole);
                par[2] = new SqlParameter("@nIDUser", nIDUser);
                par[3] = new SqlParameter("@retValue", 0);
                par[3].Direction = ParameterDirection.ReturnValue;

                Data.DBHelper.ExecuteStoredProcedure(con, this.SchemaNameAndDot + "spAuth_RoleUser_Add", null, par);

                if (Convert.ToInt32(par[3].Value) > 0)
                {
                    return true;
                }
                else
                {
                    return false;
                }

            }
            catch (Exception Ex)
            {
                return false;
            }
            finally
            {
                Data.DBHelper.ReleaseConnection(con);
            }
        }

        public bool RemoveRoleUser(int nIDUser)
        {
            SqlConnection con = null;
            try
            {
                con = Data.DBHelper.OpenConnection(m_strConnString);

                SqlParameter[] par = new SqlParameter[2];
                par[0] = new SqlParameter("@nIDUser", nIDUser);
                par[1] = new SqlParameter("@retValue", 0);
                par[1].Direction = ParameterDirection.ReturnValue;

                Data.DBHelper.ExecuteStoredProcedure(con, this.SchemaNameAndDot + "spAuth_RoleUser_Del", null, par);

                return true;
            }
            catch (Exception Ex)
            {
                return false;
            }
            finally
            {
                Data.DBHelper.ReleaseConnection(con);
            }
        }

        public DataTable GelRolesApplication(int IDUser)
        {
            SqlConnection con = Data.DBHelper.OpenConnection(m_strConnString);

            SqlParameter[] par = new SqlParameter[2];
            par[0] = new SqlParameter("@IdUser", IDUser);
            par[1] = new SqlParameter("@IdApplication", m_IDApplication);

            DataTable dtRolesApplication = Data.DBHelper.GetDataTableFormStoredProcedure(con, this.SchemaNameAndDot + "spAuth_Roles_SelAll", "tblRoles", par);
            Data.DBHelper.ReleaseConnection(con);
            return dtRolesApplication;
        }

        public DataTable GetRuoliFasi()
        {
            SqlConnection con = Data.DBHelper.OpenConnection(m_strConnString);

            DataTable dtFasi = Data.DBHelper.GetDataTableFormStoredProcedure(con, this.SchemaNameAndDot + "sp_Get_Fasi", "tblFasi", null);
            Data.DBHelper.ReleaseConnection(con);
            return dtFasi;
        }

        public DataTable GetListaUtenti(bool JustActive = true)
        {
            SqlConnection con = Data.DBHelper.OpenConnection(m_strConnString);

            DataTable dtFasi = Data.DBHelper.GetDataTableFormStoredProcedure(con, this.SchemaNameAndDot + "sp_GetElencoUtenti", "tblUtenti", null);
            Data.DBHelper.ReleaseConnection(con);
            return dtFasi;
        }

        public IRoleUserCollection GetRoleCollection(Nullable<int> IdUser)
        {

            RoleUserCollection RoleUserCollection = new RoleUserCollection(this);
            if (IdUser != null)
            {
                RoleUserCollection.IdUser = (int)IdUser;
            }
            RoleUserCollection.Read();
            return RoleUserCollection;
        }
        #endregion BASE CLASS METHODS

        #region OVERRIDABLE CLASS METHODS
        public abstract BPLG.Security.AuthenticationPolicy.PasswordCheck IsPasswordValid(string username, string password, int? minLength, AuthenticationPolicy.PasswordRules rules, params string[] ruleOutList);

        /// <summary>
        /// Verifica il periodo di scadenza password è trascorso
        /// </summary>
        /// <returns></returns>
        public abstract bool IsPasswordScaduta();

        public abstract bool HasPermission(string strOperation, string UserParameter, UserData UserData);

        public abstract bool HasPermission(string strOperation, bool UseRealname = false);

        public abstract bool HasPermission(string[] strOperation, bool UseRealname = false);

        public abstract bool IsLogged();

        public abstract UserLoggedStatus LoggedStatus();

        public abstract ISecurityManager GetInstance();

        public abstract string RealUsername();

        public abstract void ForceImpersonate(string UserName);

        #endregion OVERRIDABLE CLASS METHODS

    }
}
