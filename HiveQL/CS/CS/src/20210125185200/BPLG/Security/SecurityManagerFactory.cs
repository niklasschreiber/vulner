using System;
using System.Collections.Generic;
using System.Text;
using System.Configuration;
using System.Web;

namespace BPLG.Security
{
    /// <summary>
    /// Classe per istanziare un oggetto che implementa
    /// l'interfaccia ISecurityManager leggendo il file di 
    /// configurazione dell'applicazione web
    /// </summary>
    public static class SecurityManagerFactory
    {
        /// <summary>
        /// Permette di creare la classe per la gestione delle autorizzazioni
        /// </summary>
        /// <returns></returns>
        public static ISecurityManager GetSecurityManager()
        {
            string strSecDBSchemaName = "";
            //Indica il tipo di autorizzazione richiesto
            switch (ConfigurationManager.AppSettings["SecurityType"])
            {
                case "DBAZMDOMAIN":
                    //Gestione delle autorizzazioni basate su Database authorization manager all'interno del Dominio
                    string strDBAZMDOMAINSQLConnection = ConfigurationManager.AppSettings["SecDBConn"];
                    string strDBAZMDOMAINAppAuthName = ConfigurationManager.AppSettings["PolicyAppName"];
                    if (ConfigurationManager.AppSettings["SecDBSchemaName"] != null)
                        strSecDBSchemaName = ConfigurationManager.AppSettings["SecDBSchemaName"];
                    return new DBAuthorizationManager("DBAZMDOMAIN", strDBAZMDOMAINSQLConnection, strDBAZMDOMAINAppAuthName, HttpContext.Current.User.Identity.Name.Split('\\')[HttpContext.Current.User.Identity.Name.Split('\\').Length - 1], strSecDBSchemaName);
                case "DBAZMLOGIN":
                    //Gestione delle autorizzazioni basate su Database authorization manager all'interno del Dominio
                    string strDBAZMLOGINSQLConnection = ConfigurationManager.AppSettings["SecDBConn"];
                    string strDBAZMLOGINAppAuthName = ConfigurationManager.AppSettings["PolicyAppName"];
                    DBAuthorizationManager dbauth = new DBAuthorizationManager("DBAZMLOGIN", strDBAZMLOGINSQLConnection, strDBAZMLOGINAppAuthName);
                    if (ConfigurationManager.AppSettings["SecDBSchemaName"] != null)
                        dbauth.SchemaName = ConfigurationManager.AppSettings["SecDBSchemaName"];
                    return dbauth;
                case "DBAZMCACHE":
                    //Gestione delle autorizzazioni basate su Database authorization manager all'interno del Dominio
                    string strDBAZMCACHESQLConnection = ConfigurationManager.AppSettings["SecDBConn"];
                    string strDBAZMCACHEAppAuthName = ConfigurationManager.AppSettings["PolicyAppName"];
                    CKAuthorizationManager dbcache = new CKAuthorizationManager("DBAZMCACHE", strDBAZMCACHESQLConnection, strDBAZMCACHEAppAuthName);
                    if (ConfigurationManager.AppSettings["SecDBSchemaName"] != null)
                        dbcache.SchemaName = ConfigurationManager.AppSettings["SecDBSchemaName"];
                    return dbcache;
                case "DBAZMSERVICE":
                    //Gestione delle autorizzazioni basate su Database authorization manager all'interno del Dominio
                    string strDBAZMSERVICESQLConnection = ConfigurationManager.AppSettings["SecDBConn"];
                    string strDBAZMSERVICEAppAuthName = ConfigurationManager.AppSettings["PolicyAppName"];
                    string strDBAZMSERVICESecurityUser = ConfigurationManager.AppSettings["SecurityUser"];
                    if (ConfigurationManager.AppSettings["SecDBSchemaName"] != null)
                        strSecDBSchemaName = ConfigurationManager.AppSettings["SecDBSchemaName"];
                    return new DBAuthorizationManager("DBAZMSERVICE", strDBAZMSERVICESQLConnection, strDBAZMSERVICEAppAuthName, strDBAZMSERVICESecurityUser, strSecDBSchemaName);

                case "SAML2EXTIDP":
                    // Gestione identita a carico di un external idp, mentre le autorizzazioni 
                    // applicative gestite internamente tramite db
                    string str_SAML2EXTIDP_SQLConnection = ConfigurationManager.AppSettings["SecDBConn"];
                    string str_SAML2EXTIDP_AppAuthName = ConfigurationManager.AppSettings["PolicyAppName"];
                    if (ConfigurationManager.AppSettings["SecDBSchemaName"] != null)
                        strSecDBSchemaName = ConfigurationManager.AppSettings["SecDBSchemaName"];
                    return new DBAuthorizationManagerWithExternalIdp(str_SAML2EXTIDP_SQLConnection, str_SAML2EXTIDP_AppAuthName, strSecDBSchemaName);


            }
            throw new Exception("Il tipo di autorizzazione indicato sul file di configurazione non è tra i tipi di autenticazione conosciuti. Verificare il parametro SecurityType sul file di configurazione.");
        }

