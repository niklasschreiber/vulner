using System;
using System.Collections.Generic;
using System.Text;
using System.Configuration;

namespace BPLG.Configuration
{
    public class WebConfigParser : IParser
    {
        public string ReadParameter(string sParamName)
        {
            return ConfigurationManager.AppSettings.Get(sParamName);
        }
    }
}
