using System;
using System.Collections.Generic;
using System.Text;
using System.Configuration;
using BPLG.Configuration;
using System.Xml;

namespace BPLG.Logging
{
    public class LoggerFactory
    {

        public static BPLG.Logging.Logger CreateLogger()
        {
            IParser pars = (IParser)new WebConfigParser();
            return CreateLogger(pars);
        }

        public static BPLG.Logging.Logger CreateLoggerDifferent(string Filename)
        {
            IParser pars = (IParser)new WebConfigParser();
            return CreateLogger(pars, Filename);
        }

        public static BPLG.Logging.Logger CreateLogger(string strXMLFileName)
        {
            IParser pars = new XMLFileParser(strXMLFileName);
            return CreateLogger(pars);
        }

        private static BPLG.Logging.Logger CreateLogger(IParser pars)
        {
            BPLG.Logging.Logger m_log = new BPLG.Logging.Logger();
            int intLoggersCount = Convert.ToInt16(pars.ReadParameter("NrLoggers"));
            for (int intLoopLoggers = 1; intLoopLoggers <= intLoggersCount; intLoopLoggers++) AddLogger(m_log, intLoopLoggers, pars);
            return m_log;
        }

        private static BPLG.Logging.Logger CreateLogger(IParser pars, String Filename)
        {
            BPLG.Logging.Logger m_log = new BPLG.Logging.Logger();
            int intLoggersCount = Convert.ToInt16(pars.ReadParameter("NrLoggers"));
            for (int intLoopLoggers = 1; intLoopLoggers <= intLoggersCount; intLoopLoggers++)
                AddLogger(m_log, intLoopLoggers, pars, Filename);
            return m_log;
        }

        private static void AddLogger(BPLG.Logging.Logger log, int intLogItem, IParser pars)
        {
            AddLogger(log, intLogItem, pars, null);
        }

        private static void AddLogger(BPLG.Logging.Logger log, int intLogItem, IParser pars, string Filename)
        {
            try
            {
                int intLoggerEvents = Convert.ToInt16(pars.ReadParameter("LoggerEvents_" + intLogItem.ToString()));
                string strLoggerType = pars.ReadParameter("LoggerType_" + intLogItem.ToString());
                switch (strLoggerType)
                {
                    case "FILE":
                        //Aggiunge un logger di tipo file di testo
                        string strLogFileName = pars.ReadParameter("LogFileName_" + intLogItem.ToString());
                        log.AddLogger(new BPLG.Logging.FileSystemLogger(intLoggerEvents, strLogFileName));
                        break;
                    case "EVENTVIEWER":
                        //Aggiunge un logger di tipo event viewer
                        string strApplicationName = pars.ReadParameter("ApplicationName_" + intLogItem.ToString());
                        log.AddLogger(new BPLG.Logging.EventViewerLogger(intLoggerEvents, strApplicationName));
                        break;
                    case "MAIL":
                        //Aggiunge un logger di tipo mail
                        System.Net.Mail.MailAddressCollection mto = new System.Net.Mail.MailAddressCollection();
                        for (int intLoop = 1; intLoop <= Convert.ToInt32(pars.ReadParameter("Email_To_Count_" + intLogItem.ToString())); intLoop++)
                            mto.Add(new System.Net.Mail.MailAddress(pars.ReadParameter("Email_To_" + intLogItem.ToString() + "_" + intLoop.ToString()), pars.ReadParameter("Email_To_Display_" + intLogItem.ToString() + "_" + intLoop.ToString())));
                        log.AddLogger(new BPLG.Logging.EmailLogger(intLoggerEvents, pars.ReadParameter("EmailAppName_" + intLogItem.ToString()), pars.ReadParameter("EmailNotification_SMTPServer_" + intLogItem.ToString()), new System.Net.Mail.MailAddress(pars.ReadParameter("EmailNotification_FromEmail_" + intLogItem.ToString()), pars.ReadParameter("EmailNotification_FromDisplay_" + intLogItem.ToString())), mto, new System.Net.Mail.MailAddressCollection(), new System.Net.Mail.MailAddressCollection()));
                        break;
                    case "CONSOLE":
                        //Aggiunge un logger di tipo console (stampa a video)
                        log.AddLogger(new BPLG.Logging.ConsoleLogger(intLoggerEvents));
                        break;
                    case "FILE_GENERIC":
                        //Aggiunge un logger di tipo file di testo
                        string strLogFileNameSpecific = pars.ReadParameter("LogFileName_" + intLogItem.ToString()) + Filename;
                        log.AddLogger(new BPLG.Logging.FileSystemLogger(intLoggerEvents, strLogFileNameSpecific));
                        break;
                }
            }
            catch (Exception ex)
            {
                log.Write(BPLG.Logging.Logger.LogTypeMessage.Error, ex.Message, ex);
            }
        }


