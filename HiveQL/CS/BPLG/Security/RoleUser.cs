using System;
using System.Collections.Generic;
using System.Text;

namespace BPLG.Security
{
    class RoleUser : IRoleUser
    {
        #region VARIABLES
        private bool m_Selected = false;
        private string m_IdRole = string.Empty;
        private string m_Descrizione = string.Empty;
        private bool m_IsRecuperatore = false;
        private bool m_IsLegale = false;
        private Dictionary<string, string> m_Fasi = new Dictionary<string, string>();
        private bool m_IsConvenzionato = false;
        private bool m_IsCivile = false;
        private bool m_IsPenale = false;
        #endregion VARIABLES

        #region PARAMETERS
        public bool Selected
        {
            get
            {
                return m_Selected;
            }
            set
            {
                m_Selected = value;
            }
        }
        public string IdRole
        {
            get
            {
                return m_IdRole;
            }
            internal set
            {
                m_IdRole = value;
            }
        }
        public string Descrizione
        {
            get
            {
                return m_Descrizione;
            }
            internal set
            {
                m_Descrizione = value;
            }
        }
        public bool IsRecuperatore
        {
            get
            {
                return m_IsRecuperatore;
            }
            internal set
            {
                m_IsRecuperatore = value;
            }
        }
        public bool IsLegale
        {
            get
            {
                return m_IsLegale;
            }
            set
            {
                m_IsLegale = value;
            }
        }
        public Dictionary<string, string> Fasi
        {
            get
            {
                return m_Fasi;
            }
        }
        public bool IsConvenzionato
        {
            get
            {
                return m_IsConvenzionato;
            }
            internal set
            {
                m_IsConvenzionato = value;
            }
        }
        public bool IsCivile
        {
            get
            {
                return m_IsCivile;
            }
            internal set
            {
                m_IsCivile = value;
            }
        }
        public bool IsPenale
        {
            get
            {
                return m_IsPenale;
            }
            internal set
            {
                m_IsPenale = value;
            }
        }
        #endregion PARAMETERS
    }
}
