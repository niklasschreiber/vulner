using System;
using System.Collections.Generic;
using System.Text;

namespace BPLG.Reporting
{
    public class SSRSReportCredentials : Microsoft.Reporting.WebForms.IReportServerCredentials
    {
        string _userName, _password, _domain;

        public SSRSReportCredentials(string userName, string password, string domain)
        {
            _userName = userName;
            _password = password;
            _domain = domain;
        }

        public System.Security.Principal.WindowsIdentity ImpersonationUser
        {
            get
            {
                return null;
            }
        }    
        
        public System.Net.ICredentials NetworkCredentials 
        { 
            get 
            { 
                return new System.Net.NetworkCredential(_userName, _password, _domain); 
            } 
        }    
        
        public bool GetFormsCredentials(out System.Net.Cookie authCoki, out string userName, out string password, out string authority) 
        { 
            userName = _userName; 
            password = _password; 
            authority = _domain; authCoki = new System.Net.Cookie(".ASPXAUTH", ".ASPXAUTH", "/", "Domain"); return true; 
        }
    }
}
