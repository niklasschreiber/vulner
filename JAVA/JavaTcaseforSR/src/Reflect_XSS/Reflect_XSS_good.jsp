<%@ page language="java" contentType="text/html; charset=ISO-8859-1" import="java.util.regex.*" import="org.owasp.webgoat.lessons.DangerousEval"
    pageEncoding="ISO-8859-1"%>
<%
String action = request.getParameter("action");
String field1 = "field1";
String regex1 = "^[0-9]{3}$";// any three digits
Pattern pattern1 = Pattern.compile(regex1);

if("Purchase".equals(action))
{
	if(!pattern1.matcher(field1).matches())
	{
	
		/** If they supplied the right attack, pass them **/
		out.write("alert('Whoops: You entered an incorrect access code of \"" + field1 + "\"');");  // good  xss
	
	}
	
}
%>