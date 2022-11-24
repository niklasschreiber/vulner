using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Configuration;
using System.Web;
using BPLG.Utility;

namespace BPLG.Authentication
{
    public static class AuthenticationManagerFactory
    {
        public static IAuthenticationManager GetSecurityManager()
        {
            RescueConfigurationInformation rescueConfig = new RescueConfigurationInformation();
            BPLG.Database.DBHelper m_ProfiliRisorse = BPLG.Database.DBHelperCollection.Instance(rescueConfig.GetApplication, rescueConfig.GetConfiguration("ProfiliRisorse"));

            switch (ConfigurationManager.AppSettings["SecurityType"])
            {
                case "DBAZMDOMAIN":
                    return new AuthenticationManager_Integrated(
                                "DBAZMDOMAIN"
                                , m_ProfiliRisorse.ConnectionString
                                , ConfigurationManager.AppSettings["PolicyAppName"]
                                , HttpContext.Current.User.Identity.Name.Split('\\')[HttpContext.Current.User.Identity.Name.Split('\\').Length - 1]);
                case "DBAZMLOGIN":
                    return new AuthenticationManger_Database(
                                "DBAZMDOMAIN"
                                , m_ProfiliRisorse.ConnectionString
                                , ConfigurationManager.AppSettings["PolicyAppName"]);
                case "DBAZMCACHE":
                    return new AuthenticationManager_Cookie(
                        "DBAZMCACHE"
                        , m_ProfiliRisorse.ConnectionString
                        , ConfigurationManager.AppSettings["PolicyAppName"]);
                case "DBAZMMIXED":
                    return new AuthenticationManager_Mixed(
                            "DBAZMDOMAIN"
                            , m_ProfiliRisorse.ConnectionString
                            , ConfigurationManager.AppSettings["PolicyAppName"]
                            , HttpContext.Current.User.Identity.Name.Split('\\')[HttpContext.Current.User.Identity.Name.Split('\\').Length - 1]);

                case "SAML2EXTIDP":
                    return new AuthenticationManager_IdentityUserPrincipal();
            }
            throw new Exception("Il tipo di autorizzazione indicato sul file di configurazione non è tra i tipi di autenticazione conosciuti. Verificare il parametro SecurityType sul file di configurazione.");
        }
    }
}
