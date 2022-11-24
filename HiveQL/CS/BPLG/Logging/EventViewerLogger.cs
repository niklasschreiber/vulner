using System;
using System.Collections.Generic;
using System.Text;
using System.Diagnostics;

namespace BPLG.Logging
{
    public class EventViewerLogger : SpecLogger
    {
        public static string m_strSource = "";
        public EventViewerLogger(int intTraceLavel, string strSourceName):base(intTraceLavel)
        {
            m_strSource = strSourceName;
        }

        public override void Write(Logger.LogTypeMessage Type, string strMessage)
        {
            try
            {
                if (!ValidTraceLevel(Type)) return;
                
                switch (Type)
                {
                    case Logger.LogTypeMessage.Information:
                        System.Diagnostics.EventLog.WriteEntry(m_strSource, strMessage, EventLogEntryType.Information);
                        break;
                    case Logger.LogTypeMessage.Warning:
                        System.Diagnostics.EventLog.WriteEntry(m_strSource, strMessage, EventLogEntryType.Warning);
                        break;
                    case Logger.LogTypeMessage.Error:
                        System.Diagnostics.EventLog.WriteEntry(m_strSource, strMessage, EventLogEntryType.Error);
                        break;
                }
            }
            catch 
            {
                //In caso di errore non faccio niente
            }


        }
    }
}
