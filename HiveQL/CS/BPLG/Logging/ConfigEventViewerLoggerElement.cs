using System;
using System.Collections.Generic;
using System.Text;
using System.Configuration;
using System.Xml;

namespace BPLG.Logging
{
    public class ConfigEventViewerLoggerElement : ConfigurationElement
    {
        #region Constructors
        /// <summary>
        /// Predefines the valid properties and prepares
        /// the property collection.
        /// </summary>
        static ConfigEventViewerLoggerElement()
        {
            // Predefine properties here
            s_propPK = new ConfigurationProperty(
                "PK",
                typeof(int),
                null,
                ConfigurationPropertyOptions.IsRequired
            );

            s_propEvents = new ConfigurationProperty(
                "events",
                typeof(int),
                null,
                ConfigurationPropertyOptions.IsRequired
            );

            s_propAppName = new ConfigurationProperty(
                "appname",
                typeof(string),
                null,
                ConfigurationPropertyOptions.IsRequired
            );


            s_properties = new ConfigurationPropertyCollection();

            s_properties.Add(s_propPK);
            s_properties.Add(s_propEvents);
            s_properties.Add(s_propAppName);
        }
        #endregion

        #region Static Fields
        private static ConfigurationProperty s_propPK;
        private static ConfigurationProperty s_propEvents;
        private static ConfigurationProperty s_propAppName;
        private static ConfigurationPropertyCollection s_properties;
        #endregion

        #region Properties

        [ConfigurationProperty("pk", IsRequired = true)]
        public int PK
        {
            get { return (int)base[s_propPK]; }
        }

        [ConfigurationProperty("events", IsRequired = true)]
        public int Events
        {
            get { return (int)base[s_propEvents]; }
        }

        [ConfigurationProperty("appname")]
        public string AppName
        {
            get { return (string)base[s_propAppName]; }
        }

        /// <summary>
        /// Override the Properties collection and return our custom one.
        /// </summary>
        protected override ConfigurationPropertyCollection Properties
        {
            get { return s_properties; }
        }
        #endregion
    }
}
