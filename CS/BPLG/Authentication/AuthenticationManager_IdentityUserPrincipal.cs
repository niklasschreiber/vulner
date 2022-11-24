using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Web;

namespace BPLG.Authentication
{
    class AuthenticationManager_IdentityUserPrincipal : AuthenticationManager
    {
        /// <summary>
        /// Questo metodo restituisce un'istanza dell'interfaccia che permetterà
        /// all'utente di utilizare i metodi della chain di classi
        /// </summary>
        /// <returns>Interfaccia della classe specifica all'interno della chain di ereditarietà</returns>
        public override IAuthenticationManager GetInstance()
        {
            throw new NotImplementedException();
        }

        /// <summary>
        /// Torna true se l'utente è loggato
        /// </summary>
        public override bool IsLogged()
        {
            return HttpContext.Current.User.Identity.IsAuthenticated;
        }

        /// <summary>
        /// Torna AuthenticationPolicy.UserLoggedStatus.AlreadyLogged se l'utente è loggato,
        /// altrimenti AuthenticationPolicy.UserLoggedStatus.NotLogged
        /// </summary>
        public override AuthenticationPolicy.UserLoggedStatus LoggedStatus()
        {
            return HttpContext.Current.User.Identity.IsAuthenticated ?
                AuthenticationPolicy.UserLoggedStatus.AlreadyLogged :
                AuthenticationPolicy.UserLoggedStatus.NotLogged;
        }
    }
}
