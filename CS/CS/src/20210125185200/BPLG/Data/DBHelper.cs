using System;
using System.Data;
using System.Data.SqlClient;
using System.Collections;
using System.Collections.Generic;
using System.Text;
using BPLG.Logging;
using System.IO;

namespace BPLG.Data
{
    public class DBHelper
    {

        #region Attributi privati della classe

        private string m_strConnectionString = "";
        private static Logger m_Logger = null;
        private int m_intCommandTimeout = 0;

        #endregion

        #region Costruttori

        public DBHelper(string strConnectionString)
        {
            m_strConnectionString = strConnectionString;
        }
        public DBHelper(string strConnectionString, int intCommandTimeout)
        {
            m_strConnectionString = strConnectionString;
            m_intCommandTimeout = intCommandTimeout;
        }
        public DBHelper(string strConnectionString, Logger oLogger)
        {
            m_strConnectionString = strConnectionString;
            m_Logger = oLogger;
        }
        public DBHelper(string strConnectionString, Logger oLogger, int intCommandTimeout)
        {
            m_strConnectionString = strConnectionString;
            m_Logger = oLogger;
            m_intCommandTimeout = intCommandTimeout;
        }

        #endregion

        #region Proprietà

        public int CommandTimeout
        {
            get
            {
                return m_intCommandTimeout;
            }
            set
            {
                m_intCommandTimeout = value;
            }
        }

        #endregion

        #region OpenConnection

        public SqlConnection OpenConnection()
        {
            return OpenConnection(m_strConnectionString);
        }

        public static SqlConnection OpenConnection(string strConString)
        {
            SqlConnection conGen = null;
            try
            {
                conGen = new SqlConnection(strConString);
                conGen.Open();
            }
            catch (System.Exception ex)
            {
                if (m_Logger != null)
                    m_Logger.Write(Logger.LogTypeMessage.Error, ex.Message, ex);
                throw ex;
            }
            return conGen;
        }
        #endregion

        #region ReleaseConnection

        public static void ReleaseConnection(SqlConnection conGen)
        {
            if (conGen != null)
            {
                conGen.Close();
                conGen.Dispose();
            }
            conGen = null;
        }

        #endregion

        #region GetDatasetFormSQL

        public DataSet GetDatasetFormSQL(string strSQL, string strTableName)
        {
            DataSet ds = new DataSet();
            SqlConnection con = OpenConnection();
            ds = GetDatasetFormSQL(con, strSQL, strTableName, ref ds, null);
            ReleaseConnection(con);
            return ds;
        }

        public DataSet GetDatasetFormSQL(string strSQL, string strTableName, ref DataSet ds)
        {
            SqlConnection con = OpenConnection();
            ds = GetDatasetFormSQL(con, strSQL, strTableName, ref ds, null);
            ReleaseConnection(con);
            return ds;
        }

        public static DataSet GetDatasetFormSQL(SqlConnection conGen, string strSQL, string strTableName)
        {
            DataSet ds = new DataSet();
            try
            {
                ds = GetDatasetFormSQL(conGen, strSQL, strTableName, ref ds, null);
            }
            catch (System.Exception ex)
            {
                if (m_Logger != null)
                    m_Logger.Write(Logger.LogTypeMessage.Error, ex.Message, ex);
                throw ex;
            }
            return ds;
        }

        public static DataSet GetDatasetFormSQL(SqlConnection conGen, string strSQL, string strTableName, SqlParameter[] pars)
        {
            DataSet ds = new DataSet();
            try
            {
                ds = GetDatasetFormSQL(conGen, strSQL, strTableName, ref ds, pars);
            }
            catch (System.Exception ex)
            {
                if (m_Logger != null)
                    m_Logger.Write(Logger.LogTypeMessage.Error, ex.Message, ex);
                throw ex;
            }
            return ds;
        }

        public static DataSet GetDatasetFormSQL(SqlConnection conGen, string strSQL, string strTableName, ref DataSet ds, SqlParameter[] pars)
        {
            try
            {
                ds = GetDatasetFormSQL(conGen, strSQL, strTableName, ref ds, null, pars);
            }
            catch (Exception ex)
            {
                if (m_Logger != null)
                    m_Logger.Write(Logger.LogTypeMessage.Error, ex.Message, ex);
                throw ex;
            }
            return ds;
        }

