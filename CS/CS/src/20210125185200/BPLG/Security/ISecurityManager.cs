using System;
using System.Data;
using System.Collections.Generic;
using System.Text;

namespace BPLG.Security
{
    /// <summary>
    /// Interfaccia di standardizzazione dei metodi di autenticazione
    /// </summary>
    public interface ISecurityManager
    {

        /// <summary>
        /// Restituisce l'istanza dell'authorization manager da salvare
        /// nell'oggetto application
        /// </summary>
        /// <returns></returns>
        ISecurityManager GetInstance();

        /// <summary>
        /// Verifica la validità della Password in base ad una serie di regole di Complexity definite
        /// </summary>
        /// <param name="password">Password da controllare</param>
        /// <param name="MinLength">Lunghezza minima della password</param>
        /// <param name="rules">Regole di Complexity da applciare (ti tipo PasswordRules)</param>
        /// <param name="ruleOutList">Elenco vecchie Password dalle quali verificarne la diversità</param>
        /// <returns></returns>
        BPLG.Security.AuthenticationPolicy.PasswordCheck IsPasswordValid(string username, string password, int? MinLength, AuthenticationPolicy.PasswordRules rules, params string[] ruleOutList);

        /// <summary>
        /// Verifica il periodo di scadenza password è trascorso
        /// </summary>
        /// <returns></returns>
        bool IsPasswordScaduta();

        /// <summary>
        /// This properties instructs the Authorization to use 
        /// the Cache instead direct access to database
        /// </summary>
        /// <param name="value">This param enable using cache in case it's true</param>
        /// <param name="ExpireDelay">
        /// The delay expire time in int (minutes).
        /// In case the value will be less than zero it will be used 5 minutes
        /// </param>
        void IsCacheEnabled(Boolean value, int ExpireDelay);

        /// <summary>
        /// This properties instructs the Authorization to use 
        /// the Cache instead direct access to database
        /// </summary>
        /// <param name="value">This param enable using cache in case it's true</param>
        /// <param name="ExpireDelay">
        /// The delay expire time in string (minutes). 
        /// In case the value will not be a correct number or less than zero it will be used 5 minutes
        /// </param>
        void IsCacheEnabled(Boolean value, string ExpireDelay);

        /// <summary>
        /// This method is in charge to clear all cached value for the user logger
        /// </summary>
        bool RemoveCache();

        /// <summary>
        /// Cambio Password
        /// </summary>
        /// <param name="Reset">Gestione Reset Password</param>
        /// <returns></returns>
        bool CambioPassword(string idUtente, string username, string newPassword, bool Reset);

        /// <summary>
        /// Permette di stabilire se si dispone dell'autorizzazione
        /// relativa ad un array di operation
        /// </summary>
        /// <param name="strOperation">Id dell'operazione da testare</param>
        /// <returns></returns>
        bool HasPermission(string[] strOperation, bool UseRealname = false);

        /// <summary>
        /// Permette di stabilire se si dispone dell'autorizzazione
        /// relativa ad una specifica operation
        /// </summary>
        /// <param name="strOperation">Id dell'operazione da testare</param>
        /// <returns></returns>
        bool HasPermission(string strOperation, bool UseRealname = false);

        /// <summary>
        /// Permette di stabilire se si dispone dell'autorizzazione
        /// relativa ad una specifica operation relativamente ad un utente
        /// </summary>
        /// <param name="strOperation">Id dell'operazione da testare</param>
        /// <returns></returns>
        bool HasPermission(string strOperation, string UserParameter, UserData UserData);

        /// <summary>
        /// Restituisce l'elenco degli utenti Attivi
        /// </summary>
        /// <returns></returns>
        DataTable UsersList(string idUtente);

        /// <summary>
        /// Restituisce una datatable contenente tutti gli
        /// utenti che costituiscono un ruolo/gruppo
        /// </summary>
        /// <param name="strRoleName"></param>
        /// <returns></returns>
        DataTable RoleUsers(string strRoleName);

        /// <summary>
        /// Indica se l'utente è già stato autenticato (loggato) al sistema
        /// </summary>
        /// <returns></returns>
        bool IsLogged();

        UserLoggedStatus LoggedStatus();

        /// <summary>
        /// Routine per l'autenticazione dell'utente
        /// </summary>
        /// <param name="strUsername"></param>
        /// <param name="strPassword"></param>
        /// <returns></returns>
        [Obsolete("Metodo obsoleto sostituito da: LoginWithResult")]
        bool Login(string strUsername, string strPassword);

        /// <summary>
        /// Nuova Routine per l'autenticazione dell'utente
        /// </summary>
        /// <param name="strUsername"></param>
        /// <param name="strPassword"></param>
        /// <returns></returns>
        int LoginWithResult(string strUsername, string strPassword);

        /// <summary>
        /// Restituisce il nome dell'utente 
        /// </summary>
        /// <returns></returns>
        string UserDisplayName();

