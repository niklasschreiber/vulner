using System;
using System.Collections.Generic;
using System.Text;
using Microsoft.Reporting.WebForms;
using System.Web;
using System.Web.UI;

namespace BPLG.Reporting
{
    /// <summary>
    /// Classe per fare il rendering dei report di SQL Server Reporting Services
    /// in vari formati
    /// </summary>
    public class SSRSReport 
    {
        protected ReportViewer rview;
        //private SSRSReportPrinter m_SSRSReportPrinter = null;
        //private RenderingSize m_PageSize = RenderingSize.Portrait;
        Logging.Logger m_log;

        #region PROPERTIES
        //internal RenderingSize PageSize
        //{
        //    set
        //    {
        //        m_PageSize = value;
        //    }
        //    get
        //    {
        //        return m_PageSize;
        //    }
        //}
        #endregion PROPERTIES


        /// <summary>
        /// Permette di specificare quale formato di rendering deve essere utilizzato
        /// </summary>
        public enum RenderingFormat
        {
            ePDF
            ,eExcel
            ,eImage
            ,eCSV
            ,eCSVSemicolon
        }

        public enum RenderingSize
        {
            Portrait
            ,Landscape
        }

        private void PrintReport()
        {
        }

        public SSRSReport(Logging.Logger log, string sRSUrl, string sRSReport, string sUsername, string sPassword, string sDominio)
        {
            try
            {
                //m_SSRSReportPrinter = new SSRSReportPrinter(this);
                m_log = log;
                rview = new ReportViewer();
                rview.ProcessingMode = ProcessingMode.Remote;
                rview.ServerReport.ReportServerUrl = new Uri(sRSUrl);
                rview.ServerReport.ReportPath = sRSReport;
                rview.ServerReport.ReportServerCredentials = new SSRSReportCredentials(sUsername, sPassword, sDominio);
            }
            catch (Exception ex)
            {
                if (log != null)
                {
                    log.Write(BPLG.Logging.Logger.LogTypeMessage.Error, ex.Message, ex);
                }
                throw ex;
            }
        }

        [Obsolete("Use new version with dictionary for list parameter")]
        public SSRSReport(Logging.Logger log, string sRSUrl, string sRSReport, string sUsername, string sPassword, string sDominio, List<ReportParameter> paramList)
            : this(log, sRSUrl, sRSReport, sUsername, sPassword, sDominio)
        {
            try
            {
                rview.ServerReport.SetParameters(paramList);
            }
            catch (Exception ex)
            {
                if (log != null)
                {
                    log.Write(BPLG.Logging.Logger.LogTypeMessage.Error, ex.Message, ex);
                }
                throw ex;
            }
        }

        /// <summary>
        /// This constructor (.ctor) has been created to allow user to pass a normal dictionary to this
        /// class instead to create in client side a ReportParameter List. This method shoud be used by
        /// client code instead to use the otherone with ReportParameter.
        /// </summary>
        /// <param name="log">Logger application object</param>
        /// <param name="sRSUrl">Report Server URL</param>
        /// <param name="sRSReport">Report Name to load</param>
        /// <param name="sUsername">Username to process the report on Reporting Server url</param>
        /// <param name="sPassword">Password to process the report on Reporting Server url</param>
        /// <param name="sDominio">Domain for Reporting Server user</param>
        /// <param name="paramList">Dicrtionary contains all Report Parameter. Key represents Report Parameter name</param>
        public SSRSReport(Logging.Logger log, string sRSUrl, string sRSReport, string sUsername, string sPassword, string sDominio, Dictionary<string, string> paramList)
            : this(log, sRSUrl, sRSReport, sUsername, sPassword, sDominio)
        {
            try
            {
                if (paramList.Count > 0)
                {
                    List<ReportParameter> listParameter = new List<ReportParameter>();
                    foreach (KeyValuePair<string, string> KVP in paramList)
                    {
                        listParameter.Add(new ReportParameter(KVP.Key, KVP.Value));
                    }

                    rview.ServerReport.SetParameters(listParameter);
                }
            }
            catch (Exception ex)
            {
                if (log != null)
                {
                    log.Write(BPLG.Logging.Logger.LogTypeMessage.Error, ex.Message, ex);
                }
                throw ex;
            }
        }

