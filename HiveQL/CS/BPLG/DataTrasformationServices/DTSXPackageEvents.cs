using System;
using System.Collections.Generic;
using System.Text;
using Microsoft.SqlServer.Dts;
using Microsoft.SqlServer.Dts.Runtime;

namespace BPLG.DataTrasformationServices
{
    public class DTSX2008Package : Application, IDTSEvents
    {
        private Logging.Logger m_logger;
        private bool m_bolExecutionCorrect;
        private Package m_DTSX;

        public DTSX2008Package(Logging.Logger logger, string sServerName, string DTSPackageFullName, string UserName, string Password)
            : base()
        {
            try
            {
                m_logger = logger;
                m_DTSX = this.LoadFromSqlServer(DTSPackageFullName, sServerName, UserName, Password, null);
            }
            catch (Exception Ex)
            {
                m_logger.Write(BPLG.Logging.Logger.LogTypeMessage.Error, "End error package (" + DTSPackageFullName + "). ");
                throw Ex;
            }
        }

        public bool ExecutePackage()
        {

            //Microsoft.SqlServer.Dts.Runtime.Wrapper.PackageClass cla = new Microsoft.SqlServer.Dts.Runtime.Wrapper.PackageClass();
            //Microsoft.SqlServer.Dts.Runtime.Wrapper.ApplicationClass cls = new Microsoft.SqlServer.Dts.Runtime.Wrapper.ApplicationClass();
            //cls.lo

            try
            {
                m_logger.Write(BPLG.Logging.Logger.LogTypeMessage.Information, "Start package (" + m_DTSX.Name + "). ");

                DTSExecResult result = m_DTSX.Execute();
                if ((result == DTSExecResult.Failure) || (result == DTSExecResult.Canceled))
                {
                    foreach (DtsError DtsError in m_DTSX.Errors)
                    {
                        m_logger.Write(BPLG.Logging.Logger.LogTypeMessage.Error, "End failed package (" + DtsError.Description + "). ");
                    }
                    return false;
                }
                else
                {
                    m_logger.Write(BPLG.Logging.Logger.LogTypeMessage.Information, "End package (" + m_DTSX.Name + "). ");
                    return true;
                }
            }
            catch (Exception Ex)
            {
                m_logger.Write(BPLG.Logging.Logger.LogTypeMessage.Error, "End error package (" + m_DTSX.Name + "). ");
                return false;
            }
            //try
            //{
            //    m_bolExecutionCorrect = this.ExecutePackage();
            //}
            //catch (Exception Ex)
            //{
            //    m_logger(BPLG.Logging.Logger.LogTypeMessage.Error, ex.Message, ex);
            //    m_bolExecutionCorrect = false;
            //}
            //return m_bolExecutionCorrect;
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
