using System;
using System.Collections.Generic;
using System.Configuration;
using System.Linq;
using System.Text;

namespace BPLG.Utility
{
    /// <summary>
    /// Questa classe si occupa di interrogare il Web Service Configuration_Manager
    /// per recuperare i link al quale le varie funzioni del pannello utente presente
    /// nella BPLGComponent deve effettuare il redirect
    /// </summary>
    public class GetNavigationUrl
    {
        public static string GetNavigationString(string PlaceHolder)
        {
            ConnectionManager.Configuration_Manager connection = new ConnectionManager.Configuration_Manager();
            connection.Url = ConfigurationManager.AppSettings["ServiceUrl"];
            connection.UseDefaultCredentials = true;

            return connection.GetNavigationString(PlaceHolder);
        }
    }
}
