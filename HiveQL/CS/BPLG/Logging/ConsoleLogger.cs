using System;
using System.Collections.Generic;
using System.Text;

namespace BPLG.Logging
{
    public class ConsoleLogger: SpecLogger
    {
        //public static string m_strLogFileName = "";

        public ConsoleLogger(int intTraceLavel)
            : base(intTraceLavel)
        {
           
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

                Console.WriteLine(System.DateTime.Now.ToString("dd/MM/yyyy") + "\t" + System.DateTime.Now.ToString("HH.mm.ss.fff") + "\t" + strType + "\t" + strMessage);
            }
            catch 
            {
                //In caso di errore non faccio niente
            }
        }
    }
}
