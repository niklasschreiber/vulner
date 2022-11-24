<html>
    <head>
        <asset:stylesheet src="home.css"/>
        <title><g:message code="home.title" default="Grails 101"/></title>
        <style type="text/css">
        </style>
    </head>
    <body>
        <div id="content" role="main">

            <h1>Grails 101</h1>

            <g:form controller="subscribe" action="subscribe" method="POST">
                <label><g:message code="onezeroone.email" default="Email"/></label>
                <g:textField name="email"/>

                <input type="submit" value="${g.message(code: 'onezeroone.joinCourse', default: 'Join Course')}"/>
            </g:form>
            <g:each in="${flash.error}">
                <b><br/>${it}</b>
            </g:each>
        </div>
    </body>
</html>
