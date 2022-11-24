using System;
using System.Collections.Generic;
using System.Configuration;
using System.Linq;
using System.Text;

namespace BPLG.Authentication
{
    public class ConfigSectionHandler : ConfigurationSection
    {
        [ConfigurationProperty("SecuritySettings", IsRequired = true)]
        internal ConfigSecurityElement SecuritySettings
        {
            get { return (ConfigSecurityElement)base["SecuritySettings"]; }
        }
    }
}
