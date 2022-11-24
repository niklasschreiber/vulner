using System;
using System.Data;
using System.Collections.Generic;
using System.Text;

namespace BPLG.Internazionalizzazione
{
    /// <summary>
    /// Classe per la localizzazione delle risorse basata su database
    /// </summary>
    public class DBResource : ILocalizzazione
    {
        private Data.DBHelper db;
        private const string c_DefaultLanguage = "ITA";
        private string m_sIDLingua = null;

        /// <summary>
        /// Costruttore al quale passiamo la stringa di connessione al database per la localizzazione
        /// </summary>
        /// <param name="sDBLocalizzazioneConnectionString"></param>
        public DBResource(string sDBLocalizzazioneConnectionString)
        {
            db = new Data.DBHelper(sDBLocalizzazioneConnectionString);
        }

        #region ILocalizzazione Members

        public string GetRisorsa(string sIDLingua, string sIDRisorsa)
        {
            DataRow dr = db.GetDataTableFormStoredProcedure("Intern.sp_GetRisorsaTesto", new System.Data.SqlClient.SqlParameter[] {
                new System.Data.SqlClient.SqlParameter("@sIDLingua",sIDLingua)
                ,new System.Data.SqlClient.SqlParameter("@sIDRisorsa",sIDRisorsa)
                }).Rows[0];
            return Convert.ToString(dr["sResult"]);
        }

        public void SetIDLingua(string sIDLingua)
        {
            m_sIDLingua = sIDLingua;
        }

        public string GetRisorsa(string sIDRisorsa)
        {
            if (m_sIDLingua != null && m_sIDLingua.Trim() != "")
                return GetRisorsa(m_sIDLingua, sIDRisorsa);
            else
                return GetRisorsa(c_DefaultLanguage, sIDRisorsa);
        }

        #endregion
    }
}
