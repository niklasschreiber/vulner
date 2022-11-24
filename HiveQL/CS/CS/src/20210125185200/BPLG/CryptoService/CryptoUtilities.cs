using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Security.Cryptography;

namespace BPLG.CryptoService
{
    /// <summary>
    /// This class is in charge to allow user to crypt and decrypt any string.
    /// The security key is stored inside the class and it should not be passed
    /// aas a parameter. two methods will help developers to achive the cryptography 
    /// operations. the cryptography method used is TripleDES.
    /// This method is builded just raise any exception to the caller through the stack trace
    /// </summary>
    public class CryptoUtilities
    {
        /// <summary>
        /// Security key for TripleDES encryption.
        /// </summary>
        private static string m_SecurityKey = "1524AGRS5214YSTD";

        /// <summary>
        /// As the name says, this method is in charge to Encrypt a text passed by value
        /// </summary>
        /// <param name="ToEncrypt">plain text will be encrypted</param>
        /// <returns>The enrypted string.</returns>
        public static string Encrypt(string ToEncrypt)
        {
            try
            {
                byte[] keyArray;
                byte[] toEncryptArray = UTF8Encoding.UTF8.GetBytes(ToEncrypt);

                keyArray = UTF8Encoding.UTF8.GetBytes(m_SecurityKey);
                TripleDESCryptoServiceProvider tdes = new TripleDESCryptoServiceProvider();
                tdes.Key = keyArray;
                tdes.Mode = CipherMode.ECB;
                tdes.Padding = PaddingMode.PKCS7;

                ICryptoTransform cTrasform = tdes.CreateEncryptor();
                byte[] resultArray = cTrasform.TransformFinalBlock(toEncryptArray, 0, toEncryptArray.Length);

                tdes.Clear();
                return Convert.ToBase64String(resultArray, 0, resultArray.Length);
            }
            catch (Exception Ex)
            {
                throw Ex;
            }
        }

        /// <summary>
        /// As the name says, this method is in charge to Decrypt an encrypted text passed by value
        /// </summary>
        /// <param name="cipherString">The encrypted text</param>
        /// <returns>Plain text for the cipher string passed as parameter</returns>
        public static string Decrypt(string cipherString)
        {
            try
            {
                byte[] keyArray;
                byte[] toEncryptArray = Convert.FromBase64String(cipherString);

                keyArray = UTF8Encoding.UTF8.GetBytes(m_SecurityKey);
                TripleDESCryptoServiceProvider tdes = new TripleDESCryptoServiceProvider();
                tdes.Key = keyArray;
                tdes.Mode = CipherMode.ECB;
                tdes.Padding = PaddingMode.PKCS7;
                ICryptoTransform cTrasform = tdes.CreateDecryptor();
                byte[] resultArray = cTrasform.TransformFinalBlock(toEncryptArray, 0, toEncryptArray.Length);

                tdes.Clear();

                return UTF8Encoding.UTF8.GetString(resultArray);
            }
            catch (Exception Ex)
            {
                throw Ex;
            }
        }
    }
}
