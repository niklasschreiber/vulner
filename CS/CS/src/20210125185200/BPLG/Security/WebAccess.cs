using System;
using System.Collections.Generic;
using System.Text;
using System.Data;
using System.Data.SqlClient;
using System.Net;
using System.Security.Cryptography.X509Certificates;
using System.Web;

namespace BPLG.Security
{
    public class WebAccess
    {

        #region Membri privati di classe

        private string organismo_DEFAULT = "1001";

        private string m_strConnString = "";
        private string m_sCodiceCliente = "";
        private string m_sDisplayName = "";
        private string m_sRagioneSociale = "";
        private int m_nIdStatoAccount = 0;
        private string m_sEmail = "";
        private string m_sEmailWeb = "";
        private bool m_bolLoggedIn = false;
        private int m_isAdministrator = 0;
        private bool m_bolResolver = false;
        private string m_sCodiceOrganismo = "";
        private bool m_bEntePubblico = false;
        private string m_sCodiceFiscale = "";
        private string m_sPartitaIva = "";
        private string m_sLinkPortaleGDPR = "";
        private string m_sNomeClienteProspect = "";
        private string m_sCognomeClienteProspect = "";
        private string m_sEmailClienteProspect = "";
        private string m_sCellulareClienteProspect = "";
        private string m_sIdLoginClienteProspect = "";
        private int m_nIdStatoAccountProspect = 0;
        private string m_sCodiceFiscaleProspect = "";
        private bool m_bIsProspectUser = false;
        private bool m_bIsProspectActiveUser = false;
        private bool m_bLoggedInProspect = false;
        private bool m_bIsPrivacyrequired = false;
        #endregion


        #region Costruttori

        public WebAccess(string strConnString)
        {
            m_strConnString = strConnString;
        }

        #endregion

        public void CreazioneAccount(string sCodiceCliente, string sPassword)
        {

            SqlConnection con = Data.DBHelper.OpenConnection(m_strConnString);
            SqlParameter[] par = new SqlParameter[2];
            par[0] = new SqlParameter("@sCodiceCliente", sCodiceCliente);
            par[1] = new SqlParameter("@sPassword", sPassword);
            Data.DBHelper.ExecuteStoredProcedure(con, "sp_CreazioneAccount", null, par);
        }
        public int AccountExists(string sCodiceCliente)
        {
            SqlConnection con = Data.DBHelper.OpenConnection(m_strConnString);
            SqlParameter[] par = new SqlParameter[3];
            par[0] = new SqlParameter("@sCodiceCliente", sCodiceCliente);
            par[1] = new SqlParameter("@Exists", null);
            par[2] = new SqlParameter("@nIdStatoAccount", null);
            par[1].DbType = DbType.Int32;
            par[1].Direction = ParameterDirection.Output;
            par[2].DbType = DbType.Int32;
            par[2].Direction = ParameterDirection.Output;
            Data.DBHelper.ExecuteStoredProcedure(con, "sp_AccountExists", null, par);
            int StatoAccount = 0;
            if (par[2].Value != DBNull.Value) { try { StatoAccount = Convert.ToInt32(par[2].Value.ToString()); } catch { } }
            return StatoAccount;

        }
        public int ClienteExists(string sCodiceCliente)
        {
            SqlConnection con = Data.DBHelper.OpenConnection(m_strConnString);
            SqlParameter[] par = new SqlParameter[2];
            par[0] = new SqlParameter("@sCodiceCliente", sCodiceCliente);
            par[1] = new SqlParameter("@Exists", null);
            par[1].DbType = DbType.Int32;
            par[1].Direction = ParameterDirection.Output;
            Data.DBHelper.ExecuteStoredProcedure(con, "sp_ClienteExists", null, par);
            return Convert.ToInt32(par[1].Value.ToString());

        }



        public void ModificaMailWeb(string sCodiceCliente, string sNuovaMailWeb)
        {
            SqlConnection con = Data.DBHelper.OpenConnection(m_strConnString);
            SqlParameter[] par = new SqlParameter[2];
            par[0] = new SqlParameter("@sCodiceCliente", sCodiceCliente);
            par[1] = new SqlParameter("@sNuovaMailWeb", sNuovaMailWeb);
            Data.DBHelper.ExecuteStoredProcedure(con, "sp_ModificaWebMail", null, par);
            m_sEmailWeb = sNuovaMailWeb;
        }


