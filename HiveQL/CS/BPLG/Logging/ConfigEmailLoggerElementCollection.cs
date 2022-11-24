using System;
using System.Collections.Generic;
using System.Text;
using System.Configuration;
using System.Xml;

namespace BPLG.Logging
{
    [ConfigurationCollection(typeof(ConfigEmailLoggerElement),
       CollectionType = ConfigurationElementCollectionType.AddRemoveClearMap)]
    public class ConfigEmailLoggerElementCollection : ConfigurationElementCollection
    {

        #region Constructors
        static ConfigEmailLoggerElementCollection()
        {
            m_properties = new ConfigurationPropertyCollection();
        }

        public ConfigEmailLoggerElementCollection()
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
        public ConfigEmailLoggerElement this[int index]
        {
            get { return (ConfigEmailLoggerElement)base.BaseGet(index); }
            set
            {
                if (base.BaseGet(index) != null)
                {
                    base.BaseRemoveAt(index);
                }
                base.BaseAdd(index, value);
            }
        }

        public ConfigEmailLoggerElement this[string name]
        {
            get { return (ConfigEmailLoggerElement)base.BaseGet(name); }
        }
        #endregion

        #region Overrides
        protected override ConfigurationElement CreateNewElement()
        {
            return new ConfigEmailLoggerElement();
        }
        
        protected override object GetElementKey(ConfigurationElement element)
        {
            return (element as ConfigEmailLoggerElement).PK;
        }
        
        #endregion
    }
}
