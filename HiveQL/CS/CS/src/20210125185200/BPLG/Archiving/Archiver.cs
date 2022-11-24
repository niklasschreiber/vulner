using System;
using System.Text.RegularExpressions;
using System.IO;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using BPLG.Logging;

namespace BPLG.Archiving
{
    public class Archiver : IArchiver
    {

        string m_sArchiveFolder;
        int m_nMaxHistoryNumber;
        string m_sFileSuffix;

        public Archiver(string sArchiveFolder, int nMaxHistoryNumber, string sFileSuffix)
        {
            m_sArchiveFolder = sArchiveFolder;
            m_nMaxHistoryNumber = nMaxHistoryNumber;
            m_sFileSuffix = sFileSuffix;
        }

        #region IArchiver Members

        public bool MoveAndArchiveFile(string sFileToArchive, string sDestinationFolder)
        {
            return MoveAndArchiveFile(null, sFileToArchive, sDestinationFolder);
        }

        public bool MoveAndArchiveFile(ILogger log, string sFileToArchive, string sDestinationFolder)
        {
            bool bResult = false;
            try
            {
                #region Logging start activity
                if (log != null)
                {
                    log.Write(Logger.LogTypeMessage.Information, "Start archiving");
                }
                #endregion

                CheckDirectory(log);
                ClearOldHistory(log);

                #region Logging source
                if (log != null)
                {
                    log.Write(Logger.LogTypeMessage.Information, string.Format("[Source     ]=[{0}]", sFileToArchive));
                }
                #endregion

                string sArchiveZipFileName = DateTime.Now.ToString("yyyy-MM-dd_HHmmssfff") + "_" + m_sFileSuffix + ".zip";

                #region Logging Archive
                if (log != null)
                {
                    log.Write(Logger.LogTypeMessage.Information, string.Format("[Archive    ]=[{0}]", Path.Combine(m_sArchiveFolder, sArchiveZipFileName)));
                }
                #endregion

                BPLG.Zip.Zip.ZipFile(Path.Combine(m_sArchiveFolder, sArchiveZipFileName), sFileToArchive);

                #region Logging Destination
                if (log != null)
                {
                    log.Write(Logger.LogTypeMessage.Information, string.Format("[Destination]=[{0}]", Path.Combine(sDestinationFolder, Path.GetFileName(sFileToArchive))));
                }
                #endregion

                #region Cancellazione file di destinazione se già presente
                if (File.Exists(Path.Combine(sDestinationFolder, Path.GetFileName(sFileToArchive))))
                {
                    log.Write(Logger.LogTypeMessage.Warning, string.Format("File [{0}] already exist. It will be deleted.", Path.Combine(sDestinationFolder, Path.GetFileName(sFileToArchive))));
                    File.Delete(Path.Combine(sDestinationFolder, Path.GetFileName(sFileToArchive)));
                }
                #endregion

                File.Move(sFileToArchive, Path.Combine(sDestinationFolder, Path.GetFileName(sFileToArchive)));

                ClearOldHistory(log);

                #region Logging Success
                if (log != null)
                {
                    log.Write(Logger.LogTypeMessage.Information, "Archive succeded!");
                }
                #endregion

                bResult = true;
            }
            catch (Exception ex)
            {
                #region Logging Error
                if (log != null)
                {
                    log.Write(Logger.LogTypeMessage.Error, "Archiving error:" + ex.Message);
                }
                #endregion
                bResult = false;
            }
            return bResult;
        }

        public bool ArchiveFile(ILogger log, string sFileToArchive)
        {
            bool bResult = false;
            try
            {
                #region Logging start activity
                if (log != null)
                {
                    log.Write(Logger.LogTypeMessage.Information, "Start archiving");
                }
                #endregion

                CheckDirectory(log);
                ClearOldHistory(log);

                #region Logging source
                if (log != null)
                {
                    log.Write(Logger.LogTypeMessage.Information, string.Format("[Source     ]=[{0}]", sFileToArchive));
                }
                #endregion

                string sArchiveZipFileName = DateTime.Now.ToString("yyyy-MM-dd_HHmmssfff") + "_" + m_sFileSuffix + ".zip";

                #region Logging Archive
                if (log != null)
                {
                    log.Write(Logger.LogTypeMessage.Information, string.Format("[Archive    ]=[{0}]", Path.Combine(m_sArchiveFolder, sArchiveZipFileName)));
                }
                #endregion

                BPLG.Zip.Zip.ZipFile(Path.Combine(m_sArchiveFolder, sArchiveZipFileName), sFileToArchive);

                File.Delete(sFileToArchive);

                ClearOldHistory(log);

                #region Logging Success
                if (log != null)
                {
                    log.Write(Logger.LogTypeMessage.Information, "Archive succeded!");
                }
                #endregion

                bResult = true;
            }
            catch (Exception ex)
            {
                #region Logging Error
                if (log != null)
                {
                    log.Write(Logger.LogTypeMessage.Error, "Archiving error:" + ex.Message);
                }
                #endregion
                bResult = false;
            }
            return bResult;
        }

        #endregion

        #region Private methods

        private void CheckDirectory(ILogger log)
        {
            if (!Directory.Exists(m_sArchiveFolder))
            {
                Directory.CreateDirectory(m_sArchiveFolder);
            }
        }

        private void ClearOldHistory(ILogger log)
        {
            if (Directory.Exists(m_sArchiveFolder))
            {
                string[] sHistoryFiles = Directory.GetFiles(m_sArchiveFolder, "*" + m_sFileSuffix + ".zip", SearchOption.TopDirectoryOnly);
                Array.Sort(sHistoryFiles, StringComparer.InvariantCulture);
                int nFilesToMaintain = m_nMaxHistoryNumber;
                for (int nFile = sHistoryFiles.Length - 1; nFile >= 0; nFile--)
                {
                    //2013-04-17_154338497_Postalizzazione.zip
                    if (Regex.IsMatch(Path.GetFileName(sHistoryFiles[nFile]), @"\d{4}-\d{2}-\d{2}_\d{9}_" + m_sFileSuffix))
                    {
                        if (nFilesToMaintain <= 0)
                        {
                            File.Delete(sHistoryFiles[nFile]);
                        }
                        else
                        {
                            nFilesToMaintain--;
                        }
                    }
                }
            }
        }

        #endregion

    }
}
