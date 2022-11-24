<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Grails 101 - ${day}</title>

    <style type="text/css">
    body,#bodyTable,#bodyCell{
        height:100% !important;
        margin:0;
        padding:0;
        width:100% !important;
    }
    table{
        border-collapse:collapse;
    }
    img,a img{
        border:0;
        outline:none;
        text-decoration:none;
    }
    h1,h2,h3,h4,h5,h6{
        margin:0;
        padding:0;
    }
    p{
        margin:1em 0;
    }
    .ReadMsgBody{
        width:100%;
    }
    .ExternalClass{
        width:100%;
    }
    .ExternalClass,.ExternalClass p,.ExternalClass span,.ExternalClass font,.ExternalClass td,.ExternalClass div{
        line-height:100%;
    }
    table,td{
        mso-table-lspace:0pt;
        mso-table-rspace:0pt;
    }
    #outlook a{
        padding:0;
    }
    img{
        -ms-interpolation-mode:bicubic;
    }
    body,table,td,p,a,li,blockquote{
        -ms-text-size-adjust:100%;
        -webkit-text-size-adjust:100%;
    }
    @media only screen and (max-width: 480px){
        td[id=introductionContainer],td[id=callToActionContainer],td[id=eventContainer],td[id=merchandiseContainer],td[id=footerContainer]{
            padding-right:10px !important;
            padding-left:10px !important;
        }

    }   @media only screen and (max-width: 480px){
        table[id=introductionBlock],table[id=callToActionBlock],table[id=eventBlock],table[id=merchandiseBlock],table[id=footerBlock]{
            max-width:480px !important;
            width:100% !important;
        }

    }   @media only screen and (max-width: 480px){
        body{
            width:100% !important;
            min-width:100% !important;
        }

    }   @media only screen and (max-width: 480px){
        h1{
            font-size:34px !important;
        }

    }   @media only screen and (max-width: 480px){
        h2{
            font-size:30px !important;
        }

    }   @media only screen and (max-width: 480px){
        h3{
            font-size:24px !important;
        }

    }   @media only screen and (max-width: 480px){
        img[id=heroImage]{
            height:auto !important;
            max-width:600px !important;
            width:100% !important;
        }

    }   @media only screen and (max-width: 480px){
        td[class=introductionLogo],td[class=introductionHeading]{
            display:block !important;
        }

    }   @media only screen and (max-width: 480px){
        td[class=introductionHeading]{
            padding:40px 0 0 0 !important;
        }

    }   @media only screen and (max-width: 480px){
        td[class=introductionContent]{
            padding-top:20px !important;
        }

    }   @media only screen and (max-width: 480px){
        td[class=callToActionContent]{
            text-align:left !important;
        }

    }   @media only screen and (max-width: 480px){
        table[class=callToActionButton]{
            width:100% !important;
        }

    }   @media only screen and (max-width: 480px){
        td[id=eventBlockCell]{
            padding-right:20px !important;
            padding-left:20px !important;
        }

    }   @media only screen and (max-width: 480px){
        table[class=eventBlockCalendar]{
            width:100px !important;
        }

    }   @media only screen and (max-width: 480px){
        td[id=merchandiseBlockCell]{
            padding-right:20px !important;
            padding-left:20px !important;
        }

    }   @media only screen and (max-width: 480px){
        td[class=merchandiseBlockHeading] h2{
            text-align:center !important;
        }

    }   @media only screen and (max-width: 480px){
        td[class=merchandiseBlockLeftColumn],td[class=merchandiseBlockRightColumn]{
            display:block !important;
            padding:0 0 20px 0 !important;
            width:100% !important;
        }

    }   @media only screen and (max-width: 480px){
        td[class=footerContent]{
            font-size:15px !important;
        }

    }   @media only screen and (max-width: 480px){
        td[class=footerContent] a{
            display:block;
        }

    }</style></head>