        public static BPLG.Logging.Logger CreateLogger(ConfigSectionHandler config)
        {
            BPLG.Logging.Logger m_log = new BPLG.Logging.Logger();

            foreach (ConfigFileSystemLoggerElement log in config.FileSystemLoggers)
                m_log.AddLogger(new FileSystemLogger(log.Events, log.FileName));

            foreach (ConfigEventViewerLoggerElement log in config.EventViewerLoggers)
                m_log.AddLogger(new BPLG.Logging.EventViewerLogger(log.Events, log.AppName));

            foreach (ConfigEmailLoggerElement log in config.EmailLoggers)
            {
                System.Net.Mail.MailAddressCollection to = new System.Net.Mail.MailAddressCollection();
                to.Add(log.To);
                m_log.AddLogger(new BPLG.Logging.EmailLogger(log.Events, log.AppName, log.SmtpServer, new System.Net.Mail.MailAddress(log.From), to, new System.Net.Mail.MailAddressCollection(), new System.Net.Mail.MailAddressCollection()));
            }

            return m_log;
        }

        public static BPLG.Logging.Logger CreateLogger(System.Xml.XmlNode LoggerNode)
        {
            BPLG.Logging.Logger m_log = new BPLG.Logging.Logger();

            #region FILE SYSTEM LOGGER
            XmlNodeList FileSystemLogger = LoggerNode.SelectNodes("descendant::FileSystemLoggers/add");
            foreach (XmlNode ActualNode in FileSystemLogger)
            {
                m_log.AddLogger(
                        new FileSystemLogger(
                                    int.Parse(ActualNode.Attributes["events"].Value), 
                                    ActualNode.Attributes["filename"].Value
                                    )
                        );
            }
            #endregion FILE SYSTEM LOGGER

            #region EVENT VIEWER LOGGER
            XmlNodeList EventViewerLogger = LoggerNode.SelectNodes("descendant::EventViewerLoggers/add");
            foreach (XmlNode ActualNode in EventViewerLogger)
            {
                m_log.AddLogger(
                        new BPLG.Logging.EventViewerLogger(
                                    int.Parse(ActualNode.Attributes["events"].Value),
                                    ActualNode.Attributes["appname"].Value
                                    )
                        );
            }
            #endregion EVENT VIEWER LOGGER

            #region EMAIL LOGGER
            XmlNodeList EmailLogger = LoggerNode.SelectNodes("descendant::EmailLoggers/add");
            foreach (XmlNode ActualNode in EmailLogger)
            {
                System.Net.Mail.MailAddressCollection to = new System.Net.Mail.MailAddressCollection();
                to.Add(ActualNode.Attributes["to"].Value);

                m_log.AddLogger(
                        new BPLG.Logging.EmailLogger(
                                    int.Parse(ActualNode.Attributes["events"].Value),
                                    ActualNode.Attributes["appname"].Value,
                                    ActualNode.Attributes["smtpserver"].Value,
                                    new System.Net.Mail.MailAddress(ActualNode.Attributes["from"].Value),
                                    to,
                                    new System.Net.Mail.MailAddressCollection(),
                                    new System.Net.Mail.MailAddressCollection()
                                    )
                        );
            }
            #endregion EMAIL LOGGER

            #region CONSOLE LOGGER
            XmlNodeList ConsoleLogger = LoggerNode.SelectNodes("descendant::ConsoleLoggers/add");
            foreach (XmlNode ActualNode in ConsoleLogger)
            {
                m_log.AddLogger(
                        new ConsoleLogger(
                                    int.Parse(ActualNode.Attributes["events"].Value))
                        );
            }
            #endregion CONSOLE LOGGER

            return m_log;
        }
    
    }

}
