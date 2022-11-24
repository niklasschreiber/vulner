using System;
using System.Collections.Generic;
using System.Text;

namespace BPLG.Configuration
{
    public interface IParser
    {
        string ReadParameter(string sParamName);
    }
}
