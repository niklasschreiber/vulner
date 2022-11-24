using System;
using System.Collections.Generic;
using System.Text;
using System.Data;
using System.Data.SqlClient;
using System.Security.Cryptography;
using System.Web;
using System.Web.Caching;
using System.Collections;
using BPLG.CryptoService;
using System.Configuration;
using System.Net;
using System.IO;

namespace BPLG.Security
{
    /// <summary>
    /// Classe per l'accesso alle policy dell'applicazione
    /// </summary>
    class CKAuthorizationManager : AuthorizationManager_Base
    {
        #region Costruttori
        /// <summary>
        /// This is the ctor for this class. In this ctor it will be initialized some parameter (located in the
        /// base class) and it will be check if the user is already capable to be authenticated
        /// </summary>
        /// <param name="dbSecurityType">Type of security choosen. In this case it will always be DBAMZCACHE</param>
        /// <param name="strConnString">The connection string for the database in which the code will look for users</param>
        /// <param name="idApplication">Application's name</param>
        /// <param name="username">Username that will be used for query the database</param>
        /// <param name="sSchemaName">Default schema for stored procedure</param>
        public CKAuthorizationManager(string dbSecurityType, string strConnString, string idApplication, string username, string sSchemaName)
        {
            m_strConnString = strConnString;
            m_IDApplication = idApplication;
            m_DBSecurityType = dbSecurityType;
            m_sSchemaName = sSchemaName;

            IsLogged();
        }

        /// <summary>
        /// This is just a redirect to the full ctor. in this case default schema it's filled with empty space
        /// </summary>
        /// <param name="dbSecurityType">Type of security choosen. In this case it will always be DBAMZCACHE</param>
        /// <param name="strConnString">The connection string for the database in which the code will look for users</param>
        /// <param name="idApplication">Application's name</param>
        /// <param name="username">Username that will be used for query the database</param>
        public CKAuthorizationManager(string dbSecurityType, string strConnString, string idApplication, string username)
            : this(dbSecurityType, strConnString, idApplication, username, "")
        {
        }

        /// <summary>
        /// Another overload of the full ctor in which the caller doesn't need to supply any username. In this case
        /// almost surely, the username will be retrieved by the domain cookie storen inside the client machine.
        /// </summary>
        /// <param name="dbSecurityType">Type of security choosen. In this case it will always be DBAMZCACHE</param>
        /// <param name="strConnString">The connection string for the database in which the code will look for users</param>
        /// <param name="idApplication">Application's name</param>
        public CKAuthorizationManager(string dbSecurityType, string strConnString, string idApplication)
        {
            m_strConnString = strConnString;
            m_IDApplication = idApplication;
            m_DBSecurityType = dbSecurityType;

            IsLogged();
        }

        #endregion

