using System;
using System.Collections.Generic;
using System.Text;
using System.Xml;

namespace BPLG.Configuration
{
    public class XMLFileParser : IParser
    {
        static XmlDocument ini;

        public XMLFileParser(string strFilePathAndName)
        {
            ini = new XmlDocument();
            ini.Load(strFilePathAndName);
        }

        public string ReadParameter(string sParamName)
        {
            string value = "";
            value = ini.DocumentElement.SelectSingleNode(sParamName).InnerText;
            return value;
        }
    }
}
