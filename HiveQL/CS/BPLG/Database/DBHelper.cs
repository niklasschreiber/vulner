using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using BPLG.Logging;

namespace BPLG.Database
{
    public class DBHelperCollection
    {
        #region VARIABLES
        private static List<DBHelper> m_DBHelpers = new List<DBHelper>();
        #endregion VARIABLES

        #region CTOR
        private DBHelperCollection() { }
        #endregion CTOR

        #region METHODS
        public static DBHelper Instance(string ApplicationName, string Database, Logger MainLogger)
        { 
            DBHelper DatabaseFound = null;
            DatabaseFound = m_DBHelpers.FirstOrDefault(item => item.DatabaseRequested == Database);
            if (DatabaseFound == null)
            {
                DatabaseFound = new DBHelper();
                DatabaseFound.Logger = MainLogger;
                DatabaseFound.RescueConnectionString(ApplicationName, Database);
                m_DBHelpers.Add(DatabaseFound);
            }
            return DatabaseFound;
            
        }
        public static DBHelper Instance(string ApplicationName, string Database)
        {
            return Instance(ApplicationName, Database, null);
        }

        public static DBHelper Instance()
        {
            return new DBHelper();
        }

        public static DBHelper Instance(string ConnectionString)
        {
            DBHelper dbRequest = new DBHelper();
            dbRequest.ConnectionString = ConnectionString;
            return dbRequest;
        }
        #endregion METHODS
    }

    public class DBHelper
    {
        #region MEMBER
        private string m_DatabaseRequested = null;
        private string m_ConnectionString = string.Empty;
        private static Logger m_Logger = null;
        private int m_CommandTimeout = 0;
        #endregion MEMBER

        #region CTOR
        internal DBHelper() { }
        #endregion CTOR

        #region PROPERTIES
        public string ConnectionString
        {
            internal get { return m_ConnectionString; }
            set { m_ConnectionString = value; }
        }
        public int CommandTimeout
        {
            get { return m_CommandTimeout; }
            set { m_CommandTimeout = value; }
        }
        public Logger Logger
        {
            set { m_Logger = value; }
        }
        internal string DatabaseRequested
        {
            get
            {
                return m_DatabaseRequested;
            }
            set
            {
                m_DatabaseRequested = value;
            }
        }
        #endregion PROPERTIES

        #region METHODS
        internal SqlConnection OpenConnection()
        {
            SqlConnection connectionRequested = null;
            try
            {
                connectionRequested = new SqlConnection(ConnectionString);
                connectionRequested.Open();
            }
            catch (System.Exception ex)
            {
                if (m_Logger != null)
                    m_Logger.Write(Logger.LogTypeMessage.Error, ex.Message, ex);
                throw ex;
            }
            return connectionRequested;
        }

        public void RescueConnectionString(string ApplicationName, string Database)
        {
            try
            {
                ConnectionManager.Configuration_Manager connection = new ConnectionManager.Configuration_Manager();
                connection.Url = ConfigurationManager.AppSettings["ServiceUrl"];
                connection.UseDefaultCredentials = true;

                m_ConnectionString = connection.GetConnectionString(ApplicationName, Database);
                DatabaseRequested = Database;
            }
            catch (Exception ex)
            {
                if (m_Logger != null)
                    m_Logger.Write(Logger.LogTypeMessage.Error, ex.Message, ex);
                throw new Exception("Impossibile collegarsi alla Factory delle connection");
            }
        }

        #region RETURN DATATABLE
        public int GetReturnValueFormStoredProcedure(string strSPName)
        {
            return GetReturnValueFormStoredProcedure(strSPName, null);
        }

        public int GetReturnValueFormStoredProcedure(string strSPName, SqlParameter[] pars)
        {
            
            return Task.Factory.StartNew(() =>
            {
                if (pars != null)
                {
                    Array.Resize<SqlParameter>(ref pars, pars.Length + 1);
                }
                else 
                {
                    pars = new SqlParameter[1];
                }
                
                SqlParameter retParam = new SqlParameter("@retValue", SqlDbType.Int);
                retParam.Direction = ParameterDirection.ReturnValue;
                pars[pars.Length - 1] = retParam;

                //SqlConnection con = OpenConnection();
                using (SqlConnection con = OpenConnection()) { 
                    ExecuteStoredProcedure(con, strSPName, null, pars);
                }
                return Convert.ToInt32(retParam.Value);
            }).Result;
        }

        public DataTable GetDataTableFormStoredProcedure(string strSPName)
        {
            return GetDataTableFormStoredProcedure(strSPName, null);
        }

        public DataTable GetDataTableFormStoredProcedure(string strSPName, SqlParameter[] pars)
        {
            return Task.Factory.StartNew(() =>
            {
                DataTable dtResult = null;
                using (SqlConnection con = OpenConnection())
                {
                    //SqlConnection con = OpenConnection();
                    dtResult = GetDataTableFormStoredProcedure(con, strSPName, "tblGen", null, pars, CommandTimeout);
                }
                return dtResult;
            }).Result;
        }

