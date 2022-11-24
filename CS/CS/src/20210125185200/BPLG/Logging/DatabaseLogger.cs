using System;
using System.Collections.Generic;
using System.Text;
using System.Data.SqlClient;
using System.Data;

namespace BPLG.Logging
{
    public class DatabaseLogger : SpecLogger
    {
        public string m_strConnectionString = "";
        public string m_strLogTableName = "";
        public string m_strDateTimeFieldName = "";
        public string m_strTypeFieldName = "";
        public string m_strMessageFieldName = "";

        public DatabaseLogger(int intTraceLavel, string strConnectionString, string strLogTableName, string strDateTimeFieldName, string strTypeFieldName, string strMessageFieldName):base(intTraceLavel)
        {
            m_strConnectionString = strConnectionString;
            m_strLogTableName=strLogTableName;
            m_strDateTimeFieldName=strDateTimeFieldName;
            m_strTypeFieldName=strTypeFieldName;
            m_strMessageFieldName=strMessageFieldName;
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
                //Sistemo il campo con il messaggio per cambiare i caratteri non validi
                strMessage = strMessage.Replace("'", "''");

                string strSQL = "";
                SqlConnection oCon = new SqlConnection(m_strConnectionString);
                oCon = new SqlConnection(m_strConnectionString);
                oCon.Open();
                strSQL += " INSERT INTO " + m_strLogTableName + " ";
                strSQL += " (" + m_strDateTimeFieldName + "," + m_strTypeFieldName + "," + m_strMessageFieldName + ") ";
                strSQL += " VALUES ";
                //strSQL += " ('" + DateTime.Now.ToString("yyyyMMddHHmmss") + "','" + strType + "','" + strMessage + "')";
                strSQL += " ('" + DateTime.Now.ToString("yyyyMMddHHmmssfff") + "','" + strType + "',@Message)";
                SqlCommand comm = oCon.CreateCommand();
                comm.CommandText = strSQL;
                comm.CommandType = CommandType.Text;
                comm.Parameters.Add(new SqlParameter("@Message", strMessage));
                comm.ExecuteNonQuery();
            }
            catch 
            { 
                //In caso di errore non faccio niente
            }
        }
    }
}