        public static DataSet GetDatasetFormSQL(SqlConnection conGen, string strSQL, string strTableName, ref DataSet ds, SqlTransaction tran, SqlParameter[] pars)
        {
            try
            {
                ds = GetDatasetFormSQL(conGen, strSQL, strTableName, ref ds, null, pars, 0);
            }
            catch (Exception ex)
            {
                if (m_Logger != null)
                    m_Logger.Write(Logger.LogTypeMessage.Error, ex.Message, ex);
                throw ex;
            }
            return ds;
        }

        public static DataSet GetDatasetFormSQL(SqlConnection conGen, string strSQL, string strTableName, ref DataSet ds, SqlTransaction tran, SqlParameter[] pars, int intCommandTimeout)
        {
            try
            {
                SqlCommand cmdSelect = new SqlCommand();
                if (tran != null) cmdSelect.Transaction = tran;
                cmdSelect.Connection = conGen;
                cmdSelect.CommandText = strSQL;
                cmdSelect.CommandType = CommandType.Text;
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
            return ds;
        }

        #endregion

        #region GetDataTableFormSQL

        public DataTable GetDataTableFormSQL(string strSQL)
        {
            return GetDataTableFormSQL(strSQL, null);
        }

        public DataTable GetDataTableFormSQL(string strSQL, SqlParameter[] pars)
        {
            SqlConnection con = OpenConnection();
            DataTable dtRes = GetDataTableFormSQL(con, strSQL, "tblGen", null, pars, m_intCommandTimeout);
            ReleaseConnection(con);
            return dtRes;
        }

        public DataTable GetDataTableFormSQL(string strSQL, string strTableName, SqlParameter[] pars)
        {
            SqlConnection con = OpenConnection();
            DataTable dtRes = GetDataTableFormSQL(con, strSQL, strTableName, null, pars, m_intCommandTimeout);
            ReleaseConnection(con);
            return dtRes;
        }

        public static DataTable GetDataTableFormSQL(SqlConnection conGen, string strSQL, string strTableName, SqlParameter[] pars)
        {
            return GetDataTableFormSQL(conGen, strSQL, strTableName, null, pars);
        }

        public DataTable GetDataTableFormSQL(string strSQL, string strTableName, SqlTransaction tran, SqlParameter[] pars)
        {
            SqlConnection con = OpenConnection();
            DataTable dtRes = GetDataTableFormSQL(con, strSQL, strTableName, tran, pars, m_intCommandTimeout);
            ReleaseConnection(con);
            return dtRes;
        }

        public static DataTable GetDataTableFormSQL(SqlConnection conGen, string strSQL, string strTableName, SqlTransaction tran, SqlParameter[] pars)
        {
            try
            {
                return GetDataTableFormSQL(conGen, strSQL, strTableName, tran, pars, 0);
            }
            catch (Exception ex)
            {
                if (m_Logger != null)
                    m_Logger.Write(Logger.LogTypeMessage.Error, ex.Message, ex);
                throw ex;
            }
        }

        public static DataTable GetDataTableFormSQL(SqlConnection conGen, string strSQL, string strTableName, SqlTransaction tran, SqlParameter[] pars, int intCommandTimeout)
        {
            DataSet ds = new DataSet();
            try
            {
                SqlCommand cmdSelect = new SqlCommand();
                if (tran != null) cmdSelect.Transaction = tran;
                cmdSelect.Connection = conGen;
                cmdSelect.CommandText = strSQL;
                cmdSelect.CommandType = CommandType.Text;
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

        #endregion

        #region GetDataTableFormStoredProcedure

        public DataTable GetDataTableFormStoredProcedure(string strSPName)
        {
            return GetDataTableFormStoredProcedure(strSPName, null);
        }

        public DataTable GetDataTableFormStoredProcedure(string strSPName, SqlParameter[] pars)
        {
            SqlConnection con = OpenConnection();
            DataTable dtRes = GetDataTableFormStoredProcedure(con, strSPName, "tblGen", null, pars, m_intCommandTimeout);
            ReleaseConnection(con);
            return dtRes;
        }

        public DataTable GetDataTableFormStoredProcedure(string strSPName, string strTableName, SqlParameter[] pars)
        {
            SqlConnection con = OpenConnection();
            DataTable dtResult = GetDataTableFormStoredProcedure(con, strSPName, strTableName, null, pars, m_intCommandTimeout);
            ReleaseConnection(con);
            return dtResult;
        }

        public DataTable GetDataTableFormStoredProcedure(string strSPName, string strTableName, SqlTransaction tran, SqlParameter[] pars)
        {
            SqlConnection con = OpenConnection();
            DataTable dtRes = GetDataTableFormStoredProcedure(con, strSPName, strTableName, tran, pars, m_intCommandTimeout);
            ReleaseConnection(con);
            return dtRes;
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
                cmdSelect.CommandTimeout = m_intCommandTimeout;
                SqlDataAdapter da = new SqlDataAdapter();

                if (!(pars == null))
                {
                    for (int intPar = 0; intPar <= pars.Length - 1; intPar++)
                    {
                        cmdSelect.Parameters.Add(pars[intPar]);
                    }
                }
                //DataTable DataTable = new DataTable("RemarketingData");
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

        #endregion

        #region ExecuteStoredProcedure


        public void ExecuteStoredProcedure(string strSPName, SqlParameter[] pars)
        {
            SqlConnection con = OpenConnection();
            ExecuteStoredProcedure(con, strSPName, null, pars, m_intCommandTimeout);
            ReleaseConnection(con);
        }

        public void ExecuteStoredProcedure(string strSPName, ref SqlParameter[] pars)
        {
            SqlConnection con = OpenConnection();
            ExecuteStoredProcedure(con, strSPName, null, ref pars, m_intCommandTimeout);
            ReleaseConnection(con);
        }

        public void ExecuteStoredProcedure(string strSPName, SqlTransaction tran)
        {
            SqlConnection con = OpenConnection();
            ExecuteStoredProcedure(con, strSPName, tran, null, m_intCommandTimeout);
            ReleaseConnection(con);
        }

        public void ExecuteStoredProcedure(string strSPName, SqlTransaction tran, SqlParameter[] pars)
        {
            SqlConnection con = OpenConnection();
            ExecuteStoredProcedure(con, strSPName, tran, pars, m_intCommandTimeout);
            ReleaseConnection(con);
        }

        public void ExecuteStoredProcedure(string strSPName, SqlTransaction tran, ref SqlParameter[] pars)
        {
            SqlConnection con = OpenConnection();
            ExecuteStoredProcedure(con, strSPName, tran, ref pars, m_intCommandTimeout);
            ReleaseConnection(con);
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

        #endregion

        #region ExecuteSQL

        public void ExecuteSQL(string strSQL)
        {
            ExecuteSQL(strSQL, null);
        }

        public void ExecuteSQL(string strSQL, SqlParameter[] pars)
        {
            SqlConnection con = OpenConnection();
            ExecuteSQL(con, strSQL, null, pars, m_intCommandTimeout);
            ReleaseConnection(con);
        }

        public void ExecuteSQL(string strSQL, SqlTransaction tran, SqlParameter[] pars)
        {
            SqlConnection con = OpenConnection();
            ExecuteSQL(con, strSQL, tran, pars, m_intCommandTimeout);
            ReleaseConnection(con);
        }

        public static void ExecuteSQL(SqlConnection conGen, string strSQL, SqlTransaction tran, SqlParameter[] pars)
        {
            try
            {
                ExecuteSQL(conGen, strSQL, tran, pars, 0);
            }
            catch (Exception ex)
            {
                if (m_Logger != null)
                    m_Logger.Write(Logger.LogTypeMessage.Error, ex.Message, ex);
                throw ex;
            }
        }

        public static void ExecuteSQL(SqlConnection conGen, string strSQL, SqlTransaction tran, SqlParameter[] pars, int intCommandTimeout)
        {
            DataSet ds = new DataSet();
            try
            {
                SqlCommand cmdExec = new SqlCommand();
                if (tran != null) cmdExec.Transaction = tran;
                cmdExec.Connection = conGen;
                cmdExec.CommandText = strSQL;
                cmdExec.CommandType = CommandType.Text;
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

        #endregion

        #region Static methods

        //Metodo statico che salva il contenuto di una datatable in un file csv
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

                //Scrittura vera a propria del file fisico
                //File.WriteAllText(sCsvFileName, sb.ToString());
            }
            return sb.ToString();
        }
        private static string FormatCSVField(string sFieldValue)
        {
            return string.Concat("\"", sFieldValue.Replace("\"", "\"\""), "\"");
        }

        #endregion

    }
}
