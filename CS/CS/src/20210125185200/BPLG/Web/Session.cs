using System;
using System.Collections.Generic;
using System.Text;

namespace BPLG.Web
{
    public class Session
    {
        public string m_strSessionID = "";
        public string m_strIP = "";
        public DateTime m_dtLastAction;

        public System.Web.HttpRequest m_LastReq;

        public string m_strUser = "";
        public string m_strUrl = "";

        public Session(string strSessionID)
        {
            m_strSessionID = strSessionID;
            //lock (this)
            //{
            //}
        }
        public void RefreshSession(System.Web.HttpRequest req)
        {
            //m_LastReq = req;
            m_strUser = req.LogonUserIdentity.Name;
            m_strUrl = req.Url.OriginalString;
            m_dtLastAction = DateTime.Now;
            m_strIP = req.UserHostAddress;
        }
    }
}
