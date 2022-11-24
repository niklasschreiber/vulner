using System;
using System.Collections.Generic;
using System.Text;
using System.Configuration;
using System.Xml;

namespace BPLG.Logging
{
    [ConfigurationCollection(typeof(ConfigEventViewerLoggerElement),
       CollectionType = ConfigurationElementCollectionType.AddRemoveClearMap)]
    public class ConfigEventViewerLoggerElementCollection : ConfigurationElementCollection
    {

        #region Constructors
        static ConfigEventViewerLoggerElementCollection()
        {
            m_properties = new ConfigurationPropertyCollection();
        }

        public ConfigEventViewerLoggerElementCollection()
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
        public ConfigEventViewerLoggerElement this[int index]
        {
            get { return (ConfigEventViewerLoggerElement)base.BaseGet(index); }
            set
            {
                if (base.BaseGet(index) != null)
                {
                    base.BaseRemoveAt(index);
                }
                base.BaseAdd(index, value);
            }
        }

        public ConfigEventViewerLoggerElement this[string name]
        {
            get { return (ConfigEventViewerLoggerElement)base.BaseGet(name); }
        }
        #endregion

        #region Overrides
        protected override ConfigurationElement CreateNewElement()
        {
            return new ConfigEventViewerLoggerElement();
        }
        
        protected override object GetElementKey(ConfigurationElement element)
        {
            return (element as ConfigEventViewerLoggerElement).PK;
        }
        
        #endregion
    }
}