        public DataTable GetDataTableFormStoredProcedure(string strSPName, string strTableName, SqlParameter[] pars)
        {
            return Task.Factory.StartNew(() =>
            {
                DataTable dtResult = null;
                using (SqlConnection con = OpenConnection())
                {
                    dtResult = GetDataTableFormStoredProcedure(con, strSPName, strTableName, null, pars, CommandTimeout);
                }
                return dtResult;
            }).Result;
        }

        public DataTable GetDataTableFormStoredProcedure(string strSPName, string strTableName, SqlTransaction tran, SqlParameter[] pars)
        {
            return Task.Factory.StartNew(() =>
            {
                DataTable dtResult = null;
                using (SqlConnection con = OpenConnection())
                {
                    //SqlConnection con = OpenConnection();
                    dtResult = GetDataTableFormStoredProcedure(con, strSPName, strTableName, tran, pars, CommandTimeout);
                }
                return dtResult;
            }).Result;
        }

        public void GetDataSetFromStoredProcedure<T>(string strSPName, string strTableName, SqlParameter[] pars, ref T DataSet)
        {
            try
            {
                SqlConnection con = OpenConnection();
                SqlCommand cmdSelect = new SqlCommand();
                cmdSelect.Connection = con;
                cmdSelect.CommandText = strSPName;
                cmdSelect.CommandType = CommandType.StoredProcedure;
                cmdSelect.CommandTimeout = CommandTimeout;
                SqlDataAdapter da = new SqlDataAdapter();

                if (!(pars == null))
                {
                    for (int intPar = 0; intPar <= pars.Length - 1; intPar++)
                    {
                        cmdSelect.Parameters.Add(pars[intPar]);
                    }
                }

                da.SelectCommand = cmdSelect;
                da.TableMappings.Add("Table", strTableName);
                da.Fill(DataSet as DataSet);
            }
            catch (Exception ex)
            {
                if (m_Logger != null)
                    m_Logger.Write(Logger.LogTypeMessage.Error, ex.Message, ex);
                throw ex;
            }
        }
        #endregion RETURN DATATABLE

        #region EXECUTE STORED
        public void ExecuteStoredProcedure(string strSPName, SqlParameter[] pars)
        {
            Task.Factory.StartNew(() =>
            {
                using (SqlConnection con = OpenConnection())
                {
                    ExecuteStoredProcedure(con, strSPName, null, pars, CommandTimeout);
                }
            });
        }

        public void ExecuteStoredProcedure(string strSPName, ref SqlParameter[] pars)
        {
            using (SqlConnection con = OpenConnection())
            {
                ExecuteStoredProcedure(con, strSPName, null, ref pars, CommandTimeout);
            }
        }

        public void ExecuteStoredProcedure(string strSPName, SqlTransaction tran)
        {
            Task.Factory.StartNew(() =>
            {
                using (SqlConnection con = OpenConnection())
                {
                    ExecuteStoredProcedure(con, strSPName, tran, null, CommandTimeout);
                }
            });
        }

        public void ExecuteStoredProcedure(string strSPName, SqlTransaction tran, SqlParameter[] pars)
        {
            Task.Factory.StartNew(() =>
            {
                using (SqlConnection con = OpenConnection())
                {
                    ExecuteStoredProcedure(con, strSPName, tran, pars, CommandTimeout);
                }
            });
        }

        public void ExecuteStoredProcedure(string strSPName, SqlTransaction tran, ref SqlParameter[] pars)
        {
            SqlConnection con = OpenConnection();
            ExecuteStoredProcedure(con, strSPName, tran, ref pars, CommandTimeout);
        }
        #endregion EXECUTE STORED
        #endregion METHODS

        #region STATIC METHODS
        public static DataTable GetDataTableFormStoredProcedure(SqlConnection conGen, string strSPName)
        {
            return GetDataTableFormStoredProcedure(conGen, strSPName, "ReturnTable", null, null);
        }

        public static DataTable GetDataTableFormStoredProcedure(SqlConnection conGen, string strSPName, string strTableName, SqlParameter[] pars)
        {
            return GetDataTableFormStoredProcedure(conGen, strSPName, strTableName, null, pars);
        }

        public static DataTable GetDataTableFormStoredProcedure(SqlConnection conGen, string strSPName, string strTableName, SqlTransaction tran, SqlParameter[] pars)
        {
            try
            {
                return GetDataTableFormStoredProcedure(conGen, strSPName, strTableName, tran, pars, 0);
            }
            catch (Exception ex)
            {
                if (m_Logger != null)
                    m_Logger.Write(Logger.LogTypeMessage.Error, ex.Message, ex);
                throw ex;
            }
        }

