<%@ page contentType="text/html;charset=UTF-8" %>
<html>
<head>
    <title>Add Wiki Page</title>
    <meta name="layout" content="admin"/>
</head>

<body>

<g:uploadForm action="save" class="form-horizontal">
    <fieldset>

        <g:render template="form" />

        <div class="form-group"><div class="col-sm-offset-2 col-sm-10">
            <g:submitButton name="create" class="btn btn-primary" value="Create" />
            <g:link class="btn" action="list">Cancel</g:link>
        </div></div>

    </fieldset>

</g:uploadForm>

</body>
</html>