        /// <summary>
        /// Restituisce il nome dell'utente 
        /// </summary>
        /// <returns></returns>
        string UserDisplayName(string UserParameter, UserData UserData);

        /// <summary>
        /// Restituisce lo username dell'utente
        /// </summary>
        string Username();

        /// <summary>
        /// [SOLO PER AUTENTICAZIONE INTEGRATA]
        /// Restituisce lo username dell'utente recuperato dall'Identity se la connessione è
        /// tramite Windows Authentication altrimenti lo username memorizzato in applicativo
        /// </summary>
        string RealUsername();

        /// <summary>
        /// Permette di impersonificare un utente passando il suo Username
        /// </summary>
        /// <param name="UserName">UserLogin dettl'utente da impersonificare</param>
        void ForceImpersonate(string UserName);

        /// <summary>
        /// Restituisce l'e-mail dellUtente
        /// </summary>
        string Email();

        /// <summary>
        /// Restituisce l'ID dell'utente
        /// </summary>
        string IDUtente();

        /// <summary>
        /// Restituisce l'IDStruttura del servizio d'appartenza dell'utente
        /// </summary>
        int IDServizio();

        /// <summary>
        /// Restituisce l'ID dell'applicazione
        /// </summary>
        string IDApplicazione();

        /// <summary>
        /// Aggiunge l'associazione di un utente ad uno specifico ruolo
        /// </summary>
        //bool AddRoleUser(int nIDUser, string sIDRole);

        /// <summary>
        /// Rimuove l'associazione di un utente ad uno specifico ruolo
        /// </summary>
        //string RemoveRoleUser(int nIDUser);

        /// <summary>
        /// Recupera tutti i ruoli presenti nel database per una determinata applicazione
        /// </summary>
        //DataTable GelRolesApplication(int IDUser);

        /// <summary>
        /// Restituisce un oggetto di tipo RoleUserCollection contentente 
        /// tutti i ruoli e l'associazione relativa all'utente impostato
        /// </summary>
        /// <param name="IdUser">Id User recuperato dall'utente selezionato in Web UI</param>
        /// <returns>Interfaccia di tipo IRoleUserCollection già valorizzata</returns>
        IRoleUserCollection GetRoleCollection(Nullable<int> IdUser);

        /// <summary>
        /// Questa property restituisce true se si stà utilizzando l'autenticazione integrata di Windows.
        /// <para/>In caso di autenticazione tramite Login verrà restituito false
        /// </summary>
        /// <returns>
        ///     True se si utilizza l'Autenticazione integrata<para/>
        ///     False se si utilizza l'Autenticazione tramite login
        /// </returns>
        bool IsIntegratedAuthentication
        {
            get;
        }

        /// <summary>
        /// Questa property restituisce true se si stà utilizzando un identity provider.
        /// <para/>In caso di autenticazione tramite IDP
        /// </summary>
        /// <returns>
        ///     True se si utilizza un autenticazione esterna tramite IDP<para/>
        /// </returns>
        bool IsExternalAuthenticationEnabled
        {
            get;
        }

        /// <summary>
        /// Da valorizzare in caso di IsExternalAuthenticationEnabled = true, quindi in presenza di un IDP
        /// Valorizzare con l'url utilizzato per eseguire il challange di authenticazione verso l'IDP
        /// </summary>
        string ExternalAuthChallangeUrl
        {
            get;
        }
        
        /// <summary>
        /// Questo metodo restituisce un oggetto di tipo UserDetail dato uno user login.
        /// Viene restituito solo l'utente attivo
        /// </summary>
        /// <param name="UserLogin">Struttura dati</param>
        /// <returns>Utente attivo con lo user login richiesto</returns>
        Organigramma.UserDetails UtenteInformation(string UserLogin);
        Organigramma.UserDetails UtenteInformation(string UserLogin, bool bIncludeDisabled = false);
        /// <summary>
        /// Restituisce un oggetto di tipo RoleUserCollection contentente 
        /// tutti i ruoli e l'associazione relativa all'utente impostato
        /// </summary>
        /// <param name="IdUser">Id User recuperato dall'utente selezionato in Web UI</param>
        /// <returns>Interfaccia di tipo IRoleUserCollection già valorizzata</returns>
        //IRoleUserCollection GetRoleColecction();
        /// <summary>
        /// Restituisce per ciascun utente:
        ///     IdUtente: rappresenta l'id dell'utente presente nella tabella
        ///     UserLogin: rappresenta la struserLogin della tabella
        ///     NomeUtente: rappresenta la colonna Nome Utente all'interno della tabella
        ///     Email: rappresenta la strEmail presente nella tabella
        /// I dati sono ordinati per Cognome e Nome
        /// </summary>
        /// <param name="JustActive">
        ///     Parametro di default che recupera solo gli utenti attivi. 
        ///     Passare false per avere tutti gli utenti compresi quelli disabilitati
        /// </param>
        /// <returns></returns>
        DataTable GetListaUtenti(bool JustActive = true);
    }
}
