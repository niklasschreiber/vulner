using System;
using System.Collections.Generic;
using System.Configuration;
using System.Linq;
using System.Text;

namespace BPLG.Authentication
{
    internal class ConfigSecurityElement : ConfigurationElement
    {
        #region Static Fields
        private static ConfigurationProperty s_propSecurityType;
        private static ConfigurationProperty s_propPolicyAppName;
        private static ConfigurationProperty s_propSecDBConn;
        private static ConfigurationProperty s_propSecDBSchemaName;
        private static ConfigurationProperty s_propSec_SMTPServer;
        private static ConfigurationPropertyCollection s_properties;
        #endregion

        #region Properties
        [ConfigurationProperty("securitytype", IsRequired = true)]
        public string SecurityType
        {
            get { return (string)base[s_propSecurityType]; }
        }

        [ConfigurationProperty("policyappname", IsRequired = true)]
        public string PolicyAppName
        {
            get { return (string)base[s_propPolicyAppName]; }
        }

        [ConfigurationProperty("secdbconn", IsRequired = true)]
        public string SecDBConn
        {
            get { return (string)base[s_propSecDBConn]; }
        }

        [ConfigurationProperty("secdbschemaname")]
        public string SecDBSchemaName
        {
            get { return (string)base[s_propSecDBSchemaName]; }
        }

        [ConfigurationProperty("secsmtpserver", IsRequired = true)]
        public string SecSMTPServer
        {
            get { return (string)base[s_propSec_SMTPServer]; }
        }

        /// <summary>
        /// Override the Properties collection and return our custom one.
        /// </summary>
        protected override ConfigurationPropertyCollection Properties
        {
            get { return s_properties; }
        }
        #endregion

        #region Constructors
        /// <summary>
        /// Predefines the valid properties and prepares
        /// the property collection.
        /// </summary>
        static ConfigSecurityElement()
        {
            // Predefine properties here
            s_propSecurityType = new ConfigurationProperty(
                "securitytype",
                typeof(string),
                null,
                ConfigurationPropertyOptions.IsRequired
            );

            s_propPolicyAppName = new ConfigurationProperty(
                "policyappname",
                typeof(string),
                null,
                ConfigurationPropertyOptions.IsRequired
            );

            s_propSecDBConn = new ConfigurationProperty(
                "secdbconn",
                typeof(string),
                null,
                ConfigurationPropertyOptions.IsRequired
            );

            s_propSecDBSchemaName = new ConfigurationProperty(
                "secdbschemaname",
                typeof(string),
                "",
                ConfigurationPropertyOptions.None
            );

            s_propSec_SMTPServer = new ConfigurationProperty(
                "secsmtpserver",
                typeof(string),
                null,
                ConfigurationPropertyOptions.IsRequired
            );

            s_properties = new ConfigurationPropertyCollection();

            s_properties.Add(s_propSecurityType);
            s_properties.Add(s_propPolicyAppName);
            s_properties.Add(s_propSecDBConn);
            s_properties.Add(s_propSecDBSchemaName);
            s_properties.Add(s_propSec_SMTPServer);
        }
        #endregion
    }
}