        public int CheckCorrispondenzaClienteIva(string sCodiceCliente, string sPartitaIva)
        {
            // Verifica che ci sia corrispondenza fra  partita IVA e cliente.

            SqlConnection con = Data.DBHelper.OpenConnection(m_strConnString);
            SqlParameter[] par = new SqlParameter[3];
            par[0] = new SqlParameter("@sCodiceCliente", sCodiceCliente);
            par[1] = new SqlParameter("@sPartitaIva", sPartitaIva);
            par[2] = new SqlParameter("@Exists", null);
            par[2].DbType = DbType.Int32;
            par[2].Direction = ParameterDirection.Output;

            Data.DBHelper.ExecuteStoredProcedure(con, "sp_CheckCorrispondenzaClienteIva", null, par);

            return Convert.ToInt32(par[2].Value.ToString());

        }

        public int CheckClienteBlackList(string sCodiceCliente)
        {
            // Verifica che ci sia corrispondenza fra  partita IVA e cliente.

            SqlConnection con = Data.DBHelper.OpenConnection(m_strConnString);
            SqlParameter[] par = new SqlParameter[2];
            par[0] = new SqlParameter("@sCodiceCliente", sCodiceCliente);
            par[1] = new SqlParameter("@isBlackList", null);
            par[1].DbType = DbType.Int32;
            par[1].Direction = ParameterDirection.Output;

            Data.DBHelper.ExecuteStoredProcedure(con, "sp_IsClienteBlackList", null, par);

            return Convert.ToInt32(par[1].Value.ToString());

        }

        public int CheckCorrispondenzaClienteContratto(string sCodiceCliente, string sCodiceContratto)
        {
            // Verifica che ci sia corrispondenza fra  contratto e cliente.

            SqlConnection con = Data.DBHelper.OpenConnection(m_strConnString);
            SqlParameter[] par = new SqlParameter[3];
            par[0] = new SqlParameter("@sCodiceCliente", sCodiceCliente);
            par[1] = new SqlParameter("@sCodiceContratto", sCodiceContratto);
            par[2] = new SqlParameter("@Exists", null);
            par[2].DbType = DbType.Int32;
            par[2].Direction = ParameterDirection.Output;

            Data.DBHelper.ExecuteStoredProcedure(con, "sp_CheckCorrispondenzaClienteContratto", null, par);

            return Convert.ToInt32(par[2].Value.ToString());

        }
        public int AttivazioneAccount(string sCodiceCliente, string sPassword)
        {

            SqlConnection con = Data.DBHelper.OpenConnection(m_strConnString);

            SqlParameter[] par = new SqlParameter[3];
            par[0] = new SqlParameter("@sCodiceCliente", sCodiceCliente);
            par[1] = new SqlParameter("@sPassword", sPassword);
            par[2] = new SqlParameter("@Esito", null);

            par[2].DbType = DbType.Int16;
            par[2].Direction = ParameterDirection.Output;

            Data.DBHelper.ExecuteStoredProcedure(con, "sp_AttivazioneAccount", null, par);
            int esito = Convert.ToInt32(par[2].Value);
            return esito;

        }
        public int CancellazioneAccount(string codiceCliente, string sPassword)
        {

            SqlConnection con = Data.DBHelper.OpenConnection(m_strConnString);

            SqlParameter[] par = new SqlParameter[3];
            par[0] = new SqlParameter("@sCodiceCliente", codiceCliente);
            par[1] = new SqlParameter("@sPassword", sPassword);
            par[2] = new SqlParameter("@Esito", null);

            par[2].DbType = DbType.Int16;
            par[2].Direction = ParameterDirection.Output;

            Data.DBHelper.ExecuteStoredProcedure(con, "sp_CancellazioneAccount", null, par);
            int esito = Convert.ToInt32(par[2].Value);
            return esito;

        }


        public BPLG.Security.AuthenticationPolicy.PasswordCheck IsPasswordValid(string codiceCliente, string password, int? minLength, AuthenticationPolicy.PasswordRules rules, params string[] ruleOutList)
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
                DataTable dtPollicy = Data.DBHelper.GetDataTableFormStoredProcedure(con, "sp_GetParametri", "", null);
                Data.DBHelper.ReleaseConnection(con);

                if (dtPollicy.Rows.Count > 0)
                {
                    if (dtPollicy.Rows[0]["nPwdMinLength"] != null)
                    {
                        nMinLen = Convert.ToInt16(dtPollicy.Rows[0]["nPwdMinLength"]);
                    }
                }
            }
            else nMinLen = (int)minLength;

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
                SqlConnection con = Data.DBHelper.OpenConnection(m_strConnString);

