using System;
using System.Data;
using System.Configuration;
using System.Web;
using System.Web.Security;
using System.Web.UI;
using System.Web.UI.WebControls;
using System.Web.UI.WebControls.WebParts;
using System.Web.UI.HtmlControls;
using System.IO;
using System.Security.Cryptography.X509Certificates;
using System.Net;
using System.Net.Security;


namespace BPLG.FTPS
{
    /// <summary>
    /// Summary description for FTPSClient
    /// </summary>
    public class FTPSClient
    {
        private string m_strFtpServer;
        private string m_strUserName;
        private string m_strPassword;

        /// <summary>
        /// Inizializza l'oggetto per l'accesso all'ftp protetto
        /// </summary>
        /// <param name="strFtpServer"></param>
        /// <param name="strUserName"></param>
        /// <param name="strPassword"></param>
        public FTPSClient(string strFtpServer, string strUserName, string strPassword)
        {
            m_strFtpServer = strFtpServer;
            m_strUserName = strUserName;
            m_strPassword = strPassword;
        }

        /// <summary>
        /// Permette di effettuare un upload sul server ftps
        /// </summary>
        public void PutFile(string strFileName)
        {
            //Creo l'ftp request
            FtpWebRequest req = (FtpWebRequest)WebRequest.Create(m_strFtpServer);
            //Abilito l'utilizzo dell'ssl
            req.EnableSsl = true;
            //Imposto l'handler che si deve occupare della validazione dei certificati
            ServicePointManager.ServerCertificateValidationCallback = new RemoteCertificateValidationCallback(myCertificateValidation);
            //Imposto le credenziali per l'accesso al server ftp
            req.Credentials = new NetworkCredential(m_strUserName, m_strPassword);
            //Utilizzo un ftp passivo
            req.UsePassive = true;
            //Non utilizzo nessun proxy
            req.Proxy = null;
            //Indico che devo effettuare un upload
            req.Method = WebRequestMethods.Ftp.UploadFile;

            try
            {

                //Recupero lo stream della richiesta
                Stream s = req.GetRequestStream();
                //Recupero lo stream del file che desidero inviare
                FileStream fs = new FileStream(strFileName, System.IO.FileMode.Open);

                byte[] temp = new byte[fs.Length];
                fs.Read(temp, 0, (int)fs.Length);
                s.Write(temp, 0, (int)fs.Length);
                fs.Close();
                s.Close();

                req.GetResponse();
            }
            catch (Exception error)
            {
                Console.WriteLine(error.Message);
            }

        }

        public bool myCertificateValidation(Object sender, X509Certificate cert, X509Chain chain, SslPolicyErrors Errors)
        {
            return true;
        }

    }
}