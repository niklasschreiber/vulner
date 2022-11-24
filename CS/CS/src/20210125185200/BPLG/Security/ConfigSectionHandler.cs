using System;
using System.Collections.Generic;
using System.Text;
using System.Configuration;
using System.Xml;

namespace BPLG.Security
{
    public class ConfigSectionHandler : ConfigurationSection
    {

        //tutte le proprietà trascodificate...
        //SecuritySettings
        [ConfigurationProperty("SecuritySettings", IsRequired=true)]
        public ConfigSecurityElement SecuritySettings
        {
            get { return (ConfigSecurityElement)base["SecuritySettings"]; }
        }


    }
}
