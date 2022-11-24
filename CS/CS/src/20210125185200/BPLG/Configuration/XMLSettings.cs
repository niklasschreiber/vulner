using System;
using System.Collections.Generic;
using System.Text;
using System.Xml;

namespace BPLG.Configuration
{
    public class XMLSettings : ISettingsReader
    {
        static XmlDocument ini;
        private string m_strXMLFileName;

        public XMLSettings(string strConfig)
        {
            m_strXMLFileName = strConfig;
            ini = new XmlDocument();
            ini.Load(strConfig);
        }

        public string getParam(string paramName)
        {
            string value = "";
            value = ini.DocumentElement.SelectSingleNode(paramName).InnerText;
            return value;
        }

        public XMLSectionSettings getSection(string strSectionName)
        {
            return new XMLSectionSettings(m_strXMLFileName, ini.DocumentElement.SelectSingleNode(strSectionName));
        }

    }
}
