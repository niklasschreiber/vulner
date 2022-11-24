using System;
using System.Collections.Generic;
using System.Text;
using Microsoft.SqlServer.Dts.Runtime;

namespace BPLG.DataTrasformationServices
{
    class Importer2008 : IDTSEvents
    {
        private Logging.Logger m_logger;
        private Package m_DTSX;
        private bool m_bolExecutionCorrect;

        /// <summary>
        /// Costruttore della classe
        /// </summary>
        /// <param name="logger">classe per la scrittura dei log</param>
        /// <param name="sServerName">Nome del server SQL in cui è presente il package DTS</param>
        /// <param name="sDTSPackageName">Nome del package DTS che deve essere utilizzato</param>
        public Importer2008(string sServerName, string strDTSPackageFullName, string UserName, string Password)
        {
            m_logger = null;
            m_DTSX = getDTSXSQLPackage(sServerName, strDTSPackageFullName, UserName, Password);
        }

        /// <summary>
        /// Costruttore della classe
        /// </summary>
        /// <param name="logger">classe per la scrittura dei log</param>
        /// <param name="sServerName">Nome del server SQL in cui è presente il package DTS</param>
        /// <param name="sDTSPackageName">Nome del package DTS che deve essere utilizzato</param>
        public Importer2008(Logging.Logger logger, string sServerName, string strDTSPackageFullName, string UserName, string Password)
        {
            m_logger = logger;
            m_DTSX = getDTSXSQLPackage(sServerName, strDTSPackageFullName, UserName, Password);
        }

        /// <summary>
        /// Routine che restituisce un oggetto Package2Class già pronto per essere
        /// manipolato all'interno dell'applicazione
        /// </summary>
        /// <param name="strSQLServerName">Nome del server SQL a cui collegarsi</param>
        /// <param name="strDTSPackageName">Nome del package DTS che si desidera caricare</param>
        /// <returns></returns>
        private Package getDTSXSQLPackage(string strSQLServerName, string strDTSPackageFullName, string UserName, string Password)
        {
            //Application AppPackage = new Application().LoadFromSqlServer;
            return new Application().LoadFromSqlServer(strDTSPackageFullName, strSQLServerName, UserName, Password, null);

            //foreach (Step stp in package.Steps)
            //    stp.ExecuteInMainThread = true;
            //return package;
        }

        /// <summary>
        /// Esegue il package DTS e traccia un info su file di log
        /// </summary>
        /// <param name="package">Package da eseguire</param>
        /// <returns></returns>
        private bool RunPackage(Package package)
        {
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
        }

        public bool ExecutePackage()
        {
            bool bolReturnValue = false;
            try
            {
                m_bolExecutionCorrect = true;
                RunPackage(m_DTSX);
                bolReturnValue = m_bolExecutionCorrect;
            }
            catch (Exception ex)
            {
                if (m_logger != null)
                    m_logger.Write(BPLG.Logging.Logger.LogTypeMessage.Error, ex.Message, ex);
                bolReturnValue = false;
            }
            return bolReturnValue;
        }


        #region IDTSEvents Members

        void IDTSEvents.OnBreakpointHit(IDTSBreakpointSite breakpointSite, BreakpointTarget breakpointTarget)
        {
            throw new Exception("The method or operation is not implemented.");
        }

        void IDTSEvents.OnCustomEvent(TaskHost taskHost, string eventName, string eventText, ref object[] arguments, string subComponent, ref bool fireAgain)
        {
            throw new Exception("The method or operation is not implemented.");
        }

        bool IDTSEvents.OnError(DtsObject source, int errorCode, string subComponent, string description, string helpFile, int helpContext, string idofInterfaceWithError)
        {
            throw new Exception("The method or operation is not implemented.");
        }

        void IDTSEvents.OnExecutionStatusChanged(Executable exec, DTSExecStatus newStatus, ref bool fireAgain)
        {
            throw new Exception("The method or operation is not implemented.");
        }

        void IDTSEvents.OnInformation(DtsObject source, int informationCode, string subComponent, string description, string helpFile, int helpContext, string idofInterfaceWithError, ref bool fireAgain)
        {
            throw new Exception("The method or operation is not implemented.");
        }

        void IDTSEvents.OnPostExecute(Executable exec, ref bool fireAgain)
        {
            throw new Exception("The method or operation is not implemented.");
        }

        void IDTSEvents.OnPostValidate(Executable exec, ref bool fireAgain)
        {
            throw new Exception("The method or operation is not implemented.");
        }

        void IDTSEvents.OnPreExecute(Executable exec, ref bool fireAgain)
        {
            throw new Exception("The method or operation is not implemented.");
        }

        void IDTSEvents.OnPreValidate(Executable exec, ref bool fireAgain)
        {
            throw new Exception("The method or operation is not implemented.");
        }

        void IDTSEvents.OnProgress(TaskHost taskHost, string progressDescription, int percentComplete, int progressCountLow, int progressCountHigh, string subComponent, ref bool fireAgain)
        {
            throw new Exception("The method or operation is not implemented.");
        }

        bool IDTSEvents.OnQueryCancel()
        {
            throw new Exception("The method or operation is not implemented.");
        }

        void IDTSEvents.OnTaskFailed(TaskHost taskHost)
        {
            throw new Exception("The method or operation is not implemented.");
        }

        void IDTSEvents.OnVariableValueChanged(DtsContainer DtsContainer, Microsoft.SqlServer.Dts.Runtime.Variable variable, ref bool fireAgain)
        {
            throw new Exception("The method or operation is not implemented.");
        }

        void IDTSEvents.OnWarning(DtsObject source, int warningCode, string subComponent, string description, string helpFile, int helpContext, string idofInterfaceWithError)
        {
            throw new Exception("The method or operation is not implemented.");
        }

        #endregion
    }
}
