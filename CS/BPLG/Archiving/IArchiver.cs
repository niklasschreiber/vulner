using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using BPLG.Logging;

namespace BPLG.Archiving
{
    public interface IArchiver
    {
        bool MoveAndArchiveFile(string sFileToArchive, string sDestinationFolder);
        bool MoveAndArchiveFile(ILogger log, string sFileToArchive, string sDestinationFolder);
    }
}
