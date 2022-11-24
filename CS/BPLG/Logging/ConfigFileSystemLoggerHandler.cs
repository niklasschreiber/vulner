using System;
using System.Collections.Generic;
using System.Text;
using System.Configuration;
using System.Xml;

namespace BPLG.Logging
{
    public class ConfigFileSystemLoggerHandler : ConfigurationSection
    {
        [ConfigurationProperty("FileSystemLoggers", IsDefaultCollection = false)]
        public ConfigFileSystemLoggerElementCollection FileSystemLoggers
        {
            get { return (ConfigFileSystemLoggerElementCollection)base["FileSystemLoggers"]; }
        }

    }
}
