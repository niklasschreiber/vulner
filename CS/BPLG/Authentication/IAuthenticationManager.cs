using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using BPLG.Organigramma;

namespace BPLG.Authentication
{
    public interface IAuthenticationManager
    {
        /// <summary>
        /// Questo metodo restituisce un flag che indica se l'utente è o meno loggato all'applicativo.
        /// </summary>
        /// <returns>True se l'utente risulta loggato</returns>
        bool IsLogged();
        /// <summary>
        /// Questa property restituisce un informazione circa la presenza della Windows Authentication
        /// </summary>
        bool IsIntegrated { get; } 
        /// <summary>
        /// Questo metodo verifica se l'utente ha la permission per effettuare una determinata
        /// funzione. La permission viene passata dal caller e viene verificato sul db che si abbiano
        /// le policy per utilizzarla.
        /// </summary>
        /// <param name="strOperation">Operation di cui si vuole sapere se si ha o meno la permission</param>
        /// <param name="UserParameter">Utente da testare</param>
        /// <param name="UserData">Objcet contenente i dati dell'utente</param>
        /// <returns>True se l'utente ha la permission richiesta</returns>
        [Obsolete("Questo metodo non deve più essere utilizzato con la nuova struttura")]
        bool HasPermission(string strOperation, string UserParameter, AuthenticationPolicy.UserData UserData);
        /// <summary>
        /// Questo metodo verifica la permission per l'utente correntemente loggato.
        /// </summary>
        /// <param name="strOperation">Operation di cui verificare la permission</param>
        /// <returns>True se l'utente ha la permission richiesta</returns>
        [Obsolete("Questo metodo non deve più essere utilizzato con la nuova struttura")]
        bool HasPermission(string strOperation);
        /// <summary>
        /// Questo metodo permette di effettuare un cambio password attraverso la vecchia
        /// password e una nuova che viene scelta dall'utente. Effettua il cambio password 
        /// sull'utente corrente loggato
        /// </summary>
        /// <param name="oldPassword">Vecchia password inserita dell'utente</param>
        /// <param name="newPassword">Nuova password inserita dall'utente</param>
        /// <returns>True se il cambio password si è concluso con successo</returns>
        AuthenticationPolicy.PasswordChange CambioPassword(string oldPassword, string newPassword);
        /// <summary>
        /// Questo metodo verifica se la password passata come parametro soddisfa i requisiti di complessità
        /// </summary>
        /// <param name="passwordToCheck">Password inserita dall'utente</param>
        /// <returns>False nel caso la password non soddisfi i requisiti altrimenti True</returns>
        bool PasswordComplexityCheck(string passwordToCheck);

        /// <summary>
        /// Questo metodo permette il reset della password. Il reset della password creerà una password
        /// temporanea basata su TIMESTAMP hashato in formato SHA512 per memorizzare un token univoco da
        /// ripresentare all'utente sulla mail col link attraverso il quale l'utente potrà procedere a
        /// reimpostare la propria password
        /// </summary>
        /// <param name="userName">UserName inserito dall'utente</param>
        /// <returns>True se l'operazione è andata a buon fine oppure false in caso non sia riuscita</returns>
        AuthenticationPolicy.PasswordReset ResetPassword(out string TimeStampPassword, string UserName = null);
        /// <summary>
        /// Questo metodo permette di effettuare un Login attraverso una user e una
        /// password. Se il tipo di autenticazione è DBAZMDOMAIN questo metodo 
        /// lancierà un'eccezione
        /// </summary>
        /// <param name="strUsername">Nome utente, corrisponde alla User Login</param>
        /// <param name="strPassword">Password utente</param>
        /// <returns>Enumeration per indicare lo stato della Login</returns>
        AuthenticationPolicy.LoginResults LoginWithResult(string strUsername, string strPassword, bool IsImpersonale = false);
        /// <summary>
        /// Dettagli relativi all'utente loggato. Questa classe contiene 
        /// delle property in cui sono memorizzati i dati utente
        /// </summary>
        UserDetails UserDetail { get; }
        /// <summary>
        /// Questo metodo restituisce un'istanza dell'interfaccia che permetterà
        /// all'utente di utilizare i metodi della chain di classi
        /// </summary>
        /// <returns>Interfaccia della classe specifica all'interno della chain di ereditarietà</returns>
        IAuthenticationManager GetInstance();
        AuthenticationPolicy.UserLoggedStatus LoggedStatus();
    }
}
