using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using BPLG.Utility;

namespace BPLG.Authentication
{
    public class AuthenticationPolicy
    {
        public enum PasswordRules
        {
            /// <summary>
            /// L Password deve contenere Numeri
            /// </summary>
            Digit = 1,
            /// <summary>
            /// La Password deve contenere Lettere maiuscole
            /// </summary>
            UpperCase = 2,
            /// <summary>
            /// La Password deve contenere Lettere minuscole
            /// </summary>
            LowerCase = 4,
            /// <summary>
            /// La Password deve contenere lettere maiuscole e minuscole
            /// </summary>
            MixedCase = 6,
            /// <summary>
            /// La Passworde deve includere caratteri non alfanumerici
            /// </summary>
            SpecialChar = 8,
            /// <summary>
            /// Tutte le regole di complessità vanno applicate
            /// </summary>
            All = 15,
            /// <summary>
            /// Nessuna regola di compelssità va applicata
            /// </summary>
            None = 0
        }

        public enum PasswordChange 
        {
            [MappingEnumeration("Errore imprevisto in fase di Cambio Password. La preghiamo di contattare l'amministratore di sistema")]
            EmptyResult = 0,
            [MappingEnumeration("Cambio Password effettuato con successo")]
            ChangeSuccessfull = 1,
            [MappingEnumeration("La Password precedente o la password temporanea sono errate.")]
            LastPasswordError = 2,
            [MappingEnumeration("La Password specificata è già stata utilizzata in precedenza.")]
            PasswordExists = 3
        }

        public enum PasswordReset 
        {
            [MappingEnumeration("Errore imprevisto in fase di Reset Password. La preghiamo di contattare l'amministratore di sistema")]
            EmptyResult = 0,
            [MappingEnumeration("Reset della password effettuata con successo <br/> É stata inviata una mail con le indicazioni da seguire per completare la sua richiesta.")]
            ResetSuccessfull= 1,
            [MappingEnumeration("L'utente specificato non è stato trovato. <br>Reset password non effettuata.")]
            UserNotFound = 2
        }

        public enum PasswordCheck
        {
            [MappingEnumeration("To implement")]
            /// <summary>
            /// Password OK
            /// </summary>
            OK = 1,
            [MappingEnumeration("To implement")]
            /// <summary>
            /// Wrong Password Complexity
            /// </summary>
            WrongComplexity = 2,
            [MappingEnumeration("To implement")]
            /// <summary>
            /// Password già utilizzata
            /// </summary>
            WrongAlreadyUsed = 3
        }

        public enum LoginResults
        {
            [MappingEnumeration("Nessuna operazione effettuata")]
            /// <summary>
            /// Enum di default per il none operation
            /// </summary>
            NoOperation = 0,
            [MappingEnumeration("To implement")]
            /// <summary>
            /// Login effettuato con Successo
            /// </summary>
            LoginOK = 1,
            [MappingEnumeration("Tentativo di accesso non riuscito<br />Login errata")]
            /// <summary>
            /// Tentativo di Accesso non riuscito
            /// </summary>
            LoginErrato = 2,
            [MappingEnumeration("L'account risulta bloccato a seguito di troppi tentativi di Login errati")]
            /// <summary>
            /// L' Account risulta Bloccato per superamento soglia tentativi
            /// </summary>
            LoginBloccato = 3,
            [MappingEnumeration("L'account è stato bloccato a seguito dell'utlimo tentativo di Login errato")]
            /// Account è stato Bloccato a seguito dell'ultimo tentativo
            /// </summary>
            BloccoLogin = 4,
            [MappingEnumeration("La funzionalità di Login non è permessa per questa applicazione")]
            /// <summary>
            /// Impostato quando il login non deve essere permesso, esempioa ctive directory
            /// </summary>
            LoginNotAllowed = 5,
            [MappingEnumeration("<b>Attenzione: La tua password è scaduta.</b><br />E&#39;necessario specificare una nuova password per accedere alle risorse richieste.")]
            /// <summary>
            /// Password scaduta, necessario cambiare password
            /// </summary>
            PasswordWxpired = 6,
            [MappingEnumeration("Si è verificato un errore interno, le credenziali inserite sono comunque corrette")]
            /// <summary>
            /// Questo valore informa che non è stato possibile ricavare i dati relativi all'utente. 
            /// La login è avvenuta con successo, denomina un errore interno
            /// </summary>
            WrongUserDetail = 99
        }

        public enum UserData
        {
            UserId = 0,
            UserLogin = 1
        }

        public enum UserLoggedStatus
        {
            NotLogged = 0,
            AlreadyLogged = 1,
            NotAuthorized = 2
        }
    }
}
