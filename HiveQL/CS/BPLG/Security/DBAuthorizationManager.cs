using System;
using System.Collections.Generic;
using System.Text;
using System.Data;
using System.Data.SqlClient;
using System.Security.Cryptography;
using System.Web;
using System.Web.Caching;
using System.Collections;

namespace BPLG.Security
{
    /// <summary>
    /// Classe per l'accesso alle policy dell'applicazione
    /// </summary>
    class DBAuthorizationManager : AuthorizationManager_Base
    {
        #region Costruttori

        private string m_RealUsername = string.Empty;

        public DBAuthorizationManager(string dbSecurityType, string strConnString, string idApplication, string username, string sSchemaName)
        {
            m_strConnString = strConnString;
            m_IDApplication = idApplication;
            m_sUsername = username;
            m_RealUsername = username;
            m_DBSecurityType = dbSecurityType;
            m_sSchemaName = sSchemaName;

            if ((m_DBSecurityType == "DBAZMDOMAIN") || (m_DBSecurityType == "DBAZMSERVICE"))
            {
                SqlConnection con = Data.DBHelper.OpenConnection(m_strConnString);
                SqlParameter[] par = new SqlParameter[1];
                par[0] = new SqlParameter("@strUserLogin", m_sUsername);

                DataTable dtUsers = Data.DBHelper.GetDataTableFormStoredProcedure(con, this.SchemaNameAndDot + "spAuth_GetIDUtente", "tblUtenti", par);
                
                if (dtUsers.Rows.Count > 0)
                {
                    if (dtUsers.Rows[0]["ID"] != null)
                    {
                        m_nIDUtente = dtUsers.Rows[0]["ID"].ToString();
                    }
                }

                DataTable dtServizio = Data.DBHelper.GetDataTableFormStoredProcedure(con, this.SchemaNameAndDot + "spAuth_GetIDServizio", "tblServizio",
                    new SqlParameter[]{
                        new SqlParameter("@nIDUtente", m_nIDUtente)
                    });

                if (dtServizio.Rows.Count > 0)
                {
                    if (dtServizio.Rows[0]["idStruttura"] != null)
                    {
                        m_nIDServizio = Convert.ToInt16(dtServizio.Rows[0]["idStruttura"]);
                    }
                }
                
                Data.DBHelper.ReleaseConnection(con);
            }
        }

        public DBAuthorizationManager(string dbSecurityType, string strConnString, string idApplication, string username)
            : this(dbSecurityType, strConnString, idApplication, username, "")
        {
        }

        public DBAuthorizationManager(string dbSecurityType, string strConnString, string idApplication)
        {
            m_strConnString = strConnString;
            m_IDApplication = idApplication;
            m_DBSecurityType = dbSecurityType;
        }

        #endregion

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

        public override sealed bool HasPermission(string strOperation, string UserParameter, UserData UserData)
        {
            if ((m_DBSecurityType == "DBAZMLOGIN") && (!m_bolLoggedIn))
                return false;
            else
            {
                if ((HttpContext.Current.Cache[UserParameter + "|" + strOperation] == null) || (!m_bolCacheEnabled))
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
                                                UserParameter + "|" + strOperation,
                                                Convert.ToBoolean(par[4].Value),
                                                null, DateTime.Now.AddMinutes(m_CacheExpireDelay), Cache.NoSlidingExpiration);
                    }
                    else
                    {
                        return Convert.ToBoolean(par[4].Value);
                    }
                }

                return (Convert.ToBoolean(HttpContext.Current.Cache[UserParameter + "|" + strOperation]));
            }
        }

        public override sealed bool HasPermission(string strOperation, bool UseRealname = false)
        {
            return HasPermission(strOperation, UseRealname ? m_RealUsername : m_sUsername, UserData.UserLogin);
        }

        public override sealed bool HasPermission(string[] strOperation, bool UseRealname = false)
        {
            if (strOperation.Length > 0)
            {
                bool result = false;
                for (int index = 0; index < strOperation.Length; ++index)
                {
                    if ((strOperation[index].Length > 0) && (HasPermission(strOperation[index], m_sUsername, UserData.UserLogin))) if ((strOperation[index].Length > 0) && (HasPermission(strOperation[index], UseRealname ? m_RealUsername : m_sUsername, UserData.UserLogin)))
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

        public override sealed bool IsLogged()
        {
            if ((m_DBSecurityType == "DBAZMDOMAIN") || (m_DBSecurityType == "DBAZMSERVICE"))
                return true;
            else
                return m_bolLoggedIn;
        }

        public override sealed UserLoggedStatus LoggedStatus()
        {
            if ((m_DBSecurityType == "DBAZMDOMAIN") || (m_DBSecurityType == "DBAZMSERVICE"))
                return UserLoggedStatus.AlreadyLogged;
            else
                return (m_bolLoggedIn) ? UserLoggedStatus.AlreadyLogged : UserLoggedStatus.NotLogged;
        }

        public override sealed ISecurityManager GetInstance()
        {
            return this;
        }

        public override sealed string RealUsername()
        {
            return m_RealUsername;
        }

        public override sealed void ForceImpersonate(string UserName)
        {
            m_sUsername = UserName;

            if ((m_DBSecurityType == "DBAZMDOMAIN") || (m_DBSecurityType == "DBAZMSERVICE"))
            {
                SqlConnection con = Data.DBHelper.OpenConnection(m_strConnString);
                SqlParameter[] par = new SqlParameter[1];
                par[0] = new SqlParameter("@strUserLogin", m_sUsername);

                DataTable dtUsers = Data.DBHelper.GetDataTableFormStoredProcedure(con, this.SchemaNameAndDot + "spAuth_GetIDUtente", "tblUtenti", par);

                if (dtUsers.Rows.Count > 0)
                {
                    if (dtUsers.Rows[0]["ID"] != null)
                    {
                        m_nIDUtente = dtUsers.Rows[0]["ID"].ToString();
                    }
                }

                DataTable dtServizio = Data.DBHelper.GetDataTableFormStoredProcedure(con, this.SchemaNameAndDot + "spAuth_GetIDServizio", "tblServizio",
                    new SqlParameter[]{
                        new SqlParameter("@nIDUtente", m_nIDUtente)
                    });

                if (dtServizio.Rows.Count > 0)
                {
                    if (dtServizio.Rows[0]["idStruttura"] != null)
                    {
                        m_nIDServizio = Convert.ToInt16(dtServizio.Rows[0]["idStruttura"]);
                    }
                }

                Data.DBHelper.ReleaseConnection(con);
            }
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
