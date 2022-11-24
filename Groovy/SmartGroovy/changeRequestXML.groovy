// Create groovyUtils and XmlHolder for the request of the Sample Request test step.
def groovyUtils = new com.eviware.soapui.support.GroovyUtils( context )
def holder = groovyUtils.getXmlHolder( 'Test Request - login#Request' )

// Change the node values in the imported XML.
holder["//username"] = "3216431654"
holder["//password"] = "Loginn1123"

// Update the request and write the updated request back to the test step.
holder.updateProperty()
context.requestContent = holder.xml