        /// <summary>
        /// This method is in charge to validate the password. Particurally, it will be check the lenght and the password content
        /// </summary>
        /// <param name="username">The user password's owner</param>
        /// <param name="password">new password choosen</param>
        /// <param name="minLength"></param>
        /// <param name="rules"></param>
        /// <param name="ruleOutList"></param>
        /// <returns>An AuthenticationPolicy result</returns>
        public override sealed BPLG.Security.AuthenticationPolicy.PasswordCheck IsPasswordValid(string username, string password, int? minLength, AuthenticationPolicy.PasswordRules rules, params string[] ruleOutList)
        {
            bool result = true;
            int nMinLen = 8;

            const string lower = "abcdefghijklmnopqrstuvwxyz";
            const string upper = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
            const string digits = "0123456789";
            string allChars = lower + upper + digits;



            if (minLength == null)
            {
                SqlConnection con = Data.DBHelper.OpenConnection(m_strConnString);
                DataTable dtPollicy = Data.DBHelper.GetDataTableFormStoredProcedure(con, this.SchemaNameAndDot + "spAuth_GetPolicy", "tblAuth_Policy", null);
                Data.DBHelper.ReleaseConnection(con);

                if (dtPollicy.Rows.Count > 0)
                {
                    if (dtPollicy.Rows[0]["nPwdMinLength"] != null)
                    {
                        nMinLen = Convert.ToInt16(dtPollicy.Rows[0]["nPwdMinLength"]);
                    }
                }
            }
            else
                nMinLen = (int)minLength;

            // Check password length
            if (password.Length < nMinLen)
            {
                result = false;
            }

            //Check Lowercase if rule is enforced
            if (Convert.ToBoolean(rules & AuthenticationPolicy.PasswordRules.LowerCase))
            {
                result &= (password.IndexOfAny(lower.ToCharArray()) >= 0);
            }
            //Check Uppercase if rule is enforced
            if (Convert.ToBoolean(rules & AuthenticationPolicy.PasswordRules.UpperCase))
            {
                result &= (password.IndexOfAny(upper.ToCharArray()) >= 0);
            }
            //Check to for a digit in password if digit is required
            if (Convert.ToBoolean(rules & AuthenticationPolicy.PasswordRules.Digit))
            {
                result &= (password.IndexOfAny(digits.ToCharArray()) >= 0);
            }
            //Check to make sure special character is included if required
            if (Convert.ToBoolean(rules & AuthenticationPolicy.PasswordRules.SpecialChar))
            {
                result &= (password.Trim(allChars.ToCharArray()).Length > 0);
            }

            if (!result)
            {
                return Security.AuthenticationPolicy.PasswordCheck.WrongComplexity;
            }

            if (ruleOutList != null)
            {

                for (int i = 0; i < ruleOutList.Length; i++)
                    result &= (password != ruleOutList[i]);
            }
            else
            {
                if (m_DBSecurityType == "DBAZMLOGIN")
                {
                    SqlConnection con = Data.DBHelper.OpenConnection(m_strConnString);

                    SqlParameter[] par = new SqlParameter[3];
                    par[0] = new SqlParameter("@nIDUser", null);
                    par[1] = new SqlParameter("@strUserLogin", m_sUsername != "" ? m_sUsername : username);
                    par[2] = new SqlParameter("@NewPassword", Security.AuthenticationPolicy.Sha512Encrypt(password));

                    DataTable dt = Data.DBHelper.GetDataTableFormStoredProcedure(con, this.SchemaNameAndDot + "spAuth_CheckPasswordUsed", "tblUtente", par);
                    Data.DBHelper.ReleaseConnection(con);
                    if (Convert.ToInt16(dt.Rows[0]["PasswordUsed"]) == 1)
                        result = false;
                    else
                        result = true;
                }
            }

            if (result)
            {
                return Security.AuthenticationPolicy.PasswordCheck.OK;
            }
            else
            {
                return Security.AuthenticationPolicy.PasswordCheck.WrongAlreadyUsed;
            }
        }

        /// <summary>
        /// Verifica il periodo di scadenza password è trascorso
        /// </summary>
        /// <returns></returns>
        public override sealed bool IsPasswordScaduta()
        {
            if (m_DBSecurityType == "DBAZMLOGIN")
            {
                SqlConnection con = Data.DBHelper.OpenConnection(m_strConnString);

                SqlParameter[] par = new SqlParameter[2];
                par[0] = new SqlParameter("@nIDUser", null);
                par[1] = new SqlParameter("@strUserLogin", m_sUsername);

                DataTable dtPwdScaduta = Data.DBHelper.GetDataTableFormStoredProcedure(con, this.SchemaNameAndDot + "spAuth_PasswordScaduta", "tblUtente", par);
                Data.DBHelper.ReleaseConnection(con);
                return (Convert.ToInt16(dtPwdScaduta.Rows[0]["PasswordScaduta"]) == 1 ? true : false);
            }
            else
            {
                return false;
            }
        }

