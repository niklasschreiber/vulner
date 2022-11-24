using System;
using System.Data;
using System.Data.SqlClient;

namespace BPLG.Organigramma
{
    public class UserInfo
    {
        #region VARIABILI PRIVATE
        Data.DBHelper m_DB;
        Logging.Logger m_Logger;
        string m_sUserLogin;
        private string m_dbName;

        private object m_IDUtente;
        private string m_EmailAddress;
        private string m_DisplayName;
        private object m_IDStruttura;
        #endregion

        #region PROPERTIES
        public object IDUtente
        {
            get
            {
                return m_IDUtente;
            }
        }

        
        public string EmailAddress
        {
            get
            {
                return m_EmailAddress;
            }
        }

        
        public string DisplayName
        {
            get
            {
                return m_DisplayName;
            }
        }

        
        public object IDStruttura
        {
            get
            {
                return m_IDStruttura;
            }
        }
        #endregion

        #region COSTRUTTORE
        //2019-05-16 Mignano: Causa cambio logica dei nomi dei database, questo costruttore è stato reso obsoleto per rendere evidente nei vari progetti che usano la BPLG dove correggere il codice passando un oggetto DBHelper collegato ad organigramma.
        [Obsolete("Metodo deprecato in quanto questo metodo deve ricevere un oggetto DBHelper collegato al db ORGANIGRAMMA. Utilizzare l'altra firma disponibile controllando che venga passato un DBHelper corretto.", true)]
        public UserInfo(Data.DBHelper DB, Logging.Logger Logger, string sUserLogin)
        {
            m_DB = DB;
            m_Logger = Logger;
            m_sUserLogin = sUserLogin;
        }

        /// <summary>
        /// Costruttore della classe UserInfo: ATTENZIONE Passare come DBHelper un oggetto che punta al database ORGANIGRAMMA
        /// </summary>
        /// <param name="sUserLogin"></param>
        /// <param name="dbOrganigramma"></param>
        /// <param name="Logger"></param>
        public UserInfo(string sUserLogin, Data.DBHelper dbOrganigramma, Logging.Logger logger)
        {
            SqlConnection conn=null;
            try
            {
                m_DB = dbOrganigramma;
                m_sUserLogin = sUserLogin;
                m_Logger = logger;
                m_Logger.Username = sUserLogin;

                conn = m_DB.OpenConnection();
                m_dbName = conn.Database;
                
                SetUserFields(sUserLogin, m_dbName, m_DB);

            }
            catch(Exception ex)
            {
                m_Logger.Write(Logging.Logger.LogTypeMessage.Error, ex.Message);
                throw ex;
            }
            finally
            {
                if (conn != null && conn.State==ConnectionState.Open)
                {
                    conn.Close();
                }
            }
        }

        #endregion

        #region METODI PRIVATI
        /// <summary>
        /// Metodo deprecato. Deve essere passato un oggetto DBHelper collegato al db ORGANIGRAMMA non a qualsiasi altro db.
        /// </summary>
        /// <param name="DB"></param>
        /// <param name="Logger"></param>
        /// <param name="sUserLogin"></param>
        /// <param name="sFieldName"></param>
        /// <returns></returns>
        [Obsolete("Metodo deprecato in quanto questo metodo deve ricevere un oggetto DBHelper collegato al db ORGANIGRAMMA non qualsiasi altro dbHelper.",true)]
        private static object GetUserFieldValue(Data.DBHelper DB, Logging.Logger Logger, string sUserLogin, string sFieldName)
        {
            try
            {
                DataTable dtUser = DB.GetDataTableFormStoredProcedure("Organigramma.dbo.sp_PUB_GetUserOrganigrammaByLogin", new System.Data.SqlClient.SqlParameter[] {
                            new SqlParameter("@User",sUserLogin)
                        });
                if (dtUser.Rows.Count == 0)
                    throw new Exception("Sul database Organigramma non è stato trovato l'utente '" + sUserLogin + "'");
                else
                    return dtUser.Rows[0][sFieldName];
            }
            catch (Exception ex)
            {
                throw ex;
            }
        }

        //2019-05-16 Mignano: nuovo metodo, effettuo una chiamata unica al db per recuperare i dati dell'utente. 
        //2019-07-12 Medini: fix recupero idStruttura - le utenze di sistema (bSystemUser = true) NON hanno una struttura associata, pertanto questa non deve essere recuperata
        //Se verranno richieste ulteriori informazioni bisognerà aggiungere una variabile privata, una property e valorizzarla in questa function
        /// <summary>
        /// Metodo Privato che chiama la stored 'sp_PUB_GetUserOrganigrammaByLogin' utilizzando il nome del db recuperato dal costruttore.
        /// </summary>
        /// <param name="sUserLogin"></param>
        /// <param name="sDbName"></param>
        /// <param name="DB"></param>
        private void SetUserFields(string sUserLogin, string sDbName, Data.DBHelper DB)
        {
            try
            {
                string spName = string.Format("{0}.dbo.sp_PUB_GetUserOrganigrammaByLogin", sDbName);
                DataTable dtUser = DB.GetDataTableFormStoredProcedure(spName, new System.Data.SqlClient.SqlParameter[] {
                            new SqlParameter("@User", sUserLogin)
                        });
                if (dtUser.Rows.Count == 0)
                    throw new Exception("Sul database Organigramma non è stato trovato l'utente '" + sUserLogin + "'");
                else
                {
                    m_IDUtente = Convert.ToInt32(dtUser.Rows[0]["id"]);
                    m_DisplayName = Convert.ToString(dtUser.Rows[0]["Nome Utente"]);
                    m_EmailAddress = Convert.ToString(dtUser.Rows[0]["strEmail"]);

                    if (dtUser.Rows[0].Field<bool>("bSystemUser") == false)
                    {
                        m_IDStruttura = Convert.ToInt32(dtUser.Rows[0]["idStruttura"]);
                    }
                }
            }
            catch (Exception ex)
            {
                throw ex;
            }
        }

        #endregion
    }
}
