using System;
using System.Collections.Generic;
using System.Text;

namespace BPLG.Validation
{
    /// <summary>
    /// Classe che permette di validare una stringa (generalmente una riga di un file di importazione)
    /// se risolve una regola di validazione data da una RegularExpression
    /// </summary>
    public class RowFormat
    {
        //Indica la regular expression che valida la riga
        System.Text.RegularExpressions.Regex regexp;

        /// <summary>
        /// Costruttore di RowValidator
        /// </summary>
        /// <param name="strRegularExpression">regular expression di validazione della riga</param>
        public RowFormat(string strRegularExpression)
        {
            regexp = new System.Text.RegularExpressions.Regex(strRegularExpression);
        }

        /// <summary>
        /// Restituisce true o false a seconda se la riga viene validata dalla regular expression specificata nel costruttore
        /// </summary>
        /// <param name="strRow">stringa da validare</param>
        /// <returns></returns>
        public bool Validate(string strRow)
        {
            return regexp.IsMatch(strRow);
        }
    }
}
