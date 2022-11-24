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
using BPLG.Organigramma;
using System.Security.Claims;
using System.Web.Security;
using BPLG.CryptoService;

namespace BPLG.Security
{
    class DBAuthorizationManagerWithExternalIdp : ISecurityManager
    {
        private string _connectionString { get; set; }
        private string _idApplication { get; set; }
        private string _schemaName { get; set; }

        private string ImpersonatedUserCookieName
        {
            get
            {
                var tempName = string.Empty;

                if (string.IsNullOrEmpty(_idApplication))
                    tempName += "no_name_provided";
                else
                    tempName += _idApplication;

                tempName += "_imp_user";

                return tempName;
            }
        }

        #region Properties

        /// <summary>
        /// Restituisce L'id dell'utente. Se attiva l'impersonificazione, torna l'id
        /// dell'utente impersonato
        /// </summary>
        private string _userId;
        public string UserId
        {
            get
            {
                var tempValue = string.Empty;

                try
                {
                    // check impersonated user 
                    if (HttpContext.Current.Request.Cookies[ImpersonatedUserCookieName] != null
                        && HttpContext.Current.Request.Cookies[ImpersonatedUserCookieName].Value.ToString() != string.Empty)
                    {
                        var cookieValue = HttpContext.Current.Request.Cookies[ImpersonatedUserCookieName].Value.ToString();
                        // protect / decrypt cookie value
                        cookieValue = Encoding.UTF8.GetString(MachineKey.Unprotect(Convert.FromBase64String(cookieValue)));

                        var splittedValues = new List<string>(cookieValue.Split(','));
                        if (splittedValues != null && splittedValues.Any())
                        {
                            tempValue = splittedValues[1];
                        }

                        return tempValue;
                    }
                }
                catch { }
            
                return _userId;
            }
            set { _userId = value; }
        }


        /// <summary>
        /// Restituisce L'id del servizio dell'utente. Se attiva l'impersonificazione, torna l'id del servizio
        /// dell'utente impersonato
        /// </summary>
        private int _idServizio;
        public int IdServizio
        {
            get
            {
                var tempValue = 0;

                try
                {

                    // check impersonated user 
                    if (HttpContext.Current.Request.Cookies[ImpersonatedUserCookieName] != null
                        && HttpContext.Current.Request.Cookies[ImpersonatedUserCookieName].Value.ToString() != string.Empty)
                    {
                        var cookieValue = HttpContext.Current.Request.Cookies[ImpersonatedUserCookieName].Value.ToString();
                        // protect / decrypt cookie value
                        cookieValue = Encoding.UTF8.GetString(MachineKey.Unprotect(Convert.FromBase64String(cookieValue)));

                        var splittedValues = new List<string>(cookieValue.Split(','));
                        if (splittedValues != null && splittedValues.Any())
                        {
                            tempValue = Convert.ToInt32(splittedValues[2]);
                        }

                        return tempValue;
                    }
                }
                catch { }

                return _idServizio;
            }
            set { _idServizio = value; }
        }


        /// <summary>
        /// Restituisce l'eventuale schema del database per il richiamo delle stored procedure
        /// </summary>
        public string SchemaName
        {
            get
            {
                return _schemaName.Trim();
            }
            set
            {
                _schemaName = value;
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
                    return _schemaName.Trim() + ".";
            }
        }