        public byte[] RenderToByte(RenderingFormat rf)
        {
            try
            {

                string mimeType, encoding, extension, deviceInfo;
                string[] streamids;
                Warning[] warnings;
                string format = "";
                switch (rf)
                {
                    case RenderingFormat.ePDF:
                        format = "PDF";
                        break;
                    case RenderingFormat.eExcel:
                        format = "Excel";
                        break;
                    case RenderingFormat.eImage:
                        format = "IMAGE";
                        break;
                    case RenderingFormat.eCSV:
                        format = "CSV";
                        break;
                    case RenderingFormat.eCSVSemicolon:
                        format = "CSVSemicolon";
                        break;
                }
                deviceInfo = "<DeviceInfo>" + "<SimplePageHeaders>True</SimplePageHeaders>" + "</DeviceInfo>";                
                byte[] bytes = rview.ServerReport.Render(format, deviceInfo, out mimeType, out encoding, out extension, out streamids, out warnings);
                return bytes;
            }
            catch (Exception ex)
            {
                if (m_log != null)
                {
                    m_log.Write(BPLG.Logging.Logger.LogTypeMessage.Error, ex.Message, ex);
                }
                throw ex;
            }
        }

        public void RenderToResponse(HttpResponse Response, RenderingFormat rf, string sFileName)
        {
            RenderToResponse(Response, rf, sFileName, RenderingSize.Portrait);
            //try
            //{

            //    string mimeType, encoding, extension, deviceInfo;
            //    string[] streamids;
            //    Warning[] warnings;
            //    string format = "";
            //    switch (rf)
            //    {
            //        case RenderingFormat.ePDF:
            //            format = "PDF";
            //            break;
            //        case RenderingFormat.eExcel:
            //            format = "Excel";
            //            break;
            //        case RenderingFormat.eImage:
            //            format = "IMAGE";
            //            break;
            //    }

            //    //deviceInfo = "<DeviceInfo>" + "<SimplePageHeaders>True</SimplePageHeaders>" + "</DeviceInfo>";
            //    deviceInfo = "<DeviceInfo><PageHeight>8.5in</PageHeight><PageWidth>11in</PageWidth><SimplePageHeaders>True</SimplePageHeaders></DeviceInfo>";
            //    byte[] bytes = rview.ServerReport.Render(format, deviceInfo, out mimeType, out encoding, out extension, out streamids, out warnings);

  

            //    Response.Clear();
                
            //    //Response.ContentType = "application/pdf";
            //    Response.ContentType = mimeType;

            //    //Response.AddHeader("Content-disposition", "attachment;filename=" + sFileName + ".pdf");
            //    Response.AddHeader("Content-disposition", "attachment;filename=" + sFileName + "." + extension);


            //    Response.OutputStream.Write(bytes, 0, bytes.Length);
            //    Response.OutputStream.Flush();
            //    Response.OutputStream.Close();
            //    Response.Flush();
            //    Response.Close();

            //}
            //catch (Exception ex)
            //{
            //    m_log.Write(BPLG.Logging.Logger.LogTypeMessage.Error, ex.Message, ex);
            //    throw ex;
            //}
        }

