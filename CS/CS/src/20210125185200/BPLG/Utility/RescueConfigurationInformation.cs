using System;
using System.Collections.Generic;
using System.Configuration;
using System.Linq;
using System.Text;

namespace BPLG.Utility
{
    public class CustomSectionConfiguration : ConfigurationSection
    {
        [ConfigurationProperty("Application", IsRequired = true)]
        public string Application
        {
            get
            {
                return this["Application"] as string;
            }
        }

        [ConfigurationProperty("ListDatabase")]
        public CustomSectionConfigurationStateCollection ListDatabase
        {
            get
            {
                return this["ListDatabase"] as CustomSectionConfigurationStateCollection;
            }
        }
    }

    public class CustomSectionConfigurationState : ConfigurationElement
    {
        [ConfigurationProperty("name", IsRequired = true)]
        public string Name
        {
            get
            {
                return this["name"] as string;
            }
        }

        [ConfigurationProperty("value", IsRequired = true)]
        public string Value
        {
            get
            {
                return this["value"] as string;
            }
        }
    }

    [ConfigurationCollection(typeof(CustomSectionConfigurationState))]
    public class CustomSectionConfigurationStateCollection : ConfigurationElementCollection
    {
        public CustomSectionConfigurationState this[int index]
        {
            get
            {
                return base.BaseGet(index) as CustomSectionConfigurationState;
            }
            set
            {
                if (base.BaseGet(index) != null) { base.BaseRemoveAt(index); }
                this.BaseAdd(index, value);
            }
        }

        protected override ConfigurationElement CreateNewElement()
        {
            return new CustomSectionConfigurationState();
        }

        protected override object GetElementKey(ConfigurationElement element)
        {
            return ((CustomSectionConfigurationState)element).Name;
        }
    }

    public class RescueConfigurationInformation
    {
        private CustomSectionConfiguration configInfo = null;

        public RescueConfigurationInformation()
        {
            configInfo = (CustomSectionConfiguration)ConfigurationManager.GetSection("ConnectionList");
        }

        public string GetApplication
        {
            get
            {
                return configInfo.Application;
            }
        }
        public string GetConfiguration(string Database)
        {
            return configInfo.ListDatabase.Cast<CustomSectionConfigurationState>().FirstOrDefault(item => item.Name == Database).Value;
        }
    }
}