        /// <summary>
        /// User Refog - From Claims
        /// </summary>
        public string UserRefog
        {
            get
            {
                if (!IsLogged())
                    return string.Empty;

                var tempValue = string.Empty;

                try
                {
                    // check impersonated user 
                    if (HttpContext.Current.Request.Cookies[ImpersonatedUserCookieName] != null
                        && HttpContext.Current.Request.Cookies[ImpersonatedUserCookieName].Value.ToString() != string.Empty)
                    {
                        var cookieValue = HttpContext.Current.Request.Cookies[ImpersonatedUserCookieName].Value.ToString();
                        // protect / decrypt cookie value
                        cookieValue = Encoding.UTF8.GetString(MachineKey.Unprotect(Convert.FromBase64String(cookieValue)));

                        var splittedValues = new List<string>(cookieValue.Split(','));
                        if (splittedValues != null && splittedValues.Any())
                        {
                            tempValue = splittedValues[0];
                        }

                        return tempValue;
                    }
                }
                catch
                {

                }

                // verifico se è presente l'attribute sUserRefog.
                // se lo trovo, ha priorità rispetto il NameIdentifier (application user id)
                var refogFromUserRefog = ReadValueFromClaims(WebssoITGClaimTypes.UserRefog);
                if (!string.IsNullOrEmpty(refogFromUserRefog))
                    return refogFromUserRefog;

                // verifico se è presente l'attributo di default (uid)
                refogFromUserRefog = ReadValueFromClaims(WebssoITGClaimTypes.UserRefogDefault);
                if (!string.IsNullOrEmpty(refogFromUserRefog))
                    return refogFromUserRefog;

                return ReadValueFromClaims(ClaimTypes.NameIdentifier);
            }
        }


        /// <summary>
        /// Username - Same as UserRefog
        /// </summary>
        public string UserName
        {
            get
            {
                return UserRefog;
            }
        }



        #endregion

        public DBAuthorizationManagerWithExternalIdp(string strConnString, string idApplication, string sSchemaName)
        {
            _connectionString = strConnString;
            _idApplication = idApplication;
            _schemaName = sSchemaName;

            if (!IsLogged())
                return;

            LoadUserDataFromOrganigramma();

        }

