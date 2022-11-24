using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Text;

namespace BPLG.Database
{
    public class DBUtility
    {
        /// <summary>
        /// Costruisce un gestore errore interno per il BulkCopy. Attenzione! la funzionalità risulta
        /// non performante in quanto deve scorrere tutte le righe. Utilizzare solo in funzione di una
        /// specifica eccezione. NON METTERE ASSOLUTAMENTE SU general Exception
        /// </summary>
        /// <param name="tableName">Nome della tabella sulla quale eseguire il try di inserimento</param>
        /// <param name="dataReader">DataReader sul quale effettuare il Bulk</param>
        /// <param name="connection">SqlConnection da utilizzare per le esecuzioni</param>
        /// <param name="TransactionName">Nome della transazione da utilizzare. In caso si lasci vuoto viene creato dal sistema</param>
        /// <returns>Messaggi di errore in caso di fallimento.</returns>
        public static string GetBulkCopyFailedData(
                                            string tableName,
                                            IDataReader dataReader,
                                            ref SqlConnection connection,
                                            string TransactionName = null)
        {
            StringBuilder errorMessage = new StringBuilder("Bulk copy failures:" + Environment.NewLine);
            SqlTransaction transaction = null;
            SqlBulkCopy bulkCopy = null;
            DataTable tmpDataTable = new DataTable();
            int indexRow = 0;

            try
            {
                transaction = (TransactionName != null ? connection.BeginTransaction(TransactionName) : connection.BeginTransaction());

                bulkCopy = new SqlBulkCopy(connection, SqlBulkCopyOptions.CheckConstraints, transaction);
                bulkCopy.DestinationTableName = tableName;

                DataTable dataSchema = dataReader.GetSchemaTable();
                foreach (DataRow row in dataSchema.Rows)
                {
                    tmpDataTable.Columns.Add(new DataColumn(row["ColumnName"].ToString(), (Type)row["DataType"]));
                }
                
                object[] values = new object[dataReader.FieldCount];

                while (dataReader.Read())
                {
                    ++indexRow;
                    tmpDataTable.Rows.Clear();
                    dataReader.GetValues(values);
                    tmpDataTable.LoadDataRow(values, true);
                    try
                    {
                        bulkCopy.WriteToServer(tmpDataTable);
                    }
                    catch (Exception ex)
                    {
                        DataRow faultyDataRow = tmpDataTable.Rows[0];
                        errorMessage.AppendFormat("Error: {0}{1}", ex.Message, Environment.NewLine);
                        errorMessage.AppendFormat("Row data: [{0}]{1}", indexRow, Environment.NewLine);
                        foreach (DataColumn column in tmpDataTable.Columns)
                        {
                            errorMessage.AppendFormat(
                               "\tColumn {0} - [{1}]{2}",
                               column.ColumnName,
                               faultyDataRow[column.ColumnName].ToString(),
                               Environment.NewLine);
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                throw new Exception(
                   "Unable to document SqlBulkCopy errors. See inner exceptions for details.",
                   ex);
            }
            finally
            {
                if (transaction != null)
                {
                    transaction.Rollback();
                }
                if (connection.State != ConnectionState.Closed)
                {
                    connection.Close();
                }
            }
            return errorMessage.ToString();
        }
    }
}
