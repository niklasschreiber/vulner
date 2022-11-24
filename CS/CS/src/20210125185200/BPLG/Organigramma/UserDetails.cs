using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace BPLG.Organigramma
{
    public class UserDetails
    {
        #region PROPERTIES
        public string Name { get; set; }
        public string Surname { get; set; }
        public string DisplayName { get; set; }
        public string UserName { get; set; }
        /// <summary>
        /// Questa property restituisce il nome dell'utente al netto dell'impersonificazione
        /// </summary>
        public string OriginallyUserName { get; set; }
        public string IdUtente { get; set; }
        public int GiorniRimanentiPassword { get; set; }
        public byte[] ImmagineUtente { get; set; }
        public string MimeType { get; set; }
        public string Email { get; set; }
        public string Telephone { get; set; }
        #endregion PROPERTIES
    }
}
