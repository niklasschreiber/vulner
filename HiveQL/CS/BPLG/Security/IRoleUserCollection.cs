using System;
namespace BPLG.Security
{
    public interface IRoleUserCollection
    {
        #region PROPERTIES
        /// <summary>
        /// Ottiene l'informazione circa lo stato della collection indicando se 
        /// contiene un ruolo da considerare recuperatore.
        /// </summary>
        bool IsRecuperatore
        {
            get;
        }
        
        /// <summary>
        /// Ottiene o imposta la User Id dell'utente
        /// </summary>
        int IdUser
        {
            get;
            set;
        }
        
        /// <summary>
        /// Ottiene l'oggetto Collection contenente tutti i ruoli ricavati
        /// dal database. Restituisce una lista castata a tipi IRoleUser
        /// </summary>
        System.Collections.Generic.List<IRoleUser> ListRole
        {
            get;
        }
        #endregion PROPERTIES
        
        #region METHODS
        /// <summary>
        /// Questo metodo si occupa di ciclare la collection e di inserire ogni
        /// item selected all'interno del database. Inizialmente vengono rimossi
        /// dal database tutti i valori già associati all'utente
        /// </summary>
        /// <returns>Indica se l'operazione è andata a buon fine o meno</returns>
        bool Commit();

        /// <summary>
        /// Tramite questo metodo è possibile ottenere uno specifico oggetto della
        /// collection a partire dal suo campo IdRole
        /// </summary>
        /// <param name="IdRole">Stringa rappresentante il ruolo da ricercare</param>
        /// <returns>IRoleUser trovato o null</returns>
        IRoleUser GetRole(string IdRole);

        IRoleUser GetRoleLegale();
        #endregion METHODS
    }
}
