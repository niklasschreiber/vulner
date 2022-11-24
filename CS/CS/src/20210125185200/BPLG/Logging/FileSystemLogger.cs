using System;
using System.Collections.Generic;
using System.Text;

namespace BPLG.Logging
{
    public class FileSystemLogger : SpecLogger
    {
        public static string m_strLogFileName = "";
       public FileSystemLogger(int intTraceLavel, string strLogFileName):base(intTraceLavel)
        {
            m_strLogFileName = strLogFileName;
        }

        public override void Write(Logger.LogTypeMessage Type, string strMessage)
        {
            try
            {
                if (!ValidTraceLevel(Type)) return;
                //Procedo solo se è stato impostato il nome del file di log
                if (m_strLogFileName == "") return;
                string strType = "";
                switch (Type)
                {
                    case Logger.LogTypeMessage.Error:
                        strType = "ERROR        ";
                        break;
                    case Logger.LogTypeMessage.Information:
                        strType = "INFORMATION  ";
                        break;
                    case Logger.LogTypeMessage.Warning:
                        strType = "WARNING      ";
                        break;
                    case Logger.LogTypeMessage.Verbose:
                        strType = "VERBOSE      ";
                        break;
                }
                System.IO.StreamWriter o = new System.IO.StreamWriter(m_strLogFileName, true);
                o.WriteLine(System.DateTime.Now.ToString("dd/MM/yyyy") + "\t" + System.DateTime.Now.ToString("HH.mm.ss.fff") + "\t" + strType + "\t" + strMessage);
                o.Close();
            }
            catch 
            {
                //In caso di errore non faccio niente
            }
        }

    }
}
