if( request.response == null )
return

// Getting the response content.
def content = context.httpResponse.responseContent

// Modifying the content – replacing all 555 with 444.
content = content.replaceAll( "555", "444" )

// Overriding the response.
context.httpResponse.responseContent = content