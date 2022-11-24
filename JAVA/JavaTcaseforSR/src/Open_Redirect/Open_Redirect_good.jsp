<%@ page language="java" contentType="text/html; charset=ISO-8859-1" import="java.util.regex.*" import="org.owasp.webgoat.lessons.DangerousEval"
    pageEncoding="ISO-8859-1"%>
<%
	String[] strURLArray = new String[]{"http://aa.com","http://bb.com","http://cc.com"};
    int strDest = Integer.parseInt(request.getParameter("dest"));
    if((strDest >= 0) && (strDest <= 15 ))
    {   String strFinalURL = strURLArray[strDest];
        pageContext.forward(strFinalURL);  } %>  <%--  // good Open Redirect --%>