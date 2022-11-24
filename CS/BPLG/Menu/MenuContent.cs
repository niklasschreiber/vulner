//using System;
//using System.Data;
//using System.Configuration;
//using System.Web;
//using System.Web.Security;
//using System.Web.UI;
//using System.Web.UI.WebControls;
//using System.Web.UI.WebControls.WebParts;
//using System.Web.UI.HtmlControls;
//using System.Collections;

///// <summary>
///// Summary description for MenuContent
///// </summary>
//public static class MenuContent
//{
//    //public const string c_strMainSite = "";
//    //private static Hashtable m_htMainMenu;

//    //public static string MainMenuContent(string strUserName, string strMenuName, string currPage)
//    //{
//    //    string strReturn = ""; 
//    //    try
//    //    {
//    //        LoadMenuContent();
//    //        if (strMenuName != "Home") MainMenuContentDetail(ref strReturn, strUserName, ((MenuItem)m_htMainMenu[strMenuName]), currPage);
//    //        //IDictionaryEnumerator enu = ((MenuItem)m_htMainMenu[strMenuName]).Child().GetEnumerator();
//    //        //while (enu.MoveNext())
//    //        //{
//    //        //    MainMenuContentDetail(ref strReturn, strUserName, ((MenuItem)enu.Value), currPage);
//    //        //}
//    //        for(Int32 intLoop = 0; intLoop<((MenuItem)m_htMainMenu[strMenuName]).Child().Count; intLoop++)
//    //            MainMenuContentDetail(ref strReturn, strUserName, (MenuItem)((MenuItem)m_htMainMenu[strMenuName]).Child()[intLoop.ToString()], currPage);
//    //    }
//    //    catch (Exception ex)
//    //    {
//    //        General.Logger.Write(BPLG.Logging.Logger.LogTypeMessage.Error, ex.Message, ex);
//    //    }
//    //    return strReturn;
//    //}

//    //private static void MainMenuContentDetail(ref string strReturn, string strUserName, MenuItem mnu, string currPage)
//    //{
//    //    try
//    //    {
//    //        if (AllowedMenu(mnu, strUserName))
//    //        {
//    //            if (currPage == "ReportEffettiScaduti.aspx" | currPage == "ReportEffettiScadenzaGG20.aspx" | currPage == "ReportEffettiRendicontazioni.aspx")
//    //            {
//    //                currPage = "ReportEffettiRiscontrati.aspx";
//    //            }
//    //                    if (mnu.MenuLink().ToString() != currPage)
//    //                    {
//    //                        strReturn += "&nbsp; | &nbsp";
//    //                        strReturn += "<a class=\"mainmenu\" href=\"" + mnu.MenuLink() + "\"><span>" + mnu.MenuName() + "</span></a>";
//    //                    }
//    //                    else
//    //                    {
//    //                        strReturn += "&nbsp; | &nbsp";
//    //                        strReturn += "<a class=\"activeitem\" href=\"" + mnu.MenuLink() + "\"><span>" + mnu.MenuName() + "</span></a>";
//    //                    }
//    //        }
//    //    }
//    //    catch (Exception ex)
//    //    {
//    //        General.Logger.Write(BPLG.Logging.Logger.LogTypeMessage.Error, ex.Message, ex);
//    //    }
//    //    return;
//    //}

//    //public static string PageMenuContent(string strUserName, string strMenuName)
//    //{
//    //    string strReturn = "";
//    //    try
//    //    {
//    //        LoadMenuContent();
//    //        //IDictionaryEnumerator enu = ((MenuItem)m_htMainMenu[strMenuName]).Child().GetEnumerator();
//    //        //while (enu.MoveNext())
//    //        //{
//    //        //    strReturn += PageMenuContentDetail(strUserName, ((MenuItem)enu.Value));
//    //        //}
//    //        for (Int32 intLoop = 0; intLoop < ((MenuItem)m_htMainMenu[strMenuName]).Child().Count; intLoop++)
//    //            strReturn += PageMenuContentDetail(strUserName, (MenuItem)((MenuItem)m_htMainMenu[strMenuName]).Child()[intLoop.ToString()]);
//    //    }
//    //    catch (Exception ex)
//    //    {
//    //        //Logging.Write("" + ex.Message, System.Diagnostics.EventLogEntryType.Error);
//    //        General.Logger.Write(BPLG.Logging.Logger.LogTypeMessage.Error, ex.Message, ex);
//    //    }
//    //    return strReturn;
//    //}

