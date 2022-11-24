using System;
using System.Collections.Generic;
using System.Text;
using System.Data;

namespace BPLG.Security
{
    class RoleUserCollection : IRoleUserCollection
    {
        #region VARIABILI
        private int m_IdUser;
        private bool m_IsRecuperatore = false;
        private bool m_IsLegale = false;
        private List<IRoleUser> m_ListRole = new List<IRoleUser>();
        private DBAuthorizationManager m_DBAuthorizationManager = null;
        #endregion VARIABILI

        #region PROPERTIES
        public bool IsRecuperatore
        {
            get
            {
                return m_IsRecuperatore;
            }
        }
        
        public List<IRoleUser> ListRole
        {
            get
            {
                return m_ListRole;
            }
        }

        public int IdUser
        {
            get
            {
                return m_IdUser;
            }
            set
            {
                m_IdUser = value;
            }
        }
        #endregion PROPERTIES

        #region CONSTRUCTOR
        public RoleUserCollection(ISecurityManager ISecurityManager)
        {
            m_DBAuthorizationManager = (DBAuthorizationManager)ISecurityManager;
        }
        #endregion CONSTRUCTOR

        #region METHODS

        #region PUBLIC
        /// <summary>
        /// Questo metodo si occupa di ciclare la collection e di inserire ogni
        /// item selected all'interno del database. Inizialmente vengono rimossi
        /// dal database tutti i valori già associati all'utente
        /// </summary>
        /// <returns></returns>
        public bool Commit()
        {
            if (m_IdUser > 0)
            {
                bool taskDoneCorrectly = true;
                try
                {
                    if (m_DBAuthorizationManager.RemoveRoleUser(m_IdUser))
                    {

                        foreach (RoleUser ActualRoleUser in m_ListRole)
                        {
                            if (ActualRoleUser.Selected)
                            {
                                if (ActualRoleUser.IsRecuperatore)
                                {
                                    m_IsRecuperatore = true;
                                }
                                taskDoneCorrectly &= m_DBAuthorizationManager.AddRoleUser(m_IdUser, ActualRoleUser.IdRole);
                            }
                        }
                    }
                    else
                    {
                        throw new Exception("Impossible to delete all Roles");
                    }
                }
                catch (Exception Ex)
                {
                    return false;
                }
                return taskDoneCorrectly;
            }
            else
            {
                return false;
            }
        }
        
        /// <summary>
        /// Tramite questo metodo è possibile ottenere uno specifico oggetto della
        /// collection a partire dal suo campo IdRole
        /// </summary>
        /// <param name="IdRole">Stringa rappresentante il ruolo da ricercare</param>
        /// <returns>IRoleUser trovato o null</returns>
        public IRoleUser GetRole(string IdRole)
        {
            IRoleUser RoleUser = m_ListRole.Find(delegate(IRoleUser InternalRoleUser)
                {
                    return InternalRoleUser.IdRole == IdRole;
                });
            return RoleUser;
        }

        public IRoleUser GetRoleLegale()
        {
            IRoleUser RoleUser = m_ListRole.Find(delegate(IRoleUser InternalRoleUser)
                {
                    return ((InternalRoleUser.IsLegale) && (InternalRoleUser.Selected));
                });
            return RoleUser;
        }
        #endregion PUBLIC

        #region INTERNAL
        /// <summary>
        /// Questo metodo si occupa di fillare la Collection. Viene chiamato una sola
        /// volta per l'inizializzazione dei valori
        /// </summary>
        /// <returns></returns>
        internal bool Read()
        {
            DataTable dtRoles = m_DBAuthorizationManager.GelRolesApplication(m_IdUser);
            DataTable dtFasi = m_DBAuthorizationManager.GetRuoliFasi();
            if ((dtRoles != null) && (dtFasi != null))
            {
                foreach (DataRow ActualDataRow in dtRoles.Rows)
                {
                    RoleUser RoleUser = new RoleUser();
                    RoleUser.Descrizione = ActualDataRow["Descrizione"].ToString();
                    RoleUser.IdRole = ActualDataRow["IdRole"].ToString();
                    if (!string.IsNullOrEmpty(ActualDataRow["Active"].ToString()))
                    {
                        RoleUser.Selected = true;
                    }
                    if (Convert.ToBoolean(ActualDataRow["IsRecuperatore"].ToString()))
                    {
                        RoleUser.IsRecuperatore = true;
                    }

                    #region LEGALE
                    if (Convert.ToBoolean(ActualDataRow["IsLegale"].ToString()))
                    {
                        RoleUser.IsLegale = true;
                        if (Convert.ToBoolean(ActualDataRow["Convenzionato"].ToString()))
                        {
                            RoleUser.IsConvenzionato = true;
                        }

                        if (Convert.ToBoolean(ActualDataRow["Civile"].ToString()))
                        {
                            RoleUser.IsCivile = true;
                        }

                        if (Convert.ToBoolean(ActualDataRow["Penale"].ToString()))
                        {
                            RoleUser.IsPenale = true;
                        }
                    }
                    #endregion LEGALE

                    if (RoleUser.IsRecuperatore)
                    {
                        foreach (DataRow ActualData in dtFasi.Select("IdRole = '" + RoleUser.IdRole + "'"))
                        {
                            RoleUser.Fasi.Add(ActualData["IdFase"].ToString(), ActualData["DescrizioneFase"].ToString());
                        }
                    }
                    
                    m_ListRole.Add(RoleUser);
                }
                return true;
            }
            return false;
        }

        #endregion INTERNAL

        #endregion METHODS
    }
}
