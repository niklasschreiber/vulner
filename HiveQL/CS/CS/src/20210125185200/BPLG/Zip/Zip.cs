using System;
using System.IO;
using ICSharpCode.SharpZipLib.Zip;
using ICSharpCode.SharpZipLib.Checksums;

namespace BPLG.Zip
{
    /// <summary>
    /// Zip
    /// </summary>
    public class Zip
    {
        #region public methods

        /// <summary>
        /// Aggiunge un file ad un file zip esistente. Se il file zip non esiste lo crea
        /// </summary>
        /// <param name="ZipFilePath">Path del file compresso da creare</param>
        /// <param name="OriginalFilePath">Path del file da comprimere</param>
        public static void ZipAddFile(string ZipFilePath, string OriginalFilePath)
        {
            try
            {
                if (!File.Exists(ZipFilePath))
                {
                    FileInfo fi = new FileInfo(OriginalFilePath);
                    ZipOutputStream zip = new ZipOutputStream(File.Open(ZipFilePath, FileMode.Append));
                    zip.SetLevel(6);    // 0 - store only to 9 - means best compression
                    AddFile2Zip(zip, fi, "");
                    zip.Finish();
                    zip.Close();
                }
                else
                {
                    ICSharpCode.SharpZipLib.Zip.ZipFile zipExisting = new ICSharpCode.SharpZipLib.Zip.ZipFile(ZipFilePath);
                    zipExisting.BeginUpdate();
                    zipExisting.Add(OriginalFilePath);
                    zipExisting.CommitUpdate();
                    zipExisting.Close();
                    //zip = new ZipOutputStream(File.Create(ZipFilePath));
                }

            }
            catch (Exception ex)
            {
                throw ex;
            }
        }

        /// <summary>
        /// Comprime il contenuto di un file in formato ZIP
        /// </summary>
        /// <param name="ZipFilePath">Path del file compresso da creare</param>
        /// <param name="OriginalFilePath">Path del file da comprimere</param>
        public static void ZipFile(string ZipFilePath, string OriginalFilePath)
        {
            try
            {
                FileInfo fi = new FileInfo(OriginalFilePath);
                ZipOutputStream zip = new ZipOutputStream(File.Create(ZipFilePath));
                zip.UseZip64 = UseZip64.Off;
                zip.SetLevel(9);    // 0 - store only to 9 - means best compression
                AddFile2Zip(zip, fi, "");
                zip.Finish();
                zip.Close();
            }
            catch (Exception ex)
            {
                throw ex;
            }
        }


        /// <summary>
        /// Comprime il contenuto di più file in un file zip
        /// </summary>
        /// <param name="ZipFilePath">Path del file compresso da creare</param>
        /// <param name="OriginalFilePath">Path del file da comprimere</param>
        public static void ZipFiles(string ZipFilePath, string[] sFiles)
        {
            try
            {
                ZipOutputStream zip = new ZipOutputStream(File.Create(ZipFilePath));
                //Aggiunta da Raf in data 27-11-2008 perchè altrimente viene generato un file
                //con zip in formato 4.5 anzichè il 2.0
                zip.UseZip64 = UseZip64.Off;
                zip.SetLevel(9);    // 0 - store only to 9 - means best compression
                for (int intLoop = 0; intLoop < sFiles.Length; intLoop++)
                {
                    FileInfo fi = new FileInfo(sFiles[intLoop]);
                    AddFile2Zip(zip, fi, "");
                }
                zip.Finish();
                zip.Close();
            }
            catch (Exception ex)
            {
                throw ex;
            }
        }
        
        /// <summary>
        /// Comprime il contenuto di una cartella in formato ZIP, ricorsivamente e preservandone la struttura
        /// </summary>
        /// <param name="ZipFilePath">Path del file compresso da creare</param>
        /// <param name="OriginalFolderPath">Path della cartella da comprimere</param>
        public static void ZipFolder(string ZipFilePath, string OriginalFolderPath)
        {
            try
            {
                DirectoryInfo di = new DirectoryInfo(OriginalFolderPath);
                ZipOutputStream zip = new ZipOutputStream(File.Create(ZipFilePath));
                zip.SetLevel(6);    // 0 - store only to 9 - means best compression
                AddFolder2Zip(zip, di, "");
                zip.Finish();
                zip.Close();
            }
            catch (Exception ex)
            {
                throw ex;
            }
        }

        /// <summary>
        /// Decomprime un file compresso ZIP nella cartella di destinazione specificata
        /// </summary>
        /// <param name="ZipFilePath">Path del file ZIP da decomprimere</param>
        /// <param name="DestinationPath">Cartella di destinazione dell'archivio decompresso</param>
        public static void UnZip(string ZipFilePath, string DestinationPath)
        {
            string dp = (DestinationPath.EndsWith("\\")) ? DestinationPath : DestinationPath + @"\";
            ZipInputStream zip = new ZipInputStream(File.OpenRead(ZipFilePath));

            ICSharpCode.SharpZipLib.Zip.ZipEntry entry;
            while ((entry = zip.GetNextEntry()) != null)
            {
                if (entry.IsDirectory)
                    Directory.CreateDirectory(dp + entry.Name);
                else
                {
                    FileStream streamWriter = File.Create(dp + entry.Name);
                    int size = 2048;
                    byte[] data = new byte[2048];
                    while (true)
                    {
                        size = zip.Read(data, 0, data.Length);
                        if (size > 0)
                            streamWriter.Write(data, 0, size);
                        else
                            break;
                    }
                    streamWriter.Close();
                }
            }
            zip.Close();
        }

        #endregion

        #region private methods

        private static void AddFolder2Zip(ZipOutputStream zip, DirectoryInfo di, string internalzippath)
        {
            string izp = internalzippath + di.Name + "/";    // A directory is determined by an entry name with a trailing slash "/"
            Crc32 crc = new Crc32();
            ICSharpCode.SharpZipLib.Zip.ZipEntry entry = new ICSharpCode.SharpZipLib.Zip.ZipEntry(izp);
            entry.Crc = crc.Value;
            zip.PutNextEntry(entry);
            foreach (FileInfo fi in di.GetFiles())
                AddFile2Zip(zip, fi, izp);
            foreach (DirectoryInfo sdi in di.GetDirectories())
                AddFolder2Zip(zip, sdi, izp);
        }


        private static void AddFile2Zip(ZipOutputStream zip, FileInfo fi, string internalzippath)
        {
            // bytes da leggere e già letti
            int bytesRead;
            // definisco un buffer per la lettura da 200000 bytes
            byte[] mBuffer = new byte[200000];

            Crc32 crc = new Crc32();
            FileStream fs = File.OpenRead(fi.FullName);
            ICSharpCode.SharpZipLib.Zip.ZipEntry entry = new ICSharpCode.SharpZipLib.Zip.ZipEntry(internalzippath + fi.Name);
            crc.Reset();
            zip.PutNextEntry(entry);
            while (fs.Position < fs.Length)
            {
                bytesRead = fs.Read(mBuffer, 0, mBuffer.Length);
                zip.Write(mBuffer, 0, bytesRead);
                crc.Update(mBuffer, 0, bytesRead);
            }
            entry.Crc = crc.Value;
            entry.DateTime = File.GetCreationTime(fi.FullName);
            entry.Size = fs.Length;
            fs.Close();
        }

        #endregion
    }
}
