using System;
using System.Collections.Generic;
using System.Text;
using System.Configuration;
using System.Diagnostics;
using System.Collections;
using System.Web;

namespace BPLG.Logging
{
    public class Logger
    {
        /// <summary>
        /// Indica i vari livelli di trace previsti dalla gestione del logging
        /// </summary>
        public enum LogTypeMessage: int
        {
            Information = 1,
            Warning = 2,
            Error = 4,
            Verbose = 8
        }

        //Hashtable contenente tutti i logger impostati
        protected Hashtable m_htLoggers = new Hashtable();
        private string m_Username = string.Empty;

        public string Username
        {
            get
            {
                return m_Username.Length > 0 ? m_Username : HttpContext.Current.Request.LogonUserIdentity.Name;
            }
            set
            {
                m_Username = value;
            }
        }

        public void AddLogger(ILogger logger)
        { 
            //Aggiungo il logger all'elenco dei logger che gestisco
            m_htLoggers.Add(logger, logger);
            return;
        }

        /// <summary>
        /// Richiama la routine Write di tutti i logger
        /// impostati in fase di inizializzazione
        /// </summary>
        /// <param name="Type"></param>
        /// <param name="strMessage"></param>
        public void Write(Logger.LogTypeMessage Type, string strMessage)
        {
            IDictionaryEnumerator enu = m_htLoggers.GetEnumerator();
            enu.Reset();
            while (enu.MoveNext())
            {
                ((ILogger)enu.Value).Write(Type,strMessage);
            }
        }

        /// <summary>
        /// Richiama la funzione di scrittura del log con in più il parametro
        /// di tipo exception
        /// </summary>
        /// <param name="Type"></param>
        /// <param name="strMessage"></param>
        /// <param name="ex"></param>
        public void Write(Logger.LogTypeMessage Type, string strMessage, Exception ex)
        {
            this.Write(Type, strMessage + " Error: " + ex.Message);
        }

        //General.Logger.Write(BPLG.Logging.Logger.LogTypeMessage.Error, "Utente: " + Request.LogonUserIdentity.Name + " - Request: " + Request.Url.ToString() + " - Errore: " + ex.Message, ex);
        public void Write(Logger.LogTypeMessage Type, System.Web.HttpRequest req, string strMessage)
        {
            string strExtraInfo = "\r\n\r\n\r\n";
            strExtraInfo += "\t---Extra info----------------------------------------------------------------\r\n";
            strExtraInfo += "\tUtente: " + Username + "\r\n";
            strExtraInfo += "\tUrl: " + req.Url.ToString() + "\r\n";
            strExtraInfo += "\tRequestType: " + req.RequestType + "\r\n";
            try {
                if (req.UrlReferrer != null)
                    strExtraInfo += "\tUrlReferrer: " + req.UrlReferrer.ToString() + "\r\n";
            }
            catch { }
            strExtraInfo += "\tUserHostAddress: " + req.UserHostAddress + "\r\n";
            strExtraInfo += "\tUserHostName: " + req.UserHostName + "\r\n";
            strExtraInfo += "\tUserAgent: " + req.UserAgent + "\r\n";
            strExtraInfo += "\t-----------------------------------------------------------------------------\r\n";
            this.Write(Type, strMessage + strExtraInfo);
        }

        //General.Logger.Write(BPLG.Logging.Logger.LogTypeMessage.Error, "Utente: " + Request.LogonUserIdentity.Name + " - Request: " + Request.Url.ToString() + " - Errore: " + ex.Message, ex);
        public void Write(Logger.LogTypeMessage Type, System.Web.HttpRequest req, Exception ex)
        {
            string strExtraInfo = "\r\n\r\n\r\n";
            strExtraInfo += ex.StackTrace + "\r\n\r\n\r\n"; 
            strExtraInfo += "\t---Extra info----------------------------------------------------------------\r\n";
            try
            {
                strExtraInfo += "\tUtente: " + Username + "\r\n";
            }
            catch
            {
            }
            try { strExtraInfo += "\tUrl: " + req.Url.ToString() + "\r\n"; } catch { }
            try { strExtraInfo += "\tRequestType: " + req.RequestType + "\r\n"; } catch { }
            
            try {
                if (req.UrlReferrer != null)
                    strExtraInfo += "\tUrlReferrer: " + req.UrlReferrer.ToString() + "\r\n";
            }
            catch { }
            
            try { strExtraInfo += "\tUserHostAddress: " + req.UserHostAddress + "\r\n"; } catch { }
            try { strExtraInfo += "\tUserHostName: " + req.UserHostName + "\r\n"; } catch { }
            try { strExtraInfo += "\tUserAgent: " + req.UserAgent + "\r\n"; } catch { }
            
            strExtraInfo += "\t-----------------------------------------------------------------------------\r\n"; 
            this.Write(Type, ex.Message + "\n\r\n\r" + ex.StackTrace + strExtraInfo);
        }

    }
}


