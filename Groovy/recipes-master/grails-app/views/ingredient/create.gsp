<%@ page import="com.recipes.Ingredient" %>  
<html>
    <head>
         <meta http-equiv="Content-Type" content="text/html; charset=UTF-8"/>
         <meta name="layout" content="main" />
         <title>Create Ingredient</title>         
    </head>
    <body>
        <div class="nav">
            <span class="menuButton"><a href="${createLinkTo(dir:'')}">Home</a></span>
            <span class="menuButton"><g:link action="list">Ingredient List</g:link></span>
        </div>
        <div class="body">
           <h1>Create Ingredient</h1>
           <g:if test="${flash.message}">
                 <div class="message">${flash.message}</div>
           </g:if>
           <g:hasErrors bean="${ingredient}">
                <div class="errors">
                    <g:renderErrors bean="${ingredient}" as="list" />
                </div>
           </g:hasErrors>
           <g:form action="save" method="post" >
               <div class="dialog">
                <table>
                    <tbody>

                       
                       
                                  <tr class='prop'><td valign='top' class='name'><label for='name'>Name:</label></td><td valign='top' class='value ${hasErrors(bean:ingredient,field:'name','errors')}'><input type='text' name='name' value="${ingredient?.name?.encodeAsHTML()}" /></td></tr>
                       
                                  <tr class='prop'><td valign='top' class='name'><label for='quantity'>Quantity:</label></td><td valign='top' class='value ${hasErrors(bean:ingredient,field:'quantity','errors')}'><input type='text' name='quantity' value="${ingredient?.quantity}"></input></td></tr>
                       
                                  <tr class='prop'><td valign='top' class='name'><label for='recipe'>Recipe:</label></td><td valign='top' class='value ${hasErrors(bean:ingredient,field:'recipe','errors')}'><g:select optionKey="id" from="${com.recipes.Recipe.list()}" name='recipe.id' value="${ingredient?.recipe?.id}"></g:select></td></tr>
                       
                    </tbody>
               </table>
               </div>
               <div class="buttons">
                     <span class="formButton">
                        <input type="submit" value="Create"></input>
                     </span>
               </div>
            </g:form>
        </div>
    </body>
</html>
