using System;
using System.Collections.Generic;
using System.Text;
using System.IO;
using System.Security.Cryptography;

namespace BPLG.Security
{
    /// <summary>
    /// Classe di utilità per il calcolo degli hash
    /// </summary>
    public class HashUtil
    {
        /// <summary>
        /// Restituisce l'hash code del file con codifica MD5
        /// </summary>
        /// <param name="strFile">Nomde del file per cui calcolare l'hash</param>
        /// <returns></returns>
        public static string HashMD5(string strFile)
        {
            return HashGeneric(MD5.Create(), strFile);
        }

        /// <summary>
        /// Restituisce l'hash code del file con codifica SHA1
        /// </summary>
        /// <param name="strFile">Nomde del file per cui calcolare l'hash</param>
        /// <returns></returns>
        public static string HashSHA1(string strFile)
        {
            return HashGeneric(SHA1.Create(), strFile);
        }

        private static string HashGeneric(HashAlgorithm hash, string strFile)
        {
            StringBuilder sb = new StringBuilder();
            using (FileStream fs = File.Open(strFile, FileMode.Open))
            {
                foreach (byte b in hash.ComputeHash(fs))
                    sb.Append(b.ToString("x2").ToLower());
            }
            return sb.ToString();
        }
    }
}
