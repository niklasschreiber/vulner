using System;
using System.Collections.Generic;
using System.Text;

namespace BPLG.Logging
{
    public abstract class SpecLogger : ILogger
    {
        private int m_intTraceLavel;
        public SpecLogger(int intTraceLavel)
        {
            m_intTraceLavel = intTraceLavel;
        }

        protected bool ValidTraceLevel(Logger.LogTypeMessage Type)
        {
            return ((Convert.ToInt32(Type) & m_intTraceLavel) == Convert.ToInt32(Type));
        }

        public abstract void Write(Logger.LogTypeMessage Type, string strMessage);
    }
}