        public static DataTable GetDataTableFormStoredProcedure(SqlConnection conGen, string strSPName, string strTableName, SqlTransaction tran, SqlParameter[] pars, int intCommandTimeout)
        {
            DataSet ds = new DataSet();
            try
            {
                SqlCommand cmdSelect = new SqlCommand();
                if (tran != null) cmdSelect.Transaction = tran;
                cmdSelect.Connection = conGen;
                cmdSelect.CommandText = strSPName;
                cmdSelect.CommandType = CommandType.StoredProcedure;
                cmdSelect.CommandTimeout = intCommandTimeout;
                SqlDataAdapter da = new SqlDataAdapter();

                if (!(pars == null))
                {
                    for (int intPar = 0; intPar <= pars.Length - 1; intPar++)
                    {
                        cmdSelect.Parameters.Add(pars[intPar]);
                    }
                }

                da.SelectCommand = cmdSelect;
                da.TableMappings.Add("Table", strTableName);
                da.Fill(ds);
            }
            catch (Exception ex)
            {
                if (m_Logger != null)
                    m_Logger.Write(Logger.LogTypeMessage.Error, ex.Message, ex);
                throw ex;
            }
            return ds.Tables[strTableName];
        }

        public static void ExecuteStoredProcedure(SqlConnection conGen, string strSPName, SqlTransaction tran, SqlParameter[] pars)
        {
            try
            {
                ExecuteStoredProcedure(conGen, strSPName, tran, pars, 0);
            }
            catch (Exception ex)
            {
                if (m_Logger != null)
                    m_Logger.Write(Logger.LogTypeMessage.Error, ex.Message, ex);
                throw ex;
            }
        }

        public static void ExecuteStoredProcedure(SqlConnection conGen, string strSPName, SqlTransaction tran, ref SqlParameter[] pars)
        {
            try
            {
                ExecuteStoredProcedure(conGen, strSPName, tran, ref pars, 0);
            }
            catch (Exception ex)
            {
                if (m_Logger != null)
                    m_Logger.Write(Logger.LogTypeMessage.Error, ex.Message, ex);
                throw ex;
            }
        }

        public static void ExecuteStoredProcedure(SqlConnection conGen, string strSPName, SqlTransaction tran, SqlParameter[] pars, int intCommandTimeout)
        {
            DataSet ds = new DataSet();
            try
            {
                SqlCommand cmdExec = new SqlCommand();
                if (tran != null) cmdExec.Transaction = tran;
                cmdExec.Connection = conGen;
                cmdExec.CommandText = strSPName;
                cmdExec.CommandType = CommandType.StoredProcedure;
                if (!(pars == null))
                {
                    for (int intPar = 0; intPar <= pars.Length - 1; intPar++)
                        cmdExec.Parameters.Add(pars[intPar]);
                }
                cmdExec.CommandTimeout = intCommandTimeout;
                cmdExec.ExecuteNonQuery();
            }
            catch (Exception ex)
            {
                if (m_Logger != null)
                    m_Logger.Write(Logger.LogTypeMessage.Error, ex.Message, ex);
                throw ex;
            }
        }

        public static void ExecuteStoredProcedure(SqlConnection conGen, string strSPName, SqlTransaction tran, ref SqlParameter[] pars, int intCommandTimeout)
        {
            DataSet ds = new DataSet();
            try
            {
                SqlCommand cmdExec = new SqlCommand();
                if (tran != null) cmdExec.Transaction = tran;
                cmdExec.Connection = conGen;
                cmdExec.CommandText = strSPName;
                cmdExec.CommandType = CommandType.StoredProcedure;
                if (!(pars == null))
                {
                    for (int intPar = 0; intPar <= pars.Length - 1; intPar++)
                        cmdExec.Parameters.Add(pars[intPar]);
                }
                cmdExec.CommandTimeout = intCommandTimeout;
                cmdExec.ExecuteNonQuery();
            }
            catch (Exception ex)
            {
                if (m_Logger != null)
                    m_Logger.Write(Logger.LogTypeMessage.Error, ex.Message, ex);
                throw ex;
            }
        }
        #endregion STATIC METHODS

        #region UTILITY
        public static string DataTableToCSV(DataTable dt)
        {
            string sSeparatorChar = ";";
            string sNewLine = "\r\n";
            StringBuilder sb = new StringBuilder();
            if (dt.Columns.Count > 0)
            {
                //Gestione delle intestazini colonne
                sb.Append(FormatCSVField(dt.Columns[0].ColumnName));
                for (int nLoopColumn = 1; nLoopColumn < dt.Columns.Count; nLoopColumn++)
                {
                    sb.Append(string.Concat(sSeparatorChar, FormatCSVField(dt.Columns[nLoopColumn].ColumnName)));
                }
                sb.Append(sNewLine);

                //Gestione delle righe dati
                foreach (DataRow row in dt.Rows)
                {
                    sb.Append(FormatCSVField(row.ItemArray[0].ToString()));
                    for (int nLoopColumn = 1; nLoopColumn < dt.Columns.Count; nLoopColumn++)
                    {
                        sb.Append(string.Concat(sSeparatorChar, FormatCSVField(row.ItemArray[nLoopColumn].ToString())));
                    }
                    sb.Append(sNewLine);
                }
            }
            return sb.ToString();
        }
        private static string FormatCSVField(string sFieldValue)
        {
            return string.Concat("\"", sFieldValue.Replace("\"", "\"\""), "\"");
        }
        #endregion UTILITY
    }
}