//    //private static string PageMenuContentDetail(string strUserName, MenuItem mnu)
//    //{
//    //    string strReturn = "";
//    //    try
//    //    {
//    //        if (AllowedMenu(mnu, strUserName))
//    //        {
//    //            strReturn += "<tr><td height=\"50\" width=\"250\" align=\"right\">";
//    //            strReturn += "<img src=\"" + c_strMainSite + "Images/BNPLogo.gif\" />";
//    //            strReturn += "</td><td width=\"10\"></td><td class=\"special\" align=\"left\">";
//    //            strReturn += "<a class=\"menu\" href=\"" + mnu.MenuLink() + "\">" + mnu.MenuName() + "</a>";
//    //            strReturn += "</td><td></td></tr>";
//    //        }
//    //    }
//    //    catch (Exception ex)
//    //    {
//    //        General.Logger.Write(BPLG.Logging.Logger.LogTypeMessage.Error, ex.Message, ex);
//    //    }
//    //    return strReturn;
//    //}

//    ///// <summary>
//    ///// Carica la struttura vera e propria dei menu di navigazione del sito 
//    ///// </summary>
//    //public static void LoadMenuContent()
//    //{
//    //    m_htMainMenu = new Hashtable();
//    //    m_htMainMenu.Add("HelpDesk", new MenuItem("HelpDesk", "HelpDesk", "Start.aspx", ""));
//    //    ((MenuItem)m_htMainMenu["HelpDesk"]).AddChild(new MenuItem("0", "Nuova Richiesta", "NuovaRichiesta.aspx", ""));
//    //    //((MenuItem)m_htMainMenu["HelpDesk"]).AddChild(new MenuItem("1", "Le mie richieste", "RichiesteUser.aspx", ""));
//    //    //((MenuItem)m_htMainMenu["HelpDesk"]).AddChild(new MenuItem("2", "Richieste in corso", "RichiesteResolver.aspx", "MainMenu_MenuRichiesteResolver"));
//    //    //((MenuItem)m_htMainMenu["HelpDesk"]).AddChild(new MenuItem("3", "Storico richieste", "Storico.aspx", "MainMenu_MenuStorico"));
//    //    //((MenuItem)m_htMainMenu["HelpDesk"]).AddChild(new MenuItem("4", "Statistiche", "Stats.aspx", "Statistiche_Viewer"));

//    //    //m_htMainMenu.Add("Statistiche", new MenuItem("Statistiche", "Statistiche", "Stats.aspx", "Statistiche_Viewer"));
//    //    //((MenuItem)m_htMainMenu["Statistiche"]).AddChild(new MenuItem("0", "Statistiche HelpDesk", "HelpDeskStatistiche.aspx", "Statistiche_Viewer"));
//    //    //((MenuItem)m_htMainMenu["Statistiche"]).AddChild(new MenuItem("1", "Riepilogo richieste per servizio", "HelpDeskStatisticheServizi.aspx", "Statistiche_Viewer"));
//    //    //((MenuItem)m_htMainMenu["Statistiche"]).AddChild(new MenuItem("2", "Incidenti", "Incidenti.aspx", "Statistiche_Viewer"));
//    //    //((MenuItem)m_htMainMenu["Statistiche"]).AddChild(new MenuItem("3", "Attività risorse", "Risorse.aspx", "Risorse_Viewer"));
//    //    //HelpDeskStatisticheServizi.aspx

//    //    //((MenuItem)m_htMainMenu["HelpDesk"]).AddChild(new MenuItem("4", "Statistiche", "Statistiche.aspx", ""));
//    //    //((MenuItem)m_htMainMenu["HelpDesk"]).AddChild(new MenuItem("5", "Report Incidenti", "ReportIncidenti.htm", ""));

//    //    //Release 2
//    //    //((MenuItem)m_htMainMenu["HelpDesk"]).AddChild(new MenuItem("4", "Statistiche", "Statistiche.aspx", "MainMenu_MenuStatistiche"));
//    //    //((MenuItem)m_htMainMenu["HelpDesk"]).AddChild(new MenuItem("4", "Il mio calendario", "Calendario.aspx", "MainMenu_MenuCalendario"));
//    //}

//    ///// <summary>
//    ///// Verifica che l'utente abbia le credenziali per accedere al menu
//    ///// </summary>
//    ///// <param name="mnu">menu item</param>
//    ///// <param name="strUserName">nome utente</param>
//    ///// <returns>indica se l'utente ha diritto ad accedere al menu</returns>
//    //private static bool AllowedMenu(MenuItem mnu, string strUserName)
//    //{
//    //    //if (mnu.MenuGroupPermission().Length == 0) return true;
//    //    //return BPLG.Security.LDAP.UserHasPermission(strUserName, mnu.MenuGroupPermission()); 
//    //    if (mnu.MenuOperation() == "") return true;
//    //    return General.Sec.HasPermission(mnu.MenuOperation());
//    //}

//}
