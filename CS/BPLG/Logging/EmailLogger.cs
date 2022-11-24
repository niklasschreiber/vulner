using System;
using System.Collections.Generic;
using System.Text;
using System.Net.Mail;
using System.Net;
using System.Text.RegularExpressions;

namespace BPLG.Logging
{
    public class EmailLogger : SpecLogger
    {
        private string m_strAppName = "";
        private string m_strServerSMTP;
        private string m_strFromIndirizzo;
        private string m_strFromDisplayName;
        private string m_strToIndirizzo;
        private string m_strToDisplayName;
        private MailAddress m_MailFrom = null;
        private MailAddressCollection m_MailTo = null;
        private MailAddressCollection m_MailCc = null;
        private MailAddressCollection m_MailBcc = null;
        private bool m_bolExt = false;

        public EmailLogger(int intTraceLavel, string strServerSMTP, string strFromIndirizzo, string strFromDisplayName, string strToIndirizzo, string strToDisplayName):base(intTraceLavel)
        {
            m_strServerSMTP = strServerSMTP;
            m_strFromIndirizzo = strFromIndirizzo;
            m_strFromDisplayName = strFromDisplayName;
            m_strToIndirizzo = strToIndirizzo;
            m_strToDisplayName = strToDisplayName;
        }

        public EmailLogger(int intTraceLavel, string strAppName, string strServerSMTP, string strFromIndirizzo, string strFromDisplayName, string strToIndirizzo, string strToDisplayName)
            : base(intTraceLavel)
        {
            m_strServerSMTP = strServerSMTP;
            m_strFromIndirizzo = strFromIndirizzo;
            m_strFromDisplayName = strFromDisplayName;
            m_strToIndirizzo = strToIndirizzo;
            m_strToDisplayName = strToDisplayName;
            m_strAppName = strAppName;
        }

        public EmailLogger(int intTraceLavel, string strServerSMTP, MailAddress MailFrom, MailAddressCollection MailTo, MailAddressCollection MailCc, MailAddressCollection MailBcc)
            : base(intTraceLavel)
        {
            m_strServerSMTP = strServerSMTP;
            m_MailTo = MailTo;
            m_MailFrom = MailFrom;
            m_MailCc = MailCc;
            m_MailBcc = MailBcc;
            m_bolExt = true;
        }

        public EmailLogger(int intTraceLavel, string strAppName, string strServerSMTP, MailAddress MailFrom, MailAddressCollection MailTo, MailAddressCollection MailCc, MailAddressCollection MailBcc)
            : base(intTraceLavel)
        {
            m_strServerSMTP = strServerSMTP;
            m_MailTo = MailTo;
            m_MailFrom = MailFrom;
            m_MailCc = MailCc;
            m_MailBcc = MailBcc;
            m_strAppName = strAppName;
            m_bolExt = true;
        }

        public override void Write(Logger.LogTypeMessage Type, string strMessage)
        {
            try
            {
                if (!ValidTraceLevel(Type)) return;
                string strType = "";
                switch (Type)
                {
                    case Logger.LogTypeMessage.Error:
                        strType = "ERROR";
                        break;
                    case Logger.LogTypeMessage.Information:
                        strType = "INFORMATION";
                        break;
                    case Logger.LogTypeMessage.Warning:
                        strType = "WARNING";
                        break;
                    case Logger.LogTypeMessage.Verbose:
                        strType = "VERBOSE      ";
                        break;
                }
                if (m_strAppName == "")
                    this.Send(strType, strMessage, Type);
                else
                    this.Send("Applicazione: " + m_strAppName + "  - Level: " + strType, strMessage, Type);
            }
            catch 
            {
                //In caso di errore non faccio niente
            }
        }

        private string Send(string strSubject, string strMessage, Logger.LogTypeMessage Type)
        {
            string strReturnErrorMessage = "";
            try
            {
                MailMessage mymail = new MailMessage();
                if (!m_bolExt)
                {
                    mymail.From = new MailAddress(m_strFromIndirizzo, m_strFromDisplayName);
                    mymail.To.Add(new MailAddress(m_strToIndirizzo, m_strToDisplayName));
                }
                else
                {
                    mymail.From = m_MailFrom;
                    for (int intLoop = 0; intLoop < m_MailTo.Count; intLoop++) { mymail.To.Add(m_MailTo[intLoop]); }
                    for (int intLoop = 0; intLoop < m_MailCc.Count; intLoop++) { mymail.CC.Add(m_MailCc[intLoop]); }
                    for (int intLoop = 0; intLoop < m_MailBcc.Count; intLoop++) { mymail.Bcc.Add(m_MailBcc[intLoop]); }
                }
                mymail.Subject = strSubject;
                mymail.Body = strMessage;
                //switch (Type)
                //{
                //    case Logger.LogTypeMessage.Error:
                //        mymail.Priority = MailPriority.High;
                //        break;
                //    case Logger.LogTypeMessage.Information:
                //        mymail.Priority = MailPriority.Low;
                //        break;
                //}
                SmtpClient o = new SmtpClient(m_strServerSMTP);
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
