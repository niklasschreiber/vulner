using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Text;

namespace BPLG.Authentication
{
    abstract class AuthenticationManager_Cookieless : AuthenticationManager
    {
        #region PROPERTIES
        public bool IsIntegratedAthentication
        {
            get
            {
                return (m_DBSecurityType == "DBAZMDOMAIN");
            }
        }
        #endregion PROPERTIES

        #region OVERRIDABLE CLASS METHODS
        public override AuthenticationPolicy.LoginResults LoginWithResult(string strUsername, string strPassword, bool IsImpersonale = false)
        {
            throw new System.Security.Authentication.AuthenticationException("Impossibile utilizzare il Login con la gestione dell'autenticazione integrata");
        }

        public override AuthenticationPolicy.PasswordChange CambioPassword(string oldPassword, string newPassword)
        {
            AuthenticationPolicy.PasswordChange resultValue = AuthenticationPolicy.PasswordChange.EmptyResult;
            try
            {
                SqlParameter retParam = new SqlParameter("@retValue", SqlDbType.Int);
                retParam.Direction = ParameterDirection.ReturnValue;

                Database.DBHelper.ExecuteStoredProcedure(RescueConnection()
                                                , "[Autorizzazioni].[spChangePassword]"
                                                , null
                                                , new SqlParameter[] {
                                                    new SqlParameter("@sLogin", UserDetail.UserName)
                                                    , new SqlParameter("@sOldPassword", oldPassword)
                                                    , new SqlParameter("@sNewPassword", newPassword)
                                                    , retParam
                                                });

                resultValue = (AuthenticationPolicy.PasswordChange)retParam.Value;
            }
            catch (Exception Ex)
            {
                return resultValue;
            }
            return resultValue;
        }

        public override AuthenticationPolicy.PasswordReset ResetPassword(out string TimeStampPassword, string UserName = null)
        {
            AuthenticationPolicy.PasswordReset resultValue = AuthenticationPolicy.PasswordReset.EmptyResult;
            TimeStampPassword = Guid.NewGuid().ToString().ToUpper().Replace("-", "");
            try
            {
                string StampPassword = Utility.HashUtility.Sha512Encrypt(TimeStampPassword);

                SqlParameter retParam = new SqlParameter("@retValue", SqlDbType.Int);
                retParam.Direction = ParameterDirection.ReturnValue;

                Database.DBHelper.ExecuteStoredProcedure(RescueConnection()
                                            , "[Autorizzazioni].[spResetPassword]"
                                            , null
                                            , new SqlParameter[] {
                                                    new SqlParameter("@sLogin", UserName == null ? UserDetail.UserName : UserName)
                                                    , new SqlParameter("@sPassword", StampPassword)
                                                    , retParam
                                                });

                resultValue = (AuthenticationPolicy.PasswordReset)retParam.Value;
                
            }
            catch (Exception Ex)
            {
                return resultValue;
            }
            return resultValue;
        }
        #endregion OVERRIDABLE CLASS METHODS
    }
}
