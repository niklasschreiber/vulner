using System;
using System.Collections.Generic;
namespace BPLG.Security
{
    public interface IRoleUser
    {
        string Descrizione
        {
            get;
        }
        string IdRole
        {
            get;
        }
        bool Selected
        {
            get;
            set;
        }
        bool IsRecuperatore
        {
            get;
        }

        bool IsLegale
        {
            get;
            set;
        }

        bool IsConvenzionato
        {
            get;
        }

        bool IsCivile
        {
            get;
        }

        bool IsPenale
        {
            get;
        }

        Dictionary<string, string> Fasi
        {
            get;
        }
    }
}
