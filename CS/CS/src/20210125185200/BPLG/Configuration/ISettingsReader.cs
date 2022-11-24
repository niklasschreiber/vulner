using System;
using System.Collections.Generic;
using System.Text;

namespace BPLG.Configuration
{
    public interface ISettingsReader
    {
        string getParam(string paramName);
    }
}
