using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Text;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace BPLG.Menu
{
    [DefaultProperty("Text")]
    [ToolboxData("<{0}:TopMenuItem runat=server></{0}:TopMenuItem>")]
    public class TopMenuItem : WebControl
    {
        [Bindable(true)]
        [Category("Appearance")]
        [DefaultValue("")]
        [Localizable(true)]
        public string Text
        {
            get
            {
                String s = (String)ViewState["Text"];
                return ((s == null) ? String.Empty : s);
            }

            set
            {
                ViewState["Text"] = value;
            }
        }

        public delegate bool HasPermission(string strOperation, bool UseRealname = false);
        private string m_strOperation;
        private string m_strMenuImage;
        private string m_strMenuName;
        private string m_strMenuLink;
        private string m_sCurrentPage;
        private bool m_Visible = false;
        public TopMenuItem(string strMenuImage, string strMenuName, string strMenuLink, string strOperation, HasPermission hasPerm, string sCurrentPage)
        {
            if (hasPerm.Invoke(strOperation, false))
            {
                //Ha le autorizzazioni
                m_strMenuImage = strMenuImage;
                m_strMenuName = strMenuName;
                m_strMenuLink = strMenuLink;
                m_strOperation = strOperation;
                m_sCurrentPage = sCurrentPage;
                m_Visible = true;
            }
            else
            {
                //Non ha le autorizzazioni
                m_Visible = false;
            }
        }
        protected override void RenderContents(HtmlTextWriter output)
        {
            if (m_Visible)
            {
                string strLinkStyle = "";
                if (m_sCurrentPage == m_strMenuLink)
                    strLinkStyle = "activeitem";
                else
                    strLinkStyle = "mainmenu";

                if (m_strMenuImage != "")
                    output.Write("IMMAGINE - Da implementare!");
                if (m_strMenuLink != "")
                    output.Write("&nbsp; | &nbsp<a class=\"" + strLinkStyle + "\" href=\"" + m_strMenuLink + "\">");
                else
                    output.Write("&nbsp; | &nbsp");
                output.Write("<span>" + m_strMenuName + "</span>");
                if (m_strMenuLink != "")
                    output.Write("</a>");
            }
        }
    }
}
