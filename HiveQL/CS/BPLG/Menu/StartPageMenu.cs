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
    [ToolboxData("<{0}:PageMenuItem runat=server></{0}:PageMenuItem>")]
    public class StartPageMenu : WebControl
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

        public string Class
        {
            set
            {
                m_Class = value;
            }
            internal get
            {
                return m_Class;
            }
        }

        public string Padding
        {
            set
            {
                m_Padding = value;
            }
            internal get
            {
                return m_Padding;
            }
        }

        public string Target
        {
            set
            {
                m_Target = value;
            }
            internal get
            {
                return m_Target;
            }
        }

        public delegate bool HasPermission(string strOperation, bool UseRealname = false);
        private string m_strOperation;
        private string m_strMenuImage;
        private string m_strMenuName;
        private string m_strMenuLink;
        private string m_Target = "_self";
        private string m_Class = "menu";
        private string m_Padding = "";
        private int m_intPixelHeight;
        private bool m_Visible = false;

        public StartPageMenu(string strMenuImage, int intPixelHeight, string strMenuName, string strMenuLink, string strOperation, HasPermission hasPerm)
            :this(strMenuImage, intPixelHeight, strMenuName, strMenuLink, strOperation, hasPerm, null)
        {
        }

        public StartPageMenu(string strMenuImage, int intPixelHeight, string strMenuName, string strMenuLink, string strOperation, HasPermission hasPerm, String Target)
        {
            //Ha le autorizzazioni
            m_strMenuImage = strMenuImage;
            m_strMenuName = strMenuName;
            m_strMenuLink = strMenuLink;
            m_strOperation = strOperation;
            m_intPixelHeight = intPixelHeight;
            m_Target = (Target == null ? m_Target : Target);
            m_Visible = true;

        }


        protected override void RenderContents(HtmlTextWriter output)
        {
            if (m_Visible)
            {
                output.Write("<div id=\"MenuItem\" class=\"PaddingItem\">");
                #region GESTIONE IMMAGINE O DIV
                if (m_strMenuImage != "")
                {
                    output.Write("<img src=\"" + m_strMenuImage + "\" style=\"vertical-align:middle;" + Padding + "\"/>&nbsp&nbsp");
                }
                else
                {
                    output.Write("<div id=\"MenuItemBullet\"></div>");
                }
                #endregion GESTIONE IMMAGINE O DIV

                if (m_strMenuLink != "")
                {
                    output.Write("<a class=\"" + Class + "\" href=\"" + m_strMenuLink + "\" target=\"" + m_Target + "\" style=\"display:inline-block;height:" + m_intPixelHeight.ToString() + "px;\" >");
                }
                output.Write(m_strMenuName);
                if (m_strMenuLink != "")
                {
                    output.Write("</a>");
                }
                output.Write("</div>");
            }
        }

    }
}