        public void RenderToResponse(HttpResponse Response, RenderingFormat rf, string sFileName, RenderingSize PageSize)
        {
            try
            {
                string mimeType, encoding, extension, deviceInfo;
                string[] streamids;
                Warning[] warnings;
                string format = "";
                switch (rf)
                {
                    case RenderingFormat.ePDF:
                        format = "PDF";
                        break;
                    case RenderingFormat.eExcel:
                        format = "Excel";
                        break;
                    case RenderingFormat.eImage:
                        format = "IMAGE";
                        break;
                    case RenderingFormat.eCSVSemicolon:
                        format = "CSVSemicolon";
                        break;
                }

                deviceInfo = "<DeviceInfo>" + "<SimplePageHeaders>True</SimplePageHeaders>" + "</DeviceInfo>";
                if (PageSize == RenderingSize.Landscape)
                {
                    deviceInfo = "<DeviceInfo><PageHeight>21cm</PageHeight><PageWidth>29cm</PageWidth><RightMargin>0.5cm</RightMargin><LeftMargin>0.5cm</LeftMargin><SimplePageHeaders>True</SimplePageHeaders></DeviceInfo>";
                }
                byte[] bytes = rview.ServerReport.Render(format, deviceInfo, out mimeType, out encoding, out extension, out streamids, out warnings);



                Response.Clear();

                //Response.ContentType = "application/pdf";
                Response.ContentType = mimeType;

                //Response.AddHeader("Content-disposition", "attachment;filename=" + sFileName + ".pdf");
                Response.AddHeader("Content-disposition", "attachment;filename=" + sFileName + "." + extension);


                Response.OutputStream.Write(bytes, 0, bytes.Length);
                Response.OutputStream.Flush();
                Response.OutputStream.Close();
                Response.Flush();
                Response.Close();

            }
            catch (Exception ex)
            {
                if (m_log != null)
                {
                    m_log.Write(BPLG.Logging.Logger.LogTypeMessage.Error, ex.Message, ex);
                }
                throw ex;
            }
        }

        public void ExportReport(string sFileName, RenderingFormat rf = RenderingFormat.eExcel, RenderingSize PageSize = RenderingSize.Landscape)
        {
            try
            {
                string mimeType, encoding, extension, deviceInfo;
                string[] streamids;
                Warning[] warnings;
                string format = "";
                #region IDENTIFICAZIONE TIPOLOGIA
                switch (rf)
                {
                    case RenderingFormat.ePDF:
                        format = "PDF";
                        break;
                    case RenderingFormat.eExcel:
                        format = "Excel";
                        break;
                    case RenderingFormat.eImage:
                        format = "IMAGE";
                        break;
                    case RenderingFormat.eCSVSemicolon:
                        format = "CSVSemicolon";
                        break;
                }
                #endregion IDENTIFICAZIONE TIPOLOGIA

                #region PARAMETRIZZAZIONE LAYOUT REPORT
                deviceInfo = "<DeviceInfo>" + "<SimplePageHeaders>True</SimplePageHeaders>" + "</DeviceInfo>";
                if (PageSize == RenderingSize.Landscape)
                {
                    deviceInfo = "<DeviceInfo><PageHeight>21cm</PageHeight><PageWidth>29cm</PageWidth><RightMargin>0.5cm</RightMargin><LeftMargin>0.5cm</LeftMargin><SimplePageHeaders>True</SimplePageHeaders></DeviceInfo>";
                }
                byte[] bytes = rview.ServerReport.Render(format, deviceInfo, out mimeType, out encoding, out extension, out streamids, out warnings);
                #endregion PARAMETRIZZAZIONE LAYOUT REPORT

                #region BUFFERIZZAZIONE ED EXPORT
                HttpContext.Current.Response.Clear();
                HttpContext.Current.Response.ContentType = mimeType;
                HttpContext.Current.Response.AddHeader("Content-disposition", "attachment;filename=" + sFileName + "." + extension);

                HttpContext.Current.Response.OutputStream.Write(bytes, 0, bytes.Length);
                HttpContext.Current.Response.OutputStream.Flush();
                HttpContext.Current.Response.OutputStream.Close();
                HttpContext.Current.Response.Flush();
                HttpContext.Current.Response.SuppressContent = true;
                HttpContext.Current.ApplicationInstance.CompleteRequest();
                #endregion BUFFERIZZAZIONE ED EXPORT
            }
            catch (Exception ex)
            {
                if (m_log != null)
                {
                    m_log.Write(BPLG.Logging.Logger.LogTypeMessage.Error, ex.Message, ex);
                }
                throw ex;
            }
        }
    }
}
