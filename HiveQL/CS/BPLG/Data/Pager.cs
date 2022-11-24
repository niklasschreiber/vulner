using System;
using System.Data;
using System.Data.SqlClient;
using System.Collections.Generic;
using System.Text;
using BPLG.Logging;

namespace BPLG.Data
{
    /// <summary>
    /// Classe che serve per la paginazione dei dati presi da SQL
    /// </summary>
    public class Pager
    {
        //Oggetto DBHelper per fare le interrogazioni al DB
        private DBHelper m_db;
        string m_sTableName = "";
        string m_sIDColumName = "";
        string m_sSortField = "";
        OrderType m_sSortType = OrderType.eASC;
        FieldType m_ft = FieldType.eString;
        Int32 m_nPageSize = 10;
        Int64 m_nTotPages = 0;

        public enum FieldType
        {
            eNumeric,
            eString
        }

        public enum OrderType
        {
            eASC,
            eDESC
        }

        public Pager(DBHelper db, string sTableName, string sIDColumName, Int32 nPageSize, string sSortField, FieldType ft, OrderType sSortType)
        {
            m_db = db;
            m_sTableName = sTableName;
            m_sIDColumName = sIDColumName;
            m_nPageSize = nPageSize;
            m_sSortField = sSortField;
            m_sSortType = sSortType;
            m_ft = ft;
            m_nTotPages = Convert.ToInt64(m_db.GetDataTableFormSQL("SELECT 	CASE  WHEN COUNT(*) = 0 THEN 0 ELSE 1+ (COUNT(*) / " + m_nPageSize.ToString() + ") END nPages FROM " + m_sTableName).Rows[0][0]);
        }

        public Int64 PageNumbers
        {
            get
            {
                return m_nTotPages;
            }
        }

        public DataTable GetPage(Int64 nPageNumber)
        {
            string strSQLMAX = "";
            object id1 = null;
            object id2 = null;

            if (nPageNumber != 1)
            {
                Int64 intRecs = m_nPageSize * (nPageNumber - 1);

                if (m_sSortField.Trim() == "")
                    strSQLMAX += " SELECT TOP 1 ISNULL(" + m_sIDColumName + ", 0) AS " + m_sIDColumName + " ";
                else
                    strSQLMAX += " SELECT TOP 1 ISNULL(" + m_sIDColumName + ", 0) AS " + m_sIDColumName + " , ISNULL(" + m_sSortField + ", " + (m_ft == FieldType.eString ? "''" : "0") + ") AS " + m_sSortField + " ";
                strSQLMAX += " FROM( ";

                if (m_sSortField.Trim() == "")
                    strSQLMAX += " SELECT TOP " + intRecs.ToString() + " " + m_sIDColumName + " ";
                else
                    strSQLMAX += " SELECT TOP " + intRecs.ToString() + " " + m_sIDColumName + " , " + m_sSortField + " ";

                strSQLMAX += " FROM " + m_sTableName + " ";

                if (m_sSortField.Trim() == "")
                    strSQLMAX += "  ORDER BY " + m_sIDColumName + " ";
                else
                    strSQLMAX += "  ORDER BY " + m_sSortField + " " + (m_sSortType == OrderType.eASC ? "ASC" : "DESC") + " , " + m_sIDColumName + " ";

                strSQLMAX += " ) AS XYZXYZ ";

                if (m_sSortField.Trim() == "")
                    strSQLMAX += "  ORDER BY " + m_sIDColumName + " DESC ";
                else
                    strSQLMAX += "  ORDER BY " + m_sSortField + " " + (m_sSortType == OrderType.eASC ? "DESC" : "ASC") + " , " + m_sIDColumName + " DESC ";

                DataTable dt = m_db.GetDataTableFormSQL(strSQLMAX); //.Rows[0];
                if (dt.Rows.Count == 0)
                {
                    id1 = 0;
                    switch (m_ft)
                    {
                        case FieldType.eString:
                            id2 = "";
                            break;
                        case FieldType.eNumeric:
                            id2 = 0;
                            break;
                    }
                }
                else
                {
                    DataRow drReference = m_db.GetDataTableFormSQL(strSQLMAX).Rows[0];
                    id1 = drReference[0];
                    if (m_sSortField.Trim() != "")
                        id2 = drReference[1];
                }
            }

            string strSQLSelect = "";
            strSQLSelect += " SELECT TOP " + m_nPageSize.ToString() + " * ";
            strSQLSelect += " FROM " + m_sTableName + " ";
            if (m_sSortField.Trim() == "")
            {
                if (nPageNumber == 1)
                {
                    strSQLSelect += " ORDER BY " + m_sIDColumName + " ";
                    return m_db.GetDataTableFormSQL(strSQLSelect);
                }
                else
                {
                    strSQLSelect += " WHERE " + m_sIDColumName + " > @id1 ";
                    strSQLSelect += " ORDER BY " + m_sIDColumName + " ";
                    return m_db.GetDataTableFormSQL(strSQLSelect, new SqlParameter[] { new SqlParameter("@id1", id1) });
                }
            }
            else
            {
                if (nPageNumber == 1)
                {
                    strSQLSelect += " ORDER BY " + m_sSortField + " " + (m_sSortType == OrderType.eASC ? "ASC" : "DESC") + " , " + m_sIDColumName + " ";
                    return m_db.GetDataTableFormSQL(strSQLSelect);
                }
                else
                {
                    strSQLSelect += " WHERE " + m_sSortField + " " + (m_sSortType == OrderType.eASC ? ">" : "<") + " ISNULL(@id2, " + (m_ft == FieldType.eString ? "''" : "0") + ") OR (" + m_sSortField + " = @id2 AND " + m_sIDColumName + " > @id1 ) ";
                    strSQLSelect += " ORDER BY " + m_sSortField + " " + (m_sSortType == OrderType.eASC ? "ASC" : "DESC") + " , " + m_sIDColumName + " ";
                    return m_db.GetDataTableFormSQL(strSQLSelect, new SqlParameter[] { new SqlParameter("@id1", id1), new SqlParameter("@id2", id2) });
                }
            }

        }

    }
}
