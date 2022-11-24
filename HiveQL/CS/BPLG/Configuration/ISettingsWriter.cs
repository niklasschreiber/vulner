using System;
using System.Collections.Generic;
using System.Text;

namespace BPLG.Configuration
{
    public interface ISettingsWriter
    {
        void setParam(string paramName, string paramValue);
    }
}
