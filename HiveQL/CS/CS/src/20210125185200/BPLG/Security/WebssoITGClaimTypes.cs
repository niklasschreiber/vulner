using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace BPLG.Security
{
    /// <summary>
    /// Out of standard claims definition for WebSSO scope
    /// </summary>
    public static class WebssoITGClaimTypes
    {
        public const string UserRefog = "sUserRefog";

        public const string DisplayName = "sDisplayName";

        public const string sFirstname = "sFirstname";

        public const string sSurname = "sSurname";

        public const string sEmail = "sEmail";

        public const string UserRefogDefault = "uid";

        public const string DisplayNameDefault = "cn";

        public const string sFirstnameDefault = "sn";

        public const string sSurnameDefault = "givenName";

        public const string sEmailDefault = "mail";
    }
}
