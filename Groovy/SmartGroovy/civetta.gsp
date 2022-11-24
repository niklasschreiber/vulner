<html>
   <body>
	<g:if test="${session.role == 'admin'}">
		<%-- show administrative functions --%>
	</g:if>
	<g:else>
		<%-- show basic functions --%>
	</g:else>
     <% if (params.hello == 'true')%>
      <%= Hello ${params.name} %>
      <% else %>
      <%="Goodbye!"%>
	 <g:message code="foo.bar" encodeAs="JavaScript" /> 
	 <g:encodeAs codec="Raw">${content}</g:encodeAs> 
	 <g:encodeAs codec="javascript">${content}</g:encodeAs> 
   </body>
</html>