using System;
using System.Collections.Generic;
using System.Text;
using System.Configuration;
using System.Xml;

namespace BPLG.Logging
{
    [ConfigurationCollection(typeof(ConfigFileSystemLoggerElement),
       CollectionType = ConfigurationElementCollectionType.AddRemoveClearMap)]
    public class ConfigFileSystemLoggerElementCollection : ConfigurationElementCollection
    {
        #region Constructors
        static ConfigFileSystemLoggerElementCollection()
        {
            m_properties = new ConfigurationPropertyCollection();
        }

        public ConfigFileSystemLoggerElementCollection()
        {
        }
        #endregion

        #region Fields
        private static ConfigurationPropertyCollection m_properties;
        #endregion

        #region Properties
        protected override ConfigurationPropertyCollection Properties
        {
            get { return m_properties; }
        }

        public override ConfigurationElementCollectionType CollectionType
        {
            get { return ConfigurationElementCollectionType.AddRemoveClearMap; }
        }
        #endregion

        #region Indexers
        public ConfigFileSystemLoggerElement this[int index]
        {
            get { return (ConfigFileSystemLoggerElement)base.BaseGet(index); }
            set
            {
                if (base.BaseGet(index) != null)
                {
                    base.BaseRemoveAt(index);
                }
                base.BaseAdd(index, value);
            }
        }

        public ConfigFileSystemLoggerElement this[string name]
        {
            get { return (ConfigFileSystemLoggerElement)base.BaseGet(name); }
        }
        #endregion

        #region Overrides
        protected override ConfigurationElement CreateNewElement()
        {
            return new ConfigFileSystemLoggerElement();
        }
        
        protected override object GetElementKey(ConfigurationElement element)
        {
            return (element as ConfigFileSystemLoggerElement).PK;
        }
        
        #endregion

    }
}



