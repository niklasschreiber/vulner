// Create the groovyUtils and XmlHolder objects to hold the response XML.
def groovyUtils = new com.eviware.soapui.support.GroovyUtils( context )
def holder = groovyUtils.getXmlHolder( 'Test Request - login#Response' )

// Loop item nodes in the response message.
for( item in holder.getNodeValues( "//faultcode" ))
    log.info "Item : [$item]"
    
// If the desired content is namespace qualified, you need to define the namespace first.
// Define the namespace
holder.namespaces['ns'] = 'http://www.soapui.org/sample/'

// Loop item nodes in the response message.
for( item in holder.getNodeValues( "//ns:loginFault" ))
    log.info "Item : [$item]"