                SqlParameter[] par = new SqlParameter[2];
                par[0] = new SqlParameter("@sCodiceCliente", m_sCodiceCliente != "" ? m_sCodiceCliente : codiceCliente);
                par[1] = new SqlParameter("@NewPassword", Security.AuthenticationPolicy.Sha512Encrypt(password));


                DataTable dt = new BPLG.Data.DBHelper(m_strConnString).GetDataTableFormStoredProcedure("sp_CheckPasswordUsed", par);
                //  DataTable dt = Data.DBHelper.GetDataTableFormStoredProcedure(con, "sp_CheckPasswordUsed", "", par);
                Data.DBHelper.ReleaseConnection(con);
                if (Convert.ToInt16(dt.Rows[0]["PasswordUsed"]) == 1) result = false;
                else result = true;
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

        public BPLG.Security.AuthenticationPolicy.PasswordCheck IsPasswordValid(string SaltedString, string codiceCliente, string password, int? minLength, AuthenticationPolicy.PasswordRules rules, params string[] ruleOutList)
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
                DataTable dtPollicy = Data.DBHelper.GetDataTableFormStoredProcedure(con, "sp_GetParametri", "", null);
                Data.DBHelper.ReleaseConnection(con);

                if (dtPollicy.Rows.Count > 0)
                {
                    if (dtPollicy.Rows[0]["nPwdMinLength"] != null)
                    {
                        nMinLen = Convert.ToInt16(dtPollicy.Rows[0]["nPwdMinLength"]);
                    }
                }
            }
            else nMinLen = (int)minLength;

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
                string passwordCriptata = Security.AuthenticationPolicy.Sha512Encrypt(password);
                password = passwordCriptata + SaltedString;
                password = Security.AuthenticationPolicy.Sha512Encrypt(password);
                SqlConnection con = Data.DBHelper.OpenConnection(m_strConnString);

                SqlParameter[] par = new SqlParameter[2];
                par[0] = new SqlParameter("@sCodiceCliente", m_sCodiceCliente != "" ? m_sCodiceCliente : codiceCliente);
                par[1] = new SqlParameter("@NewPassword", password);


                DataTable dt = new BPLG.Data.DBHelper(m_strConnString).GetDataTableFormStoredProcedure("sp_CheckPasswordUsed", par);
                //  DataTable dt = Data.DBHelper.GetDataTableFormStoredProcedure(con, "sp_CheckPasswordUsed", "", par);
                Data.DBHelper.ReleaseConnection(con);
                if (Convert.ToInt16(dt.Rows[0]["PasswordUsed"]) == 1) result = false;
                else result = true;
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


        public BPLG.Security.AuthenticationPolicy.PasswordCheck IsPasswordValidProspect(string SaltedString, string codiceFiscale, string password, int? minLength, AuthenticationPolicy.PasswordRules rules, params string[] ruleOutList)
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
                DataTable dtPollicy = Data.DBHelper.GetDataTableFormStoredProcedure(con, "sp_GetParametri", "", null);
                Data.DBHelper.ReleaseConnection(con);

                if (dtPollicy.Rows.Count > 0)
                {
                    if (dtPollicy.Rows[0]["nPwdMinLength"] != null)
                    {
                        nMinLen = Convert.ToInt16(dtPollicy.Rows[0]["nPwdMinLength"]);
                    }
                }
            }
            else nMinLen = (int)minLength;

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
                string passwordCriptata = Security.AuthenticationPolicy.Sha512Encrypt(password);
                password = passwordCriptata + SaltedString;
                password = Security.AuthenticationPolicy.Sha512Encrypt(password);


                SqlConnection con = Data.DBHelper.OpenConnection(m_strConnString);

                SqlParameter[] par = new SqlParameter[2];
                par[0] = new SqlParameter("@sCodiceFiscale", codiceFiscale);
                par[1] = new SqlParameter("@NewPassword", password);


                DataTable dt = new BPLG.Data.DBHelper(m_strConnString).GetDataTableFormStoredProcedure("DigitalSign.sp_CheckPasswordUsedProspect", par);
                Data.DBHelper.ReleaseConnection(con);
                if (Convert.ToInt16(dt.Rows[0]["PasswordUsed"]) == 1) result = false;
                else result = true;
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
        /// ///////////////////////////////////////INTEGRAZIONE////////////////////////////////////
        /// </summary>
        /// <param name="sCodiceFiscale"></param>
        /// <param name="strPassword"></param>
        /// <returns></returns>
        public int ProspectLoginWithResult(string sCodiceFiscale, string strPassword)
        {
            SqlConnection con = Data.DBHelper.OpenConnection(m_strConnString);
            SqlParameter[] par = new SqlParameter[2];
            par[0] = new SqlParameter("@sCodiceFiscale", sCodiceFiscale);
            par[1] = new SqlParameter("@sPassword", strPassword);

            DataTable dtUser = new BPLG.Data.DBHelper(m_strConnString).GetDataTableFormStoredProcedure("DigitalSign.sp_CheckLoginProspectStandard", par);
            Data.DBHelper.ReleaseConnection(con);
            m_bLoggedInProspect = ((AuthenticationPolicy.LoginResults)(dtUser.Rows[0]["Esito"]) == AuthenticationPolicy.LoginResults.LoginOK);
            if (m_bLoggedInProspect)
            {
                var rows = dtUser.Rows;
                if (rows[0]["nIdLogin"] != DBNull.Value)
                {
                    var nIdLogin = Convert.ToString(rows[0]["nIdLogin"]);
                    m_sIdLoginClienteProspect = nIdLogin;
                }

                if (rows[0]["sNome"] != DBNull.Value)
                {
                    var sNome = Convert.ToString(rows[0]["sNome"]);
                    m_sNomeClienteProspect = sNome;
                }
                if (rows[0]["sCognome"] != DBNull.Value)
                {
                    var sCognome = Convert.ToString(rows[0]["sCognome"]);
                    m_sCognomeClienteProspect = sCognome;
                }

                if (rows[0]["sNumeroTelefonoCellulare"] != DBNull.Value)
                {
                    var sTelefonoCellulare = Convert.ToString(rows[0]["sNumeroTelefonoCellulare"]);
                    m_sCellulareClienteProspect = sTelefonoCellulare;
                }

                if (dtUser.Rows[0]["sEmail"] != DBNull.Value)
                {
                    var sEmail = Convert.ToString(dtUser.Rows[0]["sEmail"]);
                    m_sEmailClienteProspect = sEmail;
                }
                if (dtUser.Rows[0]["dtAttivazioneAccount"] != DBNull.Value)
                {
                    var dtAttivazione = Convert.ToString(dtUser.Rows[0]["dtAttivazioneAccount"]);
                    m_bIsProspectActiveUser = dtAttivazione != null;
                }
                if (dtUser.Rows[0]["nIdStatoAccount"] != DBNull.Value)
                {
                    var nIdStatoAccount = int.Parse(dtUser.Rows[0]["nIdStatoAccount"].ToString());
                    m_nIdStatoAccountProspect = nIdStatoAccount;
                }
                if (dtUser.Rows[0]["sCodiceFiscale"] != DBNull.Value)
                {
                    var sCodiceFiscaleProspect = Convert.ToString(dtUser.Rows[0]["sCodiceFiscale"]);
                    m_sCodiceFiscaleProspect = sCodiceFiscaleProspect;
                }
                if (dtUser.Rows[0]["bPrivacyRichiesta"] != DBNull.Value)
                {
                    object dtAccettazioneprivacy=null;
                    if (dtUser.Rows[0]["dtAccettazionePrivacy"] != DBNull.Value)
                         dtAccettazioneprivacy = dtUser.Rows[0]["dtAccettazionePrivacy"];

                    bool bPrivacyRichiesta = Convert.ToBoolean(rows[0]["bPrivacyRichiesta"]);

                    bool privacyRichiesta=false;
                    if (bPrivacyRichiesta && dtAccettazioneprivacy == null)
                        privacyRichiesta = true;

                    m_bIsPrivacyrequired = privacyRichiesta;
                }
                    m_bLoggedInProspect = true;
                    m_bIsProspectUser = true;         
            }
            Data.DBHelper.ReleaseConnection(con);

            return Convert.ToInt16(dtUser.Rows[0]["Esito"]);
        }

        public bool IsPasswordScaduta()
        {
            SqlConnection con = Data.DBHelper.OpenConnection(m_strConnString);

            SqlParameter[] par = new SqlParameter[1];
            par[0] = new SqlParameter("@sCodiceCliente", m_sCodiceCliente);

            DataTable dtPwdScaduta = Data.DBHelper.GetDataTableFormStoredProcedure(con, "sp_PasswordScaduta", "", par);
            Data.DBHelper.ReleaseConnection(con);
            return (Convert.ToInt16(dtPwdScaduta.Rows[0]["PasswordScaduta"]) == 1 ? true : false);
        }

        /// <summary>
        /// Gestisce l'aggiorna o il reset password
        /// </summary>
        public bool CambioPassword(string sCodiceCliente, string newPassword, bool Reset)
        {

            SqlConnection con = Data.DBHelper.OpenConnection(m_strConnString);

            SqlParameter[] par = new SqlParameter[3];
            par[0] = new SqlParameter("@sCodiceCliente", sCodiceCliente == null ? m_sCodiceCliente : sCodiceCliente);
            par[1] = new SqlParameter("@NewPassword", newPassword);
            par[2] = new SqlParameter("@Reset", Reset == true ? 1 : 0);

            Data.DBHelper.ExecuteStoredProcedure(con, "sp_CambioPassword", null, par);

            Data.DBHelper.ReleaseConnection(con);

            return true;
        }

        /// <summary>
        /// Disconnette l'utente
        /// </summary>
        public void LogOff()
        {
            m_isAdministrator = 0;
            m_bolResolver = false;
            m_bolLoggedIn = false;
            m_sCodiceCliente = string.Empty;
            m_sRagioneSociale = string.Empty;
            m_sDisplayName = string.Empty;
            m_nIdStatoAccount = 0;
            m_sEmail = string.Empty;
            m_sEmailWeb = string.Empty;
            m_sCodiceOrganismo = string.Empty;
            m_bEntePubblico = false;
            m_sCodiceFiscale = string.Empty;
            m_sPartitaIva = string.Empty;
            m_sLinkPortaleGDPR = string.Empty;
            m_sNomeClienteProspect = string.Empty;
            m_sCognomeClienteProspect = string.Empty;
            m_sEmailClienteProspect = string.Empty;
            m_sCellulareClienteProspect = string.Empty;
            m_sIdLoginClienteProspect = string.Empty;
            m_bIsProspectUser = false;
            m_sCodiceFiscaleProspect = string.Empty;
            m_nIdStatoAccountProspect = 0;
            m_bLoggedInProspect = false;
            m_bIsPrivacyrequired = false;
        }

        /// <summary>
        /// verifica se l'utente è autenticato oppure no
        /// </summary>
        public bool IsLogged()
        {
            return m_bolLoggedIn;
        }

        /// <summary>
        /// verifica se l'utente è Administrator
        /// </summary>
        public int IsAdministrator()
        {
            return m_isAdministrator;
        }

        /// <summary>
        /// verifica se l'utente è Resolver
        /// </summary>
        public bool IsResolver()
        {
            return m_bolResolver;
        }

        /// <summary>
        /// Effettua il Login tracciandone il tentativo
        /// </summary>
        public bool Login(string sCodiceCliente, string strPassword)
        {
            return (AuthenticationPolicy.LoginResults)(LoginWithResult(sCodiceCliente, strPassword)) == AuthenticationPolicy.LoginResults.LoginOK;
        }

        /// <summary>
        /// Effettua il Login tracciandone il tentativo
        /// </summary>
        /// 
        public int LoginDirectAdmin(string sCodiceCliente, int IsAdmin)
        {

            if (IsAdmin == 0) { return 0; }

            SqlParameter[] par = new SqlParameter[1];
            par[0] = new SqlParameter("@sCodiceCliente", sCodiceCliente);
            DataTable dtUser = new Data.DBHelper(m_strConnString).GetDataTableFormStoredProcedure("sp_loginAdmin", par);
            m_sCodiceCliente = sCodiceCliente;

            if (dtUser.Rows[0]["nAdministrator"] != DBNull.Value)
            {
                m_isAdministrator = Convert.ToInt32(dtUser.Rows[0]["nAdministrator"]);
            }
            if (dtUser.Rows[0]["bResolver"] != DBNull.Value)
            {
                m_bolResolver = Convert.ToBoolean(dtUser.Rows[0]["bResolver"]);
            }
            if (dtUser.Rows[0]["nIdStatoAccount"] != DBNull.Value)
            {
                m_nIdStatoAccount = Convert.ToInt32(dtUser.Rows[0]["nIdStatoAccount"]);
            }
            if (dtUser.Rows[0]["RagioneSociale"] != DBNull.Value)
            {
                m_sRagioneSociale = Convert.ToString(dtUser.Rows[0]["RagioneSociale"]);
            }
            if (dtUser.Rows[0]["sDisplayName"] != DBNull.Value)
            {
                m_sDisplayName = Convert.ToString(dtUser.Rows[0]["sDisplayName"]);
            }
            if (dtUser.Rows[0]["sCodiceOrganismo"] != DBNull.Value)
            {
                m_sCodiceOrganismo = Convert.ToString(dtUser.Rows[0]["sCodiceOrganismo"]);
            }
            else m_sCodiceOrganismo = organismo_DEFAULT;

            if (dtUser.Rows[0]["email"] != DBNull.Value)
            {
                m_sEmail = Convert.ToString(dtUser.Rows[0]["email"]);
            }
            if (dtUser.Rows[0]["emailWeb"] != DBNull.Value)
            {
                m_sEmailWeb = Convert.ToString(dtUser.Rows[0]["emailWeb"]);
            }
            if (dtUser.Rows[0]["bEntePubblico"] != DBNull.Value)
            {
                m_bEntePubblico = Convert.ToBoolean(dtUser.Rows[0]["bEntePubblico"]);
            }
            if (dtUser.Rows[0]["sCodiceFiscale"] != DBNull.Value)
            {
                m_sCodiceFiscale = Convert.ToString(dtUser.Rows[0]["sCodiceFiscale"]);
            }
            if (dtUser.Rows[0]["sPartitaIva"] != DBNull.Value)
            {
                m_sPartitaIva = Convert.ToString(dtUser.Rows[0]["sPartitaIva"]);
            }
            if (dtUser.Rows[0]["sLinkPortaleGDPR"] != DBNull.Value)
            {
                m_sLinkPortaleGDPR = Convert.ToString(dtUser.Rows[0]["sLinkPortaleGDPR"]);
            }
            else
            {
                m_sLinkPortaleGDPR = string.Empty;
            }

            return 1;

        }

        public int LoginDirectWithResultAdmin(string sCodiceCliente, int IsAdmin)
        {

            if (IsAdmin == 0) { return 0; }

            SqlParameter[] par = new SqlParameter[1];
            par[0] = new SqlParameter("@sCodiceCliente", sCodiceCliente);
            DataTable dtUser = new Data.DBHelper(m_strConnString).GetDataTableFormStoredProcedure("sp_loginAdmin", par);

            m_bolLoggedIn = dtUser.Rows.Count > 0;

            if (m_bolLoggedIn)
            {
                m_sCodiceCliente = sCodiceCliente;

                if (dtUser.Rows[0]["nAdministrator"] != DBNull.Value)
                {
                    m_isAdministrator = Convert.ToInt32(dtUser.Rows[0]["nAdministrator"]);
                }
                if (dtUser.Rows[0]["bResolver"] != DBNull.Value)
                {
                    m_bolResolver = Convert.ToBoolean(dtUser.Rows[0]["bResolver"]);
                }
                if (dtUser.Rows[0]["nIdStatoAccount"] != DBNull.Value)
                {
                    m_nIdStatoAccount = Convert.ToInt32(dtUser.Rows[0]["nIdStatoAccount"]);
                }
                if (dtUser.Rows[0]["RagioneSociale"] != DBNull.Value)
                {
                    m_sRagioneSociale = Convert.ToString(dtUser.Rows[0]["RagioneSociale"]);
                }
                if (dtUser.Rows[0]["sDisplayName"] != DBNull.Value)
                {
                    m_sDisplayName = Convert.ToString(dtUser.Rows[0]["sDisplayName"]);
                }
                if (dtUser.Rows[0]["sCodiceOrganismo"] != DBNull.Value)
                {
                    m_sCodiceOrganismo = Convert.ToString(dtUser.Rows[0]["sCodiceOrganismo"]);
                }
                else m_sCodiceOrganismo = organismo_DEFAULT;

                if (dtUser.Rows[0]["email"] != DBNull.Value)
                {
                    m_sEmail = Convert.ToString(dtUser.Rows[0]["email"]);
                }
                if (dtUser.Rows[0]["emailWeb"] != DBNull.Value)
                {
                    m_sEmailWeb = Convert.ToString(dtUser.Rows[0]["emailWeb"]);
                }
                if (dtUser.Rows[0]["bEntePubblico"] != DBNull.Value)
                {
                    m_bEntePubblico = Convert.ToBoolean(dtUser.Rows[0]["bEntePubblico"]);
                }
                if (dtUser.Rows[0]["sCodiceFiscale"] != DBNull.Value)
                {
                    m_sCodiceFiscale = Convert.ToString(dtUser.Rows[0]["sCodiceFiscale"]);
                }
                if (dtUser.Rows[0]["sPartitaIva"] != DBNull.Value)
                {
                    m_sPartitaIva = Convert.ToString(dtUser.Rows[0]["sPartitaIva"]);
                }
                if (dtUser.Rows[0]["sLinkPortaleGDPR"] != DBNull.Value)
                {
                    m_sLinkPortaleGDPR = Convert.ToString(dtUser.Rows[0]["sLinkPortaleGDPR"]);
                }
                else
                {
                    m_sLinkPortaleGDPR = string.Empty;
                }
            }

            return m_bolLoggedIn? 1: 0;
        }

        public int LoginWithResult(string sCodiceCliente, string strPassword)
        {
            SqlParameter[] par = new SqlParameter[2];
            par[0] = new SqlParameter("@sCodiceCliente", sCodiceCliente);
            par[1] = new SqlParameter("@sPassword", Security.AuthenticationPolicy.Sha512Encrypt(strPassword));

            DataTable dtUser = new Data.DBHelper(m_strConnString).GetDataTableFormStoredProcedure("sp_login", par);

            m_bolLoggedIn = ((AuthenticationPolicy.LoginResults)(dtUser.Rows[0]["Esito"]) == AuthenticationPolicy.LoginResults.LoginOK);
            if (m_bolLoggedIn)
            {
                m_sCodiceCliente = sCodiceCliente;

                if (dtUser.Rows[0]["nAdministrator"] != DBNull.Value)
                {
                    m_isAdministrator = Convert.ToInt32(dtUser.Rows[0]["nAdministrator"]);
                }
                if (dtUser.Rows[0]["bResolver"] != DBNull.Value)
                {
                    m_bolResolver = Convert.ToBoolean(dtUser.Rows[0]["bResolver"]);
                }
                if (dtUser.Rows[0]["nIdStatoAccount"] != DBNull.Value)
                {
                    m_nIdStatoAccount = Convert.ToInt32(dtUser.Rows[0]["nIdStatoAccount"]);
                }
                if (dtUser.Rows[0]["RagioneSociale"] != DBNull.Value)
                {
                    m_sRagioneSociale = Convert.ToString(dtUser.Rows[0]["RagioneSociale"]);
                }
                if (dtUser.Rows[0]["sDisplayName"] != DBNull.Value)
                {
                    m_sDisplayName = Convert.ToString(dtUser.Rows[0]["sDisplayName"]);
                }
                if (dtUser.Rows[0]["sCodiceOrganismo"] != DBNull.Value)
                {
                    m_sCodiceOrganismo = Convert.ToString(dtUser.Rows[0]["sCodiceOrganismo"]);
                }
                else m_sCodiceOrganismo = organismo_DEFAULT;

                if (dtUser.Rows[0]["email"] != DBNull.Value)
                {
                    m_sEmail = Convert.ToString(dtUser.Rows[0]["email"]);
                }
                if (dtUser.Rows[0]["emailWeb"] != DBNull.Value)
                {
                    m_sEmailWeb = Convert.ToString(dtUser.Rows[0]["emailWeb"]);
                }
                if (dtUser.Rows[0]["bEntePubblico"] != DBNull.Value)
                {
                    m_bEntePubblico = Convert.ToBoolean(dtUser.Rows[0]["bEntePubblico"]);
                }
                if (dtUser.Rows[0]["sCodiceFiscale"] != DBNull.Value)
                {
                    m_sCodiceFiscale = Convert.ToString(dtUser.Rows[0]["sCodiceFiscale"]);
                }
                if (dtUser.Rows[0]["sPartitaIva"] != DBNull.Value)
                {
                    m_sPartitaIva = Convert.ToString(dtUser.Rows[0]["sPartitaIva"]);
                }
                if (dtUser.Rows[0]["sLinkPortaleGDPR"] != DBNull.Value)
                {
                    m_sLinkPortaleGDPR = Convert.ToString(dtUser.Rows[0]["sLinkPortaleGDPR"]);
                }
                else
                {
                    m_sLinkPortaleGDPR = string.Empty;
                }
            }
            //Data.DBHelper.ReleaseConnection(con);

            return Convert.ToInt16(dtUser.Rows[0]["Esito"]);
        }

        /// <summary>
        /// Restituisce tutti i dati del cliente autenticato
        /// </summary>
        // public string UserGetData(
        /// <summary>
        /// Restituisce la ragione sociale del cliente autenticato
        /// </summary>

        public string UserRagioneSociale()
        {
            SqlConnection con = Data.DBHelper.OpenConnection(m_strConnString);
            SqlParameter[] par = new SqlParameter[1];
            par[0] = new SqlParameter("@sCodiceCliente", null);

            DataTable dtUsers = Data.DBHelper.GetDataTableFormStoredProcedure(con, "sp_UserRagioneSociale", "", par);
            Data.DBHelper.ReleaseConnection(con);
            if (dtUsers.Rows.Count > 0)
            {
                if (dtUsers.Rows[0]["sRagioneSociale"] != null)
                    return Convert.ToString(dtUsers.Rows[0]["sRagioneSociale"]);
                else return m_sRagioneSociale;
            }
            else return m_sRagioneSociale;
        }

        /// <summary>
        /// Restituisce un'istanza della calsse 
        /// </summary>
        public WebAccess GetInstance()
        {
            return this;
        }

        /// <summary>
        /// Restituisce l'atributo RagioneSociale della classe
        /// </summary>
        public string RagioneSociale()
        {
            return m_sRagioneSociale;
        }
        /// <summary>
        /// Restituisce l'atributo Codice Società della classe
        /// </summary>
        public string CodiceOrganismo()
        {
            return m_sCodiceOrganismo;
        }
        /// <summary>
        /// Restituisce l'atributo email della classe
        /// </summary>
        public string Email()
        {
            return m_sEmail;
        }

        /// <summary>
        /// Restituisce l'email Web
        /// </summary>
        public string EmailWeb()
        {
            return m_sEmailWeb;
        }

        /// <summary>
        /// Restituisce l'attributo CodiceCliente della classe
        /// </summary>
        public string CodiceCliente()
        {
            return m_sCodiceCliente;
        }

        /// <summary>
        /// Restituisce l'attributo StatoAccount della classe
        /// </summary>
        public int StatoAccount()
        {
            return m_nIdStatoAccount;
        }

        /// <summary>
        /// Indica se il cliente è un ente pubblico o privato
        /// </summary>
        public bool IsEntePubblico()
        {
            return m_bEntePubblico;
        }

        /// <summary>
        /// Restituisce l'attributo DisplayName della classe
        /// </summary>
        public string DisplayName()
        {
            return m_sDisplayName;
        }

        /// <summary>
        /// Restituisce l'attributo CodiceFiscale della classe
        /// </summary>
        public string CodiceFiscale()
        {
            return m_sCodiceFiscale;
        }

        /// <summary>
        /// Restituisce l'attributo PartitaIVA della classe
        /// </summary>
        public string PartitaIVA()
        {
            return m_sPartitaIva;
        }

        /// <summary>
        /// Restituisce l'attributo LinkPortaleGDPR della classe
        /// </summary>
        public string LinkPortaleGDPR()
        {
            return m_sLinkPortaleGDPR;
        }
        public string NomeClienteProspect()
        {
            return m_sNomeClienteProspect;
        }
        public string CognomeClienteProspect()
        {
            return m_sCognomeClienteProspect;
        }
        public string EmailClienteProspect()
        {
            return m_sEmailClienteProspect;
        }
        public string CellulareClienteProspect()
        {
            return m_sCellulareClienteProspect;
        }
        public string IdLoginClienteProspect()
        {
            return m_sIdLoginClienteProspect;
        }
        public bool IsProspectUser()
        {
            return m_bIsProspectUser;
        }
        public bool IsProspectActiveUser()
        {
            return m_bIsProspectActiveUser;
        }
        public int IdStatoAccountProspect()
        {
            return m_nIdStatoAccountProspect;
        }
        public string CodiceFiscaleAccountProspect()
        {
            return m_sCodiceFiscaleProspect;
        }
        public bool IsLoggedProspect
        {
            get
            {
                return m_bLoggedInProspect;
            }
        }
        public bool IsPrivacyRequired
        {
            get
            {
                return m_bIsPrivacyrequired;
            }
        }
    }
}


