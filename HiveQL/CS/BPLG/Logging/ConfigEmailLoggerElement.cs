using System;
using System.Collections.Generic;
using System.Text;
using System.Configuration;
using System.Xml;

namespace BPLG.Logging
{
    public class ConfigEmailLoggerElement : ConfigurationElement
    {
        #region Constructors
        /// <summary>
        /// Predefines the valid properties and prepares
        /// the property collection.
        /// </summary>
        static ConfigEmailLoggerElement()
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



            s_propSmtpServer = new ConfigurationProperty(
                "smtpserver",
                typeof(string),
                null,
                ConfigurationPropertyOptions.IsRequired
            );


            s_propFrom = new ConfigurationProperty(
                "from",
                typeof(string),
                null,
                ConfigurationPropertyOptions.IsRequired
            );


            s_propTo = new ConfigurationProperty(
                "to",
                typeof(string),
                null,
                ConfigurationPropertyOptions.IsRequired
            );


            s_properties = new ConfigurationPropertyCollection();

            s_properties.Add(s_propPK);
            s_properties.Add(s_propEvents);
            s_properties.Add(s_propAppName);
            s_properties.Add(s_propSmtpServer);
            s_properties.Add(s_propFrom);
            s_properties.Add(s_propTo);
        }
        #endregion

        #region Static Fields
        private static ConfigurationProperty s_propPK;
        private static ConfigurationProperty s_propEvents;
        private static ConfigurationProperty s_propAppName;
        private static ConfigurationProperty s_propSmtpServer;
        private static ConfigurationProperty s_propFrom;
        private static ConfigurationProperty s_propTo;
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

        [ConfigurationProperty("smtpserver")]
        public string SmtpServer
        {
            get { return (string)base[s_propSmtpServer]; }
        }


        [ConfigurationProperty("from")]
        public string From
        {
            get { return (string)base[s_propFrom]; }
        }


        [ConfigurationProperty("to")]
        public string To
        {
            get { return (string)base[s_propTo]; }
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
