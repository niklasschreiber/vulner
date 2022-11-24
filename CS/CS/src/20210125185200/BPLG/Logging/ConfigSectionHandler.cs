using System;
using System.Collections.Generic;
using System.Text;
using System.Configuration;
using System.Xml;

namespace BPLG.Logging
{
    public class ConfigSectionHandler : ConfigurationSection
    {

        [ConfigurationProperty("FileSystemLoggers", IsDefaultCollection = false)]
        public ConfigFileSystemLoggerElementCollection FileSystemLoggers
        {
            get { return (ConfigFileSystemLoggerElementCollection)base["FileSystemLoggers"]; }
        }

        [ConfigurationProperty("EventViewerLoggers", IsDefaultCollection = false)]
        public ConfigEventViewerLoggerElementCollection EventViewerLoggers
        {
            get { return (ConfigEventViewerLoggerElementCollection)base["EventViewerLoggers"]; }
        }

        [ConfigurationProperty("EmailLoggers", IsDefaultCollection = false)]
        public ConfigEmailLoggerElementCollection EmailLoggers
        {
            get { return (ConfigEmailLoggerElementCollection)base["EmailLoggers"]; }
        }

    }
}
