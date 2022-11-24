using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Text;
using System.Web;
using BPLG.Authentication;
using BPLG.CryptoService;

namespace BPLG.Authentication
{
    abstract class AuthenticationManager_Credential : AuthenticationManager_Cookieless
    {
        #region MEMBER
        protected bool m_bolLoggedIn = false;
        #endregion MEMBER

        #region METHODS
        /// <summary>
        /// Verifica il periodo di scadenza password è trascorso
        /// </summary>
        /// <returns></returns>
        public bool IsPasswordScaduta()
        {
            //SqlConnection con = Database.DBHelperCollection.Instance(m_strConnString).OpenConnection();

            SqlParameter[] par = new SqlParameter[2];
            par[0] = new SqlParameter("@nIDUser", null);
            par[1] = new SqlParameter("@strUserLogin", UserDetail.UserName);

            DataTable dtPwdScaduta = Database.DBHelper.GetDataTableFormStoredProcedure(RescueConnection(), "spAuth_PasswordScaduta", "tblUtente", par);
            
            return (Convert.ToInt16(dtPwdScaduta.Rows[0]["PasswordScaduta"]) == 1 ? true : false);
        }
        #endregion METHODS

        #region OVERRIDED METHODS
        /// <summary>
        /// Questo metodo si occupa di ritornare lo stato di Login dell'utente.
        /// Questo metodo si utilizza solo per la sezione di Login con user e password.
        /// Se venisse chiamata da un metodo con autenticazione integrata restituirebbe
        /// true senza fare controlli
        /// </summary>
        /// <param name="strUsername">UserName dell'utente</param>
        /// <param name="strPassword">Password selezionata dall'utente</param>
        /// <returns>Enumeration per indicare lo stato della Login</returns>
        public override AuthenticationPolicy.LoginResults LoginWithResult(string UserName, string Password, bool IsImpersonate = false)
        {
            AuthenticationPolicy.LoginResults LoginProcess = AuthenticationPolicy.LoginResults.NoOperation;
            try
            {
                SqlParameter retParam = new SqlParameter("@retValue", SqlDbType.Int);
                retParam.Direction = ParameterDirection.ReturnValue;

                SqlParameter[] par = new SqlParameter[] { 
                    new SqlParameter("@sLogin", UserName)
                    , new SqlParameter("@sPassword", Security.AuthenticationPolicy.Sha512Encrypt(Password))
                    , retParam
                };

                Database.DBHelper.ExecuteStoredProcedure(RescueConnection(), "[Autorizzazioni].[spLogin]", null, par);
                LoginProcess = (retParam.Value != DBNull.Value) ? (AuthenticationPolicy.LoginResults)((int)retParam.Value) : AuthenticationPolicy.LoginResults.LoginErrato;

                if (LoginProcess == AuthenticationPolicy.LoginResults.LoginOK)
                {
                    par = new SqlParameter[] { new SqlParameter("@sLogin", UserName) };
                    DataTable userInfo = Database.DBHelper.GetDataTableFormStoredProcedure(RescueConnection(), "[Autorizzazioni].[spUserInfo]", "ResultTable", par);
                    if ((userInfo != null) && (userInfo.Rows.Count == 1))
                    {
                        UserDetail.UserName = UserName;
                        UserDetail.DisplayName = Convert.ToString(userInfo.Rows[0]["sNomeCompleto"]);
                        UserDetail.IdUtente = Convert.ToString(userInfo.Rows[0]["nIdUtente"]);

                        if (IsImpersonate) 
                        {
                            RequestCookieCreation(true);
                        }
                        else
                        {
                            RequestCookieCreation();
                        }
                    }
                    else
                    {
                        LoginProcess = AuthenticationPolicy.LoginResults.WrongUserDetail;
                    }
                }
            }
            catch (Exception Ex)
            {
                LoginProcess = AuthenticationPolicy.LoginResults.LoginErrato;
            }
            finally
            {
                
            }
            return LoginProcess;
        }
        #endregion OVERRIDED METHODS
    }
}
