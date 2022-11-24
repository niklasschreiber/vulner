using System;
using System.Collections.Generic;
using System.Text;
using Microsoft.SqlServer.Dts;
using Microsoft.SqlServer.Dts.Runtime;
using System.Data.SqlClient;
using System.Data;

namespace BPLG.DataTrasformationServices
{
    public class DTSXPackageAgent : Application, IDTSEvents
    {
        private Logging.Logger m_logger;
        private bool m_bolExecutionCorrect;
        private Package m_DTSX;
        private string m_ServerName = string.Empty;
        private string m_AgentName = string.Empty;


        public DTSXPackageAgent(Logging.Logger logger, string ServerName, string AgentJobName)
            : base()
        {
            try
            {
                m_logger = logger;
                m_ServerName = ServerName;
                m_AgentName = AgentJobName;
            }
            catch (Exception Ex)
            {
                m_logger.Write(BPLG.Logging.Logger.LogTypeMessage.Error, "End failed job (" + m_AgentName + "). ");
                throw Ex;
            }
        }

        public List<string> ExecutePackage()
        {
            List<string> resultMethod = null;
            try
            {
                m_logger.Write(BPLG.Logging.Logger.LogTypeMessage.Information, "Start job (" + m_AgentName + "). ");

                SqlConnection jobConnection;
                SqlCommand jobCommand;
                SqlParameter jobReturnValue;
                SqlParameter jobParameter;
                int jobResult;

                jobConnection = new SqlConnection("Data Source=" + m_ServerName + ";Initial Catalog=msdb;Integrated Security=SSPI");
                jobCommand = new SqlCommand("sp_start_job", jobConnection);
                jobCommand.CommandType = CommandType.StoredProcedure;

                jobReturnValue = new SqlParameter("@RETURN_VALUE", SqlDbType.Int);
                jobReturnValue.Direction = ParameterDirection.ReturnValue;
                jobCommand.Parameters.Add(jobReturnValue);

                jobParameter = new SqlParameter("@job_name", SqlDbType.VarChar);
                jobParameter.Direction = ParameterDirection.Input;
                jobCommand.Parameters.Add(jobParameter);
                jobParameter.Value = m_AgentName;

                jobConnection.Open();
                jobCommand.ExecuteNonQuery();
                jobResult = (Int32)jobCommand.Parameters["@RETURN_VALUE"].Value;
                jobConnection.Close();

                switch (jobResult)
                {
                    case 0:
                        m_logger.Write(BPLG.Logging.Logger.LogTypeMessage.Error, "End successful job (" + m_AgentName + "). ");
                        break;
                    default:
                        resultMethod.Add("End failed job (" + m_AgentName + "). ");
                        break;
                }
            }
            catch (Exception Ex)
            {
                resultMethod.Add(Ex.Message);
                m_logger.Write(BPLG.Logging.Logger.LogTypeMessage.Error, "End failed job (" + m_AgentName + "). Error: " + Ex.Message);
            }
            return resultMethod;
        }

        public Microsoft.SqlServer.Dts.Runtime.Variables Variables
        {
            get
            {
                return m_DTSX.Variables;
            }
        }

        #region IDTSEvents Members

        public void OnBreakpointHit(IDTSBreakpointSite breakpointSite, BreakpointTarget breakpointTarget)
        {
            throw new Exception("The method or operation is not implemented.");
        }

        public void OnCustomEvent(TaskHost taskHost, string eventName, string eventText, ref object[] arguments, string subComponent, ref bool fireAgain)
        {
            throw new Exception("The method or operation is not implemented.");
        }

        public bool OnError(DtsObject source, int errorCode, string subComponent, string description, string helpFile, int helpContext, string idofInterfaceWithError)
        {
            throw new Exception("The method or operation is not implemented.");
        }

        public void OnExecutionStatusChanged(Executable exec, DTSExecStatus newStatus, ref bool fireAgain)
        {
            throw new Exception("The method or operation is not implemented.");
        }

        public void OnInformation(DtsObject source, int informationCode, string subComponent, string description, string helpFile, int helpContext, string idofInterfaceWithError, ref bool fireAgain)
        {
            throw new Exception("The method or operation is not implemented.");
        }

        public void OnPostExecute(Executable exec, ref bool fireAgain)
        {
            throw new Exception("The method or operation is not implemented.");
        }

        public void OnPostValidate(Executable exec, ref bool fireAgain)
        {
            throw new Exception("The method or operation is not implemented.");
        }

        public void OnPreExecute(Executable exec, ref bool fireAgain)
        {
            throw new Exception("The method or operation is not implemented.");
        }

        public void OnPreValidate(Executable exec, ref bool fireAgain)
        {
            throw new Exception("The method or operation is not implemented.");
        }

        public void OnProgress(TaskHost taskHost, string progressDescription, int percentComplete, int progressCountLow, int progressCountHigh, string subComponent, ref bool fireAgain)
        {
            throw new Exception("The method or operation is not implemented.");
        }

        public bool OnQueryCancel()
        {
            throw new Exception("The method or operation is not implemented.");
            return false;
        }

        public void OnTaskFailed(TaskHost taskHost)
        {
            throw new Exception("The method or operation is not implemented.");
        }

        public void OnVariableValueChanged(DtsContainer DtsContainer, Microsoft.SqlServer.Dts.Runtime.Variable variable, ref bool fireAgain)
        {
            throw new Exception("The method or operation is not implemented.");
        }

        public void OnWarning(DtsObject source, int warningCode, string subComponent, string description, string helpFile, int helpContext, string idofInterfaceWithError)
        {
            throw new Exception("The method or operation is not implemented.");
        }

        #endregion
    }
}