        /// <summary>
        /// This method will check if the user is allow to use the operation supplied as parameter. This method will be used
        /// to let developer to show some features based on role operations
        /// </summary>
        /// <param name="strOperation">Operation's name requested</param>
        /// <param name="UserParameter">Username of the connected user</param>
        /// <param name="UserData">Enumeration to inform code if Username or UserId has to be used</param>
        /// <returns>True if user is enabled to this operation, otherwise false</returns>
        public override sealed bool HasPermission(string strOperation, string UserParameter, UserData UserData)
        {
            if ((m_DBSecurityType == "DBAZMLOGIN") && (!m_bolLoggedIn))
                return false;
            else
            {
                if ((HttpContext.Current.Cache[m_sUsername + "|" + strOperation] == null) || (!m_bolCacheEnabled))
                {
                    SqlConnection con = Data.DBHelper.OpenConnection(m_strConnString);

                    SqlParameter[] par = new SqlParameter[5];
                    par[0] = new SqlParameter("@sIDApplication", m_IDApplication);
                    par[1] = new SqlParameter("@sIDOperation", strOperation);
                    par[2] = new SqlParameter("@nIDUser", UserData == UserData.UserId ? UserParameter : null);
                    par[3] = new SqlParameter("@strUserLogin", UserData == UserData.UserLogin ? UserParameter : null);
                    par[4] = new SqlParameter("@Result", null);

                    par[4].DbType = DbType.Int16;
                    par[4].Direction = ParameterDirection.Output;

                    Data.DBHelper.ExecuteStoredProcedure(con, this.SchemaNameAndDot + "spAuth_HasPermission", null, par);
                    Data.DBHelper.ReleaseConnection(con);

                    if (m_bolCacheEnabled)
                    {
                        HttpContext.Current.Cache.Insert(
                                                m_sUsername + "|" + strOperation,
                                                Convert.ToBoolean(par[4].Value),
                                                null, DateTime.Now.AddMinutes(m_CacheExpireDelay), Cache.NoSlidingExpiration);
                    }
                    else
                    {
                        return Convert.ToBoolean(par[4].Value);
                    }
                }

                return (Convert.ToBoolean(HttpContext.Current.Cache[m_sUsername + "|" + strOperation]));
            }
        }

        /// <summary>
        /// This method will check if the user is allow to use the operation supplied as parameter. This method will be used
        /// to let developer to show some features based on role operations. This is an overload of the full method
        /// </summary>
        /// <param name="strOperation">Operation's name requested</param>
        /// <returns>True if user is enabled to this operation, otherwise false</returns>
        public override sealed bool HasPermission(string[] strOperation, bool UseRealname = false)
        {
            throw new Exception("Funzionalità non implementata");
        }

