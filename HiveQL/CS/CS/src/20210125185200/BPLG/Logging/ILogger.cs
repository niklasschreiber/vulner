using System;
using System.Collections.Generic;
using System.Text;
using System.Diagnostics;

namespace BPLG.Logging
{
    /*
     * Interfaccia generica per il logging
     */
    public interface ILogger
    {
        void Write(Logger.LogTypeMessage Type, string strMessage);
    }
}