        /// <summary>
        /// Permette di creare la classe per la gestione delle autorizzazioni
        /// </summary>
        /// <returns></returns>
        public static ISecurityManager GetSecurityManager(string userLogin)
        {
            string strSecDBSchemaName = "";
            //Indica il tipo di autorizzazione richiesto
            switch (ConfigurationManager.AppSettings["SecurityType"])
            {
                //case "DB":
                //    //Gestione delle autorizzazioni basate su database
                //    string strSQLConnection = ConfigurationManager.AppSettings["SecDBConn"];
                //    return new DBSecurityManager(strSQLConnection);
                //case "AZM":
                //    //Gestione delle autorizzazioni basate su authorization manager
                //    string strXMLPolicyStore = ConfigurationManager.AppSettings["XMLPolicyStore"];
                //    string strAppName = ConfigurationManager.AppSettings["PolicyAppName"];
                //    return new AuthorizationManager(strXMLPolicyStore, strAppName, HttpContext.Current.User);
                case "DBAZMDOMAIN":
                    //Gestione delle autorizzazioni basate su Database authorization manager all'interno del Dominio
                    string strDBAZMDOMAINSQLConnection = ConfigurationManager.AppSettings["SecDBConn"];
                    string strDBAZMDOMAINAppAuthName = ConfigurationManager.AppSettings["PolicyAppName"];
                    if (ConfigurationManager.AppSettings["SecDBSchemaName"] != null)
                        strSecDBSchemaName = ConfigurationManager.AppSettings["SecDBSchemaName"];
                    return new DBAuthorizationManager("DBAZMDOMAIN", strDBAZMDOMAINSQLConnection, strDBAZMDOMAINAppAuthName, userLogin, strSecDBSchemaName);
                case "DBAZMLOGIN":
                    //Gestione delle autorizzazioni basate su Database authorization manager all'interno del Dominio
                    string strDBAZMLOGINSQLConnection = ConfigurationManager.AppSettings["SecDBConn"];
                    string strDBAZMLOGINAppAuthName = ConfigurationManager.AppSettings["PolicyAppName"];
                    DBAuthorizationManager dbauth = new DBAuthorizationManager("DBAZMLOGIN", strDBAZMLOGINSQLConnection, strDBAZMLOGINAppAuthName);
                    if (ConfigurationManager.AppSettings["SecDBSchemaName"] != null)
                        dbauth.SchemaName = ConfigurationManager.AppSettings["SecDBSchemaName"];
                    return dbauth;
            }
            throw new Exception("Il tipo di autorizzazione indicato sul file di configurazione non è tra i tipi di autenticazione conosciuti. Verificare il parametro SecurityType sul file di configurazione.");
        }

        
        public static BPLG.Security.ISecurityManager GetSecurityManager(ConfigSectionHandler config)
        {
            //Indica il tipo di autorizzazione richiesto
            switch (config.SecuritySettings.SecurityType)
            {
                case "DBAZMDOMAIN":
                    return new DBAuthorizationManager(config.SecuritySettings.SecurityType, config.SecuritySettings.SecDBConn, config.SecuritySettings.PolicyAppName, HttpContext.Current.User.Identity.Name.Split('\\')[HttpContext.Current.User.Identity.Name.Split('\\').Length - 1], config.SecuritySettings.SecDBSchemaName);
                case "DBAZMLOGIN":
                    DBAuthorizationManager dbauth = new DBAuthorizationManager(config.SecuritySettings.SecurityType, config.SecuritySettings.SecDBConn, config.SecuritySettings.PolicyAppName);
                    dbauth.SchemaName = config.SecuritySettings.SecDBSchemaName;
                    return dbauth;
            }
            throw new Exception("Il tipo di autorizzazione indicato sul file di configurazione non è tra i tipi di autenticazione conosciuti. Verificare il parametro SecurityType sul file di configurazione.");
        }

    }
}
