using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Xml;
using System.Xml.Linq;

namespace BPLG.Archiving
{
    public static class ArchiverFactory
    {
        public static IArchiver GetArchiverInstance(XElement xelement)
        { 
            Archiver arc = xelement.DescendantsAndSelf("Archive")
                .Select(obj => new Archiver(
                    obj.Element("ArchiveFolder").Value,
                    Int32.Parse(obj.Element("ArchiveHistoryNumber").Value),
                    obj.Element("ArchiveSuffix").Value)).First();
            return arc;
        }

        public static IArchiver GetArchiverInstance(string XMLConfigurationFileName)
        {
            return GetArchiverInstance(XElement.Load(XMLConfigurationFileName).DescendantsAndSelf("Archive").First());
        }
        
    }
}