        /// <summary>
        /// This method will check if the user is allow to use the operation supplied as parameter. This method will be used
        /// to let developer to show some features based on role operations. This is an overload of the full method
        /// </summary>
        /// <param name="strOperation">Operation's name requested</param>
        /// <returns>True if user is enabled to this operation, otherwise false</returns>
        public override sealed bool HasPermission(string strOperation, bool UseRealname = false)
        {
            return HasPermission(strOperation, m_sUsername, UserData.UserLogin);
        }

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
                if (HttpContext.Current.Cache[m_sUsername + "|LoginSuccessful"] != null)
                {
                    return true;
                }
                else
                {
                    HttpCookie cookie = HttpContext.Current.Request.Cookies["AuthenticationPlanning"];
                    if (cookie != null)
                    {
                        m_sUsername = CryptoUtilities.Decrypt(cookie.Values["userLogged"].ToString());

                        if (m_DBSecurityType == "DBAZMCACHE")
                        {
                            SqlConnection con = Data.DBHelper.OpenConnection(m_strConnString);
                            SqlParameter[] par = new SqlParameter[1];
                            par[0] = new SqlParameter("@strUserLogin", m_sUsername);

                            DataTable dtUsers = Data.DBHelper.GetDataTableFormStoredProcedure(con, this.SchemaNameAndDot + "spAuth_GetIDUtente", "tblUtenti", par);
                            Data.DBHelper.ReleaseConnection(con);
                            if (dtUsers.Rows.Count > 0)
                            {
                                if (dtUsers.Rows[0]["ID"] != null)
                                {
                                    m_nIDUtente = dtUsers.Rows[0]["ID"].ToString();
                                }
                            }
                        }

                        HttpContext.Current.Cache.Insert(
                            m_sUsername + "|LoginSuccessful",
                            true,
                            null, DateTime.Now.AddMinutes(30), Cache.NoSlidingExpiration);

                        return true;
                    }
                    else
                    {
                        if (string.IsNullOrEmpty((ConfigurationManager.AppSettings.Get("ContentPortal"))))
                        {
                            throw new Exception("[MANAGED] - Impossible to authenticate user. There is no portal for authentication configured");
                        }
                        return false;
                    }
                }
            }
            catch (Exception Ex)
            {
                throw Ex;
            }
        }

        public override sealed UserLoggedStatus LoggedStatus()
        {
            try
            {
                if (HttpContext.Current.Cache[m_sUsername + "|LoginSuccessful"] != null)
                {
                    return UserLoggedStatus.AlreadyLogged;
                }
                else
                {
                    HttpCookie cookie = HttpContext.Current.Request.Cookies["AuthenticationPlanning"];
                    if (cookie != null)
                    {
                        m_sUsername = CryptoUtilities.Decrypt(cookie.Values["userLogged"].ToString());

                        if (m_DBSecurityType == "DBAZMCACHE")
                        {
                            SqlConnection con = Data.DBHelper.OpenConnection(m_strConnString);
                            SqlParameter[] par = new SqlParameter[1];
                            par[0] = new SqlParameter("@strUserLogin", m_sUsername);

                            DataTable dtUsers = Data.DBHelper.GetDataTableFormStoredProcedure(con, this.SchemaNameAndDot + "spAuth_GetIDUtente", "tblUtenti", par);
                            Data.DBHelper.ReleaseConnection(con);
                            if (dtUsers.Rows.Count > 0)
                            {
                                if (dtUsers.Rows[0]["ID"] != null)
                                {
                                    m_nIDUtente = dtUsers.Rows[0]["ID"].ToString();
                                    if (string.IsNullOrEmpty(m_nIDUtente))
                                    {
                                        return UserLoggedStatus.NotAuthorized;
                                    }
                                }
                            }
                        }

                        HttpContext.Current.Cache.Insert(
                            m_sUsername + "|LoginSuccessful",
                            true,
                            null, DateTime.Now.AddMinutes(30), Cache.NoSlidingExpiration);

                        return UserLoggedStatus.AlreadyLogged;
                    }
                    else
                    {
                        if (string.IsNullOrEmpty((ConfigurationManager.AppSettings.Get("ContentPortal"))))
                        {
                            throw new Exception("[MANAGED] - Impossible to authenticate user. There is no portal for authentication configured");
                        }
                        return UserLoggedStatus.NotLogged;
                    }
                }
            }
            catch (Exception Ex)
            {
                throw Ex;
            }
        }

        /// <summary>
        /// This metjod will just supply this specific instance to the caller
        /// </summary>
        /// <returns></returns>
        public override sealed ISecurityManager GetInstance()
        {
            return this;
        }

        public override sealed string RealUsername()
        {
            return m_sUsername;
        }

        public override sealed void ForceImpersonate(string UserName)
        {
            //m_sUsername = UserName;
        }

        public override bool IsExternalAuthenticationEnabled
        {
            get
            {
                return false;
            }
        }

        public override string ExternalAuthChallangeUrl
        {
            get
            {
                return string.Empty;
            }
        }
    }
}
