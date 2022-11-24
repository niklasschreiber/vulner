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
    public class PageMenuItem : WebControl
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

        public delegate bool HasPermission(string strOperation);
        private string m_strOperation;
        private string m_strMenuImage;
        private string m_strMenuName;
        private string m_strMenuLink;
        private string m_Class = "menu";
        private int m_intPixelHeight;
        private bool m_Visible = false;

        public PageMenuItem(string strMenuImage, int intPixelHeight, string strMenuName, string strMenuLink, string strOperation, HasPermission hasPerm)
        {
                //Ha le autorizzazioni
                m_strMenuImage = strMenuImage;
                m_strMenuName = strMenuName;
                m_strMenuLink = strMenuLink;
                m_strOperation = strOperation;
                m_intPixelHeight = intPixelHeight;
                m_Visible = true;

        }
        protected override void RenderContents(HtmlTextWriter output)
        {
            if (m_Visible)
            {
                if (m_strMenuImage != "")
                    output.Write("<img src=\"" + m_strMenuImage + "\" />&nbsp&nbsp");
                if (m_strMenuLink != "")
                    output.Write("<a class=\"" + Class + "\" href=\"" + m_strMenuLink + "\" style=\"display:inline-block;height:" + m_intPixelHeight.ToString() + "px;\" >");
                output.Write(m_strMenuName);
                if (m_strMenuLink != "")
                    output.Write("</a>");
                output.Write("<p />");
            }
        }

    }
}
