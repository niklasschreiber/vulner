<%@ page language="java" contentType="text/html; charset=ISO-8859-1" import="java.util.regex.*" import="org.owasp.webgoat.lessons.DangerousEval"
    pageEncoding="ISO-8859-1"%>
<%

String strDest = request.getParameter("dest");
pageContext.forward(strDest);   %>  <%--  // good Open Redirect --%>