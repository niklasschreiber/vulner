using System;
using System.Collections.Generic;
using System.Text;

namespace BPLG.Internazionalizzazione
{
    /// <summary>
    /// Interfaccia per la localizzazione delle risorse per la gestione del multilingua
    /// </summary>
    public interface ILocalizzazione
    {
        string GetRisorsa(string sIDLingua, string sIDRisorsa);
        void SetIDLingua(string sIDLingua);
        string GetRisorsa(string sIDRisorsa);
    }
}