        private void LoadUserDataFromOrganigramma()
        {
            SqlConnection con = Data.DBHelper.OpenConnection(_connectionString);
            SqlParameter[] par = new SqlParameter[1];
            par[0] = new SqlParameter("@strUserLogin", Username());

            DataTable dtUsers = Data.DBHelper.GetDataTableFormStoredProcedure(con, this.SchemaNameAndDot + "spAuth_GetIDUtente", "tblUtenti", par);

            if (dtUsers.Rows.Count > 0)
            {
                if (dtUsers.Rows[0]["ID"] != null)
                {
                    UserId = dtUsers.Rows[0]["ID"].ToString();
                }
            }

            DataTable dtServizio = Data.DBHelper.GetDataTableFormStoredProcedure(con, this.SchemaNameAndDot + "spAuth_GetIDServizio", "tblServizio",
                new SqlParameter[]{
                    new SqlParameter("@nIDUtente", UserId)
                });

            if (dtServizio.Rows.Count > 0)
            {
                if (dtServizio.Rows[0]["idStruttura"] != null)
                {
                    _idServizio = Convert.ToInt16(dtServizio.Rows[0]["idStruttura"]);
                }
            }

            Data.DBHelper.ReleaseConnection(con);
        }

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
                return false;
            }
        }

        public bool IsExternalAuthenticationEnabled
        {
            get
            {
                return true;
            }
        }

        public string ExternalAuthChallangeUrl
        {
            get
            {
                return "~/Saml2/SignIn";
            }
        }

        public bool CambioPassword(string idUtente, string username, string newPassword, bool Reset)
        {
            var message = "Can't change password with WebSSO authentication on SP. Please change the password on IDP";

            throw new InvalidOperationException(message);
        }

        public string Email()
        {
            if (!IsLogged())
                return string.Empty;

            // verifico se è presente l'attribute sEmail.
            var sEmail = ReadValueFromClaims(WebssoITGClaimTypes.sEmail);
            if (!string.IsNullOrEmpty(sEmail))
                return sEmail;

            // se non è presente, verifico con il nome dell'attributo di default
            sEmail = ReadValueFromClaims(WebssoITGClaimTypes.sEmailDefault);
            if (!string.IsNullOrEmpty(sEmail))
                return sEmail;

            return string.Empty;
        }

        public void ForceImpersonate(string UserName)
        {
            if (!IsLogged())
                return;

            var strUserLogin = UserName;

            var impersonatedUserRefog = strUserLogin;
            var impersonatedUserId = string.Empty;
            var impersonatedIdServizio = 0;

            SqlConnection con = Data.DBHelper.OpenConnection(_connectionString);
            SqlParameter[] par = new SqlParameter[1];
            par[0] = new SqlParameter("@strUserLogin", strUserLogin);

            DataTable dtUsers = Data.DBHelper.GetDataTableFormStoredProcedure(con, this.SchemaNameAndDot + "spAuth_GetIDUtente", "tblUtenti", par);

            if (dtUsers.Rows.Count > 0)
            {
                if (dtUsers.Rows[0]["ID"] != null)
                {
                    impersonatedUserId = dtUsers.Rows[0]["ID"].ToString();
                }
            }

            DataTable dtServizio = Data.DBHelper.GetDataTableFormStoredProcedure(con, this.SchemaNameAndDot + "spAuth_GetIDServizio", "tblServizio",
                new SqlParameter[]{
                        new SqlParameter("@nIDUtente", impersonatedUserId)
                });

            if (dtServizio.Rows.Count > 0)
            {
                if (dtServizio.Rows[0]["idStruttura"] != null)
                {
                    impersonatedIdServizio = Convert.ToInt16(dtServizio.Rows[0]["idStruttura"]);
                }
            }

            if(!string.IsNullOrEmpty(impersonatedUserId) && impersonatedIdServizio > 0)
            {
                // save impersonated user info in cookies
                var cookieValue = string.Format("{0},{1},{2}", impersonatedUserRefog, impersonatedUserId, impersonatedIdServizio);

                // protect / encrypt cookie value
                cookieValue = Convert.ToBase64String(MachineKey.Protect(Encoding.UTF8.GetBytes(cookieValue)));

                HttpCookie cookie = new HttpCookie(ImpersonatedUserCookieName, cookieValue);
                cookie.Expires = DateTime.Now.AddHours(4);
                HttpContext.Current.Response.Cookies.Add(cookie);
            }

            Data.DBHelper.ReleaseConnection(con);
        }

        public ISecurityManager GetInstance()
        {
            return this;
        }

        public DataTable GetListaUtenti(bool JustActive = true)
        {
            // same implementatio of AuthorizationManager_Base

            SqlConnection con = Data.DBHelper.OpenConnection(_connectionString);

            DataTable dtFasi = Data.DBHelper.GetDataTableFormStoredProcedure(con, this.SchemaNameAndDot + "sp_GetElencoUtenti", "tblUtenti", null);
            Data.DBHelper.ReleaseConnection(con);
            return dtFasi;
        }

        public IRoleUserCollection GetRoleCollection(int? IdUser)
        {
            // same implementatio of AuthorizationManager_Base

            RoleUserCollection RoleUserCollection = new RoleUserCollection(this);
            if (IdUser != null)
            {
                RoleUserCollection.IdUser = (int)IdUser;
            }
            RoleUserCollection.Read();
            return RoleUserCollection;
        }

        public bool HasPermission(string[] strOperation, bool UseRealname = false)
        {
            if (strOperation.Length > 0)
            {
                bool result = false;

                var userRefog = UserRefog;
                var realUsername = RealUsername();

                for (int index = 0; index < strOperation.Length; ++index)
                {
                    if ((strOperation[index].Length > 0) && (HasPermission(strOperation[index], userRefog, UserData.UserLogin))) if ((strOperation[index].Length > 0) && (HasPermission(strOperation[index], UseRealname ? realUsername : userRefog, UserData.UserLogin)))
                    {
                        result = true;
                        break;
                    }
                }
                return result;
            }
            else
            {
                return false;
            }
            
        }

        public bool HasPermission(string strOperation, bool UseRealname = false)
        {
            if (!IsLogged())
                return false;

            return HasPermission(strOperation, UseRealname ? RealUsername() : UserRefog, UserData.UserLogin);
        }

        public bool HasPermission(string strOperation, string UserParameter, UserData UserData)
        {
            if (!IsLogged())
                return false;

            SqlConnection con = Data.DBHelper.OpenConnection(_connectionString);

            SqlParameter[] par = new SqlParameter[5];
            par[0] = new SqlParameter("@sIDApplication", _idApplication);
            par[1] = new SqlParameter("@sIDOperation", strOperation);
            par[2] = new SqlParameter("@nIDUser", UserData == UserData.UserId ? UserParameter : null);
            par[3] = new SqlParameter("@strUserLogin", UserData == UserData.UserLogin ? UserParameter : null);
            par[4] = new SqlParameter("@Result", null);

            par[4].DbType = DbType.Int16;
            par[4].Direction = ParameterDirection.Output;

            Data.DBHelper.ExecuteStoredProcedure(con, this.SchemaNameAndDot + "spAuth_HasPermission", null, par);
            Data.DBHelper.ReleaseConnection(con);

            return Convert.ToBoolean(par[4].Value);
        }

        public string IDApplicazione()
        {
            return _idApplication;
        }

        public int IDServizio()
        {
            // se richiedo l'id servizio ma ancora non l'ho caricato
            if (_idServizio <= 0)
            {
                LoadUserDataFromOrganigramma();
            }

            return _idServizio;

        }

        public string IDUtente()
        {

            // se richiedo l'id utente ma ancora non l'ho ricavato
            if(string.IsNullOrEmpty(UserId))
            {
                LoadUserDataFromOrganigramma();
            }

            return UserId;
        }

        public void IsCacheEnabled(bool value, int ExpireDelay)
        {
            // nothing
        }

        public void IsCacheEnabled(bool value, string ExpireDelay)
        {
            // nothing
        }

        /// <summary>
        /// Torna true se l'utente è loggato
        /// </summary>
        public bool IsLogged()
        {
            return HttpContext.Current.User.Identity.IsAuthenticated;
        }

        public bool IsPasswordScaduta()
        {
            var message = "Can't check password expiration with WebSSO authentication on SP. Please check password on IDP";

            throw new InvalidOperationException(message);
        }

        public AuthenticationPolicy.PasswordCheck IsPasswordValid(string username, string password, int? MinLength, AuthenticationPolicy.PasswordRules rules, params string[] ruleOutList)
        {
            var message = "Can't check password with WebSSO authentication on SP. Please check password on IDP";

            throw new InvalidOperationException(message);
        }

        /// <summary>
        /// Torna UserLoggedStatus.AlreadyLogged se l'utente è loggato,
        /// altrimenti UserLoggedStatus.NotLogged
        /// </summary>
        public UserLoggedStatus LoggedStatus()
        {
            return HttpContext.Current.User.Identity.IsAuthenticated ?
                UserLoggedStatus.AlreadyLogged :
                UserLoggedStatus.NotLogged;
        }


        public bool Login(string strUsername, string strPassword)
        {
            var message = "Can't login with WebSSO authentication on SP. Please login on IDP";

            throw new InvalidOperationException(message);
        }

        public int LoginWithResult(string strUsername, string strPassword)
        {
            var message = "Can't login with WebSSO authentication on SP. Please login on IDP";

            throw new InvalidOperationException(message);
        }

        public string RealUsername()
        {
            if (!IsLogged())
                return string.Empty;

            // verifico se è presente l'attribute sUserRefog.
            // se lo trovo, ha priorità rispetto il NameIdentifier (application user id)
            var refogFromUserRefog = ReadValueFromClaims(WebssoITGClaimTypes.UserRefog);
            if (!string.IsNullOrEmpty(refogFromUserRefog))
                return refogFromUserRefog;

            // verifico se è presente l'attributo di default (uid)
            refogFromUserRefog = ReadValueFromClaims(WebssoITGClaimTypes.UserRefogDefault);
            if (!string.IsNullOrEmpty(refogFromUserRefog))
                return refogFromUserRefog;

            return ReadValueFromClaims(ClaimTypes.NameIdentifier);
        }

        public bool RemoveCache()
        {
            throw new NotImplementedException();
        }

        public DataTable RoleUsers(string strRoleName)
        {
            // same implementatio of AuthorizationManager_Base

            SqlConnection con = Data.DBHelper.OpenConnection(_connectionString);
            SqlParameter[] par = new SqlParameter[2];
            par[0] = new SqlParameter("@sIDApplication", _idApplication);
            par[1] = new SqlParameter("@sIDRole", strRoleName);

            DataTable dtUsers = Data.DBHelper.GetDataTableFormStoredProcedure(con, this.SchemaNameAndDot + "spAuth_RoleUsers", "tblUtente", par);
            Data.DBHelper.ReleaseConnection(con);
            return dtUsers;
        }

        public string UserDisplayName()
        {
            if (!IsLogged()) 
                return string.Empty;

            return UserDisplayName(UserName, UserData.UserLogin);
        }

        public string UserDisplayName(string UserParameter, UserData UserData)
        {
            if (!IsLogged())
                return string.Empty;

            SqlConnection con = Data.DBHelper.OpenConnection(_connectionString);
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
                    return UserName;
            }
            else
            {
                // try to get values from claims
                var displayName = ReadValueFromClaims(WebssoITGClaimTypes.DisplayName);

                if (string.IsNullOrWhiteSpace(displayName))
                {
                    // verifico se è presente l'attribute DisplayName di default.
                    displayName = ReadValueFromClaims(WebssoITGClaimTypes.DisplayNameDefault);
                    if (!string.IsNullOrWhiteSpace(displayName))
                        return displayName;
                }

                displayName += string.Format(" ({0})", UserRefog);

                return displayName;
            }
        }

        public string Username()
        {
            return UserName;
        }

        public DataTable UsersList(string idUtente)
        {
            // same implementatio of AuthorizationManager_Base

            SqlConnection con = Data.DBHelper.OpenConnection(_connectionString);

            SqlParameter[] par = new SqlParameter[1];
            par[0] = new SqlParameter("@idUtente", idUtente);

            DataTable dtUsers = Data.DBHelper.GetDataTableFormStoredProcedure(con, this.SchemaNameAndDot + "spAuth_GetUsersList", "tblUtente", par);
            Data.DBHelper.ReleaseConnection(con);
            return dtUsers;
        }

        public UserDetails UtenteInformation(string UserLogin)
        {
            // same implementatio of AuthorizationManager_Base

            SqlConnection con = Data.DBHelper.OpenConnection(_connectionString);

            SqlParameter[] par = new SqlParameter[1];
            par[0] = new SqlParameter("@strUserLogin", UserLogin);

            DataTable dtUsers = Data.DBHelper.GetDataTableFormStoredProcedure(con, this.SchemaNameAndDot + "spAuth_GetUsersInfo_ByLogin", "tblUtente", par);
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

        public UserDetails UtenteInformation(string UserLogin, bool bIncludeDisabled = false)
        {
            // same implementatio of AuthorizationManager_Base

            SqlConnection con = Data.DBHelper.OpenConnection(_connectionString);

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

        private string ReadValueFromClaims(string claimType)
        {
            if (!IsLogged())
                return string.Empty;

            var claimsIdentity = HttpContext.Current.User.Identity as ClaimsIdentity;
            var claim = claimsIdentity?.FindFirst(claimType);

            return claim?.Value ?? string.Empty;
        }


    }
}
