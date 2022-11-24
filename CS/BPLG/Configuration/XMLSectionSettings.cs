using System;
using System.Collections.Generic;
using System.Text;
using System.Xml;

namespace BPLG.Configuration
{
    public class XMLSectionSettings : ISettingsReader, ISettingsWriter
    {
        private XmlNode m_xmlNode;
        private string m_strXMLFileName;

        public XMLSectionSettings(string strXMLFileName,  XmlNode node)
        {
            m_strXMLFileName = strXMLFileName;
            m_xmlNode = node;
        }

        public string getParam(string paramName)
        {
            string value = "";
            value = m_xmlNode.SelectSingleNode(paramName).InnerText;
            return value;
        }


        #region ISettingsWriter Members

        public void setParam(string paramName, string paramValue)
        {
            m_xmlNode.SelectSingleNode(paramName).InnerText = paramValue;
            m_xmlNode.OwnerDocument.Save(m_strXMLFileName);
        }

        #endregion
    }
}
