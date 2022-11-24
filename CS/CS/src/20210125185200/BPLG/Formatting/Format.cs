using System;
using System.Collections.Generic;
using System.Text;

namespace BPLG.Formatting
{
    /// <summary>
    /// Classe per la formattazione generica di testo e numeri 
    /// </summary>
    public class Format
    {
        public static string DateForRepeater(object obj)
        {
            return Convert.IsDBNull(obj) ? "" : Convert.ToDateTime(obj).ToString("dd/MM/yyyy");
        }
        public static string CurrencyForRepeater(object obj)
        {
            return Convert.IsDBNull(obj) ? Convert.ToDecimal(0).ToString("0.00") : Convert.ToDecimal(obj).ToString("#,##0.00");
            return "";
        }
        public static string CurrencyForRepeaterNoDecimals(object obj)
        {
            return Convert.IsDBNull(obj) ? Convert.ToDecimal(0).ToString("0") : Convert.ToDecimal(obj).ToString("#,##0");
            return "";
        }

        /// <summary>
        /// Dato un oggetto restituisce la stringa
        /// </summary>
        /// <param name="obj"></param>
        /// <returns></returns>
        public static string VarForceString(object obj)
        {
            if (obj == null) return "";
            if (Convert.IsDBNull(obj)) return "";
            return Convert.ToString(obj);
        }

        /// <summary>
        /// Dato un oggetto ne restituisce un decimal
        /// </summary>
        /// <param name="nValue"></param>
        /// <returns></returns>
        public static decimal VarForceZero(object nValue)
        {
            if (nValue == null) return (decimal)0;
            if (Convert.IsDBNull(nValue)) return (decimal)0;
            return Convert.ToDecimal(nValue);
        }

        public enum PadDirection
        {
            ePadLeft,
            ePadRight
        }
        public static string FormatField(object objVal, int intWidth, PadDirection pad, char strPadchar)
        {
            string strField = Convert.ToString(objVal);
            switch (pad)
            {
                case PadDirection.ePadLeft:
                    strField = strField.PadLeft(intWidth, strPadchar);
                    break;
                case PadDirection.ePadRight:
                    strField = strField.PadRight(intWidth, strPadchar);
                    break;
            }
            return strField;
        }

        /// <summary>
        /// Restituisce la descrizione della settimana
        /// </summary>
        /// <param name="nYearWeek">Settimana di riferimento nel formato YYYYWW dove YYYY indica l'anno e WW indica il numero della settimana dell'anno </param>
        /// <returns></returns>
        public static string GetWeekDescription(int nYearWeek)
        {
            //System.Globalization.GregorianCalendar cal = new System.Globalization.GregorianCalendar();
            string strWW = nYearWeek.ToString();
            Int32 intDayAdd = 0;
            int intAnno = int.Parse(strWW.Substring(0, 4));
            int intSettimana = int.Parse(strWW.Substring(4, 2));
            switch (DateTime.ParseExact("01/01/" + intAnno.ToString(), "dd/MM/yyyy", null).DayOfWeek)
            {
                case DayOfWeek.Monday:
                    intDayAdd = 0;
                    break;
                case DayOfWeek.Tuesday:
                    intDayAdd = -1;
                    break;
                case DayOfWeek.Wednesday:
                    intDayAdd = -2;
                    break;
                case DayOfWeek.Thursday:
                    intDayAdd = -3;
                    break;
                case DayOfWeek.Friday:
                    intDayAdd = -4;
                    break;
                case DayOfWeek.Saturday:
                    intDayAdd = -5;
                    break;
                case DayOfWeek.Sunday:
                    intDayAdd = -6;
                    break;
            }
            int intDayStart = ((intSettimana - 1) * 7) + intDayAdd;
            DateTime dtStart = DateTime.ParseExact("01/01/" + intAnno.ToString(), "dd/MM/yyyy", null).AddDays(intDayStart);

            return "Settimana dal " + dtStart.ToString("dd/MM/yyyy") + " al " + dtStart.AddDays(6).ToString("dd/MM/yyyy");
        }

        /// <summary>
        /// 
        /// </summary>
        /// <param name="Week"></param>
        /// <param name="Year"></param>
        /// <returns></returns>
        public static string GetWeekRange(int Week, int Year) 
        {
            const string WeekDescription = "Settimana dal {0} al {1}";
            DateTime dt = new DateTime(Year, 1, 1).AddDays((Week - 1) * 7 - (Week == 1 ? 0 : 1));
            string StartDate = dt.AddDays(-(dt.DayOfWeek - DayOfWeek.Monday)).Year < Year ? "01/01/" + DateTime.Now.Year : dt.AddDays(-(dt.DayOfWeek - DayOfWeek.Monday)).ToString("dd/MM/yyyy");
            string EndDate = dt.AddDays(-(dt.DayOfWeek - DayOfWeek.Monday)).AddDays(6).Year > Year ? "31/12/" + DateTime.Now.Year : dt.AddDays(-(dt.DayOfWeek - DayOfWeek.Monday)).AddDays(6).ToString("dd/MM/yyyy");
            return string.Format(WeekDescription, StartDate, EndDate);
        }
    }
}
