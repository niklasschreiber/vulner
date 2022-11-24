using System;
using System.Collections.Generic;
using System.Text;
using System.Drawing.Printing;

namespace BPLG.Reporting
{
    internal class SSRSReportPrinter : PrintDocument
    {
        internal SSRSReport m_MasterReport = null;

        public SSRSReportPrinter(SSRSReport Master)
        {
            m_MasterReport = Master;
        }

        internal void PrintReport()
        {
        }
    }
}
