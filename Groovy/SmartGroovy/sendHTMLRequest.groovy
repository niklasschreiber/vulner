// Create a request
def get = new org.apache.http.client.methods.HttpGet( "https://smartbear.com" )

// Send the request
def response = org.apache.http.impl.client.HttpClients.createDefault().execute( get )

// Obtain the body of the response
def content = response.entity.content.text

// Save the body to a context property
context.content = content