using System;
using System.Collections.Generic;
using System.Text;
using System.Security.Cryptography;
using System.Net.Mail;
using System.Net;
using System.Text.RegularExpressions;
using System.Web;

namespace BPLG.Security
{
    
    public class AuthenticationPolicy
    {
        public enum PasswordRules
        {
            /// <summary>
            /// L Password deve contenere Numeri
            /// </summary>
            Digit = 1,
            /// <summary>
            /// La Password deve contenere Lettere maiuscole
            /// </summary>
            UpperCase = 2,
            /// <summary>
            /// La Password deve contenere Lettere minuscole
            /// </summary>
            LowerCase = 4,
            /// <summary>
            /// La Password deve contenere lettere maiuscole e minuscole
            /// </summary>
            MixedCase = 6,
            /// <summary>
            /// La Passworde deve includere caratteri non alfanumerici
            /// </summary>
            SpecialChar = 8,
            /// <summary>
            /// Tutte le regole di complessità vanno applicate
            /// </summary>
            All = 15,
            /// <summary>
            /// Nessuna regola di compelssità va applicata
            /// </summary>
            None = 0
        }

        public enum PasswordCheck
        {
            /// <summary>
            /// Password OK
            /// </summary>
            OK = 1,
            /// <summary>
            /// Wrong Password Complexity
            /// </summary>
            WrongComplexity = 2,
            /// <summary>
            /// Password già utilizzata
            /// </summary>
            WrongAlreadyUsed = 3
        }

        public enum CambioPassword
        {
            /// <summary>
            /// Cambio Password per rinnovo
            /// </summary>
            Rinnovo = 1,
            /// <summary>
            /// Cambio Password per Reset
            /// </summary>
            Reset = 2,
            /// <summary>
            /// Cambio Password
            /// </summary>
            Cambio = 3
        }

        public enum LoginResults
        {
            /// <summary>
            /// Login effettuato con Successo
            /// </summary>
            LoginOK = 1,
            /// <summary>
            /// Tentativo di Accesso non riuscito
            /// </summary>
            LoginErrato = 2,
            /// <summary>
            /// L' Account risulta Bloccato
            /// </summary>
            LoginBloccato = 3,
            /// Account è stato Bloccato
            /// </summary>
            BloccoLogin = 4
        }


        public static PasswordCheck IsPasswordValid(
                                   string username,
                                   string password,
                                   int MinLength,    
                                   PasswordRules rules,
                                   params string[] ruleOutList)
        {
            bool result = true;
            const string lower = "abcdefghijklmnopqrstuvwxyz";
            const string upper = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
            const string digits = "0123456789";
            string allChars = lower + upper + digits;
            
            // Check password length
            if (password.Length < MinLength)
            {
                result = false;
            }
            
            //Check Lowercase if rule is enforced
            if (Convert.ToBoolean(rules & PasswordRules.LowerCase))
            {
                result &= (password.IndexOfAny(lower.ToCharArray()) >= 0);
            }
            //Check Uppercase if rule is enforced
            if (Convert.ToBoolean(rules & PasswordRules.UpperCase))
            {
                result &= (password.IndexOfAny(upper.ToCharArray()) >= 0);
            }
            //Check to for a digit in password if digit is required
            if (Convert.ToBoolean(rules & PasswordRules.Digit))
            {
                result &= (password.IndexOfAny(digits.ToCharArray()) >= 0);
            }
            //Check to make sure special character is included if required
            if (Convert.ToBoolean(rules & PasswordRules.SpecialChar))
            {
                result &= (password.Trim(allChars.ToCharArray()).Length > 0);
            }

            if (!result)
            {
                return PasswordCheck.WrongComplexity;
            }

            if (ruleOutList != null)
            {
                for (int i = 0; i < ruleOutList.Length; i++)
                    result &= (password != ruleOutList[i]);
            }

            if (result)
            {
                return PasswordCheck.OK;
            }
            else
            {
                return PasswordCheck.WrongAlreadyUsed;
            }
        }


        public static string Sha512Encrypt(string password)
        {
            SHA512Managed sha = new SHA512Managed();
            UnicodeEncoding uEncode = new UnicodeEncoding();
            byte[] bytClearString = uEncode.GetBytes(password);
            byte[] bytHash = sha.ComputeHash(bytClearString);

            return Convert.ToBase64String(bytHash);
        }

        //[Obsolete("This method should not be used anymore")]
        public static string SendResetPasswordLink(string idUtente, string Password, string applicationName, string applicationURL, string strServerSMTP, string strFromIndirizzo, string strFromDisplayName, string strToIndirizzo)
        {
            string strReturnErrorMessage = "";
            try
            {
                MailMessage mymail = new MailMessage();
                
                mymail.From = new MailAddress(strFromIndirizzo, strFromDisplayName);
                mymail.To.Add(new MailAddress(strToIndirizzo, strToIndirizzo));
            
                mymail.Subject = "Paperless - Procedura di Reset Password";
                mymail.Body = "La Password è stata resettata, è necessario completare la procedura cliccando il seguente Link: \n\r";
                mymail.Body += applicationURL + "/CambioPassword.aspx?action=" + BPLG.Security.AuthenticationPolicy.CambioPassword.Reset.ToString() + "&id=" + idUtente + "&pwd=" + HttpUtility.UrlEncode(Password);
                
                SmtpClient o = new SmtpClient(strServerSMTP);
                o.Send(mymail);
            }
            catch (Exception ex)
            {
                strReturnErrorMessage = ex.Message;
            }
            return strReturnErrorMessage;
        }

    }
}
