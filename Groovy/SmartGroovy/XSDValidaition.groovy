import javax.xml.XMLConstants
import javax.xml.transform.stream.StreamSource
import javax.xml.validation.SchemaFactory

// Specify an XSD Schema
def xsdFilePath = "C:\\temp\\Schema.xsd"

// Get the response as XML
def response = messageExchange.getResponse().contentAsXml

// Create validation objects
def factory = SchemaFactory.newInstance(XMLConstants.W3C_XML_SCHEMA_NS_URI);
def schema = factory.newSchema(new StreamSource(xsdFilePath));
def validator = schema.newValidator();

// Validate the response against the schema
assert validator.validate(new StreamSource(new StringReader(response))) == null;