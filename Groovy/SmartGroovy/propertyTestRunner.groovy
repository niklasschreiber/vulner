// Get property from a test case
def testCaseProperty = testRunner.testCase.getPropertyValue( "MyProp" )

// Get property from a test suite
def testSuiteProperty = testRunner.testCase.testSuite.getPropertyValue( "MyProp" )

// Get a project property
def projectProperty = testRunner.testCase.testSuite.project.getPropertyValue( "MyProp" )

// Get a global property
def globalProperty = com.eviware.soapui.SoapUI.globalProperties.getPropertyValue( "MyProp" )

// In Script Assertions, you access test cases in a different way:
// def testCaseProperty = messageExchange.modelItem.testStep.testCase.getPropertyValue( "MyProp" )

// Set values to the same properties.
testRunner.testCase.setPropertyValue( "MyProp", 'someValue' )
testRunner.testCase.testSuite.setPropertyValue( "MyProp", 'someValue' )
testRunner.testCase.testSuite.project.setPropertyValue( "MyProp", 'someValue' )
com.eviware.soapui.SoapUI.globalProperties.setPropertyValue( "MyProp", 'someValue' )

// Set names for the test case, test suite, and project.
testRunner.testCase.name = 'Sample Test Case Name'
testRunner.testCase.testSuite.name = 'Sample Test Suite Name'
testRunner.testCase.testSuite.project.name = 'Sample Project Name'