<body style="margin: 0;padding: 0;-ms-text-size-adjust: 100%;-webkit-text-size-adjust: 100%;background-color: #F5F5F5;height: 100%;width: 100%;">
<center>
    <table border="0" cellpadding="0" cellspacing="0" height="100%" width="100%" id="bodyTable" style="border-collapse: collapse;mso-table-lspace: 0pt;mso-table-rspace: 0pt;-ms-text-size-adjust: 100%;-webkit-text-size-adjust: 100%;margin: 0;padding: 0;background-color: #F5F5F5;height: 100%;width: 100%;">
        <tr>
            <td align="center" valign="top" id="bodyCell" style="mso-table-lspace: 0pt;mso-table-rspace: 0pt;-ms-text-size-adjust: 100%;-webkit-text-size-adjust: 100%;margin: 0;padding: 0;height: 100%;width: 100%;">
                <!-- // BEGIN EMAIL -->
                <table border="0" cellpadding="0" cellspacing="0" width="100%" id="emailContainer" style="border-collapse: collapse;mso-table-lspace: 0pt;mso-table-rspace: 0pt;-ms-text-size-adjust: 100%;-webkit-text-size-adjust: 100%;width: 100%;">
                    <tr>
                        <td align="center" valign="top" id="callToActionContainer" style="mso-table-lspace: 0pt;mso-table-rspace: 0pt;-ms-text-size-adjust: 100%;-webkit-text-size-adjust: 100%;background-color: #F5F5F5;padding: 40px;">

                            <!-- // BEGIN CALL-TO-ACTION BLOCK -->
                            <table border="0" cellpadding="0" cellspacing="0" width="600" style="border-collapse: collapse;mso-table-lspace: 0pt;mso-table-rspace: 0pt;-ms-text-size-adjust: 100%;-webkit-text-size-adjust: 100%;background-color: #F5F5F5;">
                                <tr>
                                    <td align="center" valign="middle" style="padding-bottom: 40px;"><a href="http://grails.org?utm_campaign=dayone&utm_source=onezeroone&utm_medium=tx_email"><img src="https://grails.org/images/grails_logo.svg" alt="Grails" width="107" height="107"/></a></td>
                                </tr>
                                <tr>
                                    <td align="center" valign="top"  style="mso-table-lspace: 0pt;mso-table-rspace: 0pt;-ms-text-size-adjust: 100%;-webkit-text-size-adjust: 100%;font-family: &quot;Helvetica Neue&quot;, Helvetica, Arial, sans-serif;font-size: 60px;text-align: center;line-height: 150%;color: #FFFFFF;background-color: #255AA8;padding: 60px;"><b>GRAILS 101<br/>${day}</b>
                                    </td>
                                </tr>
                                <tr>
                                    <td align="center" valign="top"  style="mso-table-lspace: 0pt;mso-table-rspace: 0pt;-ms-text-size-adjust: 100%;-webkit-text-size-adjust: 100%;font-family: &quot;Helvetica Neue&quot;, Helvetica, Arial, sans-serif;font-size: 16px;line-height: 150%;color: #6A6D78;background-color: #ffffff;padding: 30px 30px 20px 30px;text-align: left;"><b>${title}</b>
                                        <br/>
                                        ${body}
                                    </td>
                                </tr>

                                <tr>
                                    <td align="center" style="background-color: #ffffff;text-align: center;padding-left: 60px;padding-right: 60px;padding-bottom: 30px;">
                                        <table border="0" cellpadding="0" cellspacing="0" width="100%;" style="width: 100%;border-collapse: collapse;mso-table-lspace: 0pt;mso-table-rspace: 0pt;">
                                            <tr>
                                                <td width="33%" style="width: 33%;">&nbsp;</td>
                                                <td align="center" valign="center" bgcolor="#FB005A" width="33%" style="background:#FB005A; text-align: center; width: 33% !important;color: #ffffff;background-color: #feb672 !important;padding-top: 25px;font-size: 16px;line-height: 150%;padding-bottom: 25px;text-align: center;-moz-border-radius: 5px; -webkit-border-radius: 5px; border-radius: 5px;"><a href="${guideUrl}" style="color: #FFFFFF; text-decoration:none; margin: 0;font-family: Helvetica, &quot;Helvetica Neue&quot;, Helvetica, Arial, sans-serif;font-size: 18px;font-weight: 800;line-height: 115%;text-align: center !important;text-decoration: none;text-transform: uppercase;"><span>View Guide</span></a>
                                                </td>
                                                <td width="33%" style="width: 33%;">&nbsp;</td>
                                            </tr>
                                        </table>
                                    </td>

                                </tr>

                                <tr>
                                    <td align="center" valign="top" style="mso-table-lspace: 0pt;mso-table-rspace: 0pt;-ms-text-size-adjust: 100%;-webkit-text-size-adjust: 100%;font-family: &quot;Helvetica Neue&quot;, Helvetica, Arial, sans-serif;color: #939BBC;padding-left: 30px;padding-right: 30px;font-size: 16px;line-height: 150%;text-align: center;">grails.org<br/>
                                    </td>
                                </tr>

                            </table>
                            <!-- //END CALL-TO-ACTION BLOCK -->

                        </td>
                    </tr>
                </table>
                <!-- END EMAIL // -->
            </td>
        </tr>
    </table>
</center>
</body>
</html>