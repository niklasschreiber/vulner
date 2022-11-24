using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.IO;

namespace BPLG.Utility
{
    public class FileUtility
    {
        public static List<string> ListOfExtensions = new List<string> 
        { 
            ".tif", 
            ".tiff",
            ".jpg",
            ".jpeg",
            ".gif",
            ".png",
            ".pdf",
            ".bmp"
        };

        public static string GetMimeTypeByFilename(String Filename)
        {
            string mimeType = string.Empty;
            try
            {
                string extension = Path.GetExtension(Filename).ToLowerInvariant();
                switch (extension)
                {
                    case ".html":
                        mimeType = "text/html";
                        break;
                    case ".tif":
                    case ".tiff":
                        mimeType = "image/tiff";
                        break;
                    case ".jpg":
                    case ".jpeg":
                        mimeType = "image/jpeg";
                        break;
                    case ".gif":
                        mimeType = "image/gif";
                        break;
                    case ".png":
                        mimeType = "image/png";
                        break;
                    case ".pdf":
                        mimeType = "application/pdf";
                        break;
                    case ".bmp":
                        mimeType = "image/bmp";
                        break;
                    default:
                        throw new Exception("Extension not present in the list of available extensions");
                }
                return mimeType;
            }
            catch (Exception Ex)
            {
                throw Ex;
            }
        }

        public static string GetMimeTypeByFilename(FileInfo FileItem)
        {
            string mimeType = string.Empty;
            try
            {
                return GetMimeTypeByFilename(FileItem.FullName);
            }
            catch (Exception Ex)
            {
                throw Ex;
            }
        }

        public static string GetMimeTypeByFilenameResolver(String Filename)
        {
            string mimeType = string.Empty;
            try
            {
                string extension = Path.GetExtension(Filename).ToLowerInvariant();
                switch (extension)
                {
                    case ".html":
                        mimeType = "text/html";
                        break;
                    case ".tif":
                    case ".tiff":
                        mimeType = "image/tiff";
                        break;
                    case ".jpg":
                    case ".jpeg":
                        mimeType = "image/jpeg";
                        break;
                    case ".gif":
                        mimeType = "image/gif";
                        break;
                    case ".png":
                        mimeType = "image/png";
                        break;
                    case ".pdf":
                        mimeType = "application/pdf";
                        break;
                    case ".bmp":
                        mimeType = "image/bmp";
                        break;
                    case ".doc":
                        mimeType = "application/msword";
                        break;
                    case ".docx":
                        mimeType = "application/vnd.openxmlformats-officedocument.wordprocessingml.document";
                        break;
                    case ".xls":
                        mimeType = "application/vnd.ms-excel";
                        break;
                    case ".xlsx":
                        mimeType = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet";
                        break;
                    default:
                        throw new Exception("Extension not present in the list of available extensions");
                }
                return mimeType;
            }
            catch (Exception Ex)
            {
                throw Ex;
            }
        }
        
        public static string GetMimeTypeByFilenameResolver(FileInfo FileItem)
        {
            string mimeType = string.Empty;
            try
            {
                return GetMimeTypeByFilenameResolver(FileItem.FullName);
            }
            catch (Exception Ex)
            {
                throw Ex;
            }
        }

        public static string GetMimeTypeByExtension(String FileExtension)
        {
            string mimeType = string.Empty;
            try
            {
                if (!FileExtension.Contains("."))
                {
                    FileExtension = "." + FileExtension;
                }
                switch (FileExtension)
                {
                    case ".html":
                        mimeType = "text/html";
                        break;
                    case ".tif":
                    case ".tiff":
                        mimeType = "image/tiff";
                        break;
                    case ".jpg":
                    case ".jpeg":
                        mimeType = "image/jpeg";
                        break;
                    case ".gif":
                        mimeType = "image/gif";
                        break;
                    case ".png":
                        mimeType = "image/png";
                        break;
                    case ".pdf":
                        mimeType = "application/pdf";
                        break;
                    case ".bmp":
                        mimeType = "image/bmp";
                        break;
                    default:
                        throw new Exception("Extension not present in the list of available extensions");
                }
                return mimeType;
            }
            catch (Exception Ex)
            {
                throw Ex;
            }
        }

        public static string GetExtensionByFilename(String Filename)
        {
            string mimeType = string.Empty;
            try
            {
                return Path.GetExtension(Filename);
            }
            catch (Exception Ex)
            {
                throw Ex;
            }
        }

        public static string GetExtensionByMimeType(String MimeType)
        {
            string extension = string.Empty;
            try
            {
                switch (MimeType)
                {
                    case "text/html":
                        extension = ".html";
                        break;
                    case "image/tiff":
                        extension = ".tif";
                        break;
                    case "image/jpeg":
                        extension = ".jpg";
                        break;
                    case "image/gif":
                        extension = ".gif";
                        break;
                    case "image/png":
                        extension = ".png";
                        break;
                    case "application/pdf":
                        extension = ".pdf";
                        break;
                    case "image/bmp":
                        extension = ".bmp";
                        break;
                    default:
                        throw new Exception("Extension not present in the list of available extensions");
                }
                return extension;
            }
            catch (Exception Ex)
            {
                throw Ex;
            }
        }

        public static string GetExtensionByMimeTypeResolver(String MimeType)
        {
            string extension = string.Empty;
            try
            {
                switch (MimeType)
                {
                    case "text/html":
                        extension = ".html";
                        break;
                    case "image/tiff":
                        extension = ".tif";
                        break;
                    case "image/jpeg":
                        extension = ".jpg";
                        break;
                    case "image/gif":
                        extension = ".gif";
                        break;
                    case "image/png":
                        extension = ".png";
                        break;
                    case "application/pdf":
                        extension = ".pdf";
                        break;
                    case "image/bmp":
                        extension = ".bmp";
                        break;
                    case "application/msword":
                        extension = ".doc";
                        break;
                    case "application/vnd.openxmlformats-officedocument.wordprocessingml.document":
                        extension = ".docx";
                        break;
                    case "application/vnd.ms-excel":
                        extension = ".xls";
                        break;
                    case "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet":
                        extension = ".xlsx";
                        break;
                    default:
                        throw new Exception("Extension not present in the list of available extensions");
                }
                return extension;
            }
            catch (Exception Ex)
            {
                throw Ex;
            }
        }

        public static string GetExtensionByMimeType_NoDot(String MimeType)
        {
            string extension = string.Empty;
            try
            {
                switch (MimeType)
                {
                    case "text/html":
                        extension = "html".ToUpper();
                        break;
                    case "image/tiff":
                        extension = "tif".ToUpper();
                        break;
                    case "image/jpeg":
                        extension = "jpg".ToUpper();
                        break;
                    case "image/gif":
                        extension = "gif".ToUpper();
                        break;
                    case "image/png":
                        extension = "png".ToUpper();
                        break;
                    case "application/pdf":
                        extension = "pdf".ToUpper();
                        break;
                    case "image/bmp":
                        extension = "bmp".ToUpper();
                        break;
                    default:
                        throw new Exception("Extension not present in the list of available extensions");
                }
                return extension;
            }
            catch (Exception Ex)
            {
                throw Ex;
            }
        }
    }
}
