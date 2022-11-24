// Replace the path with the one you need.
// Make sure the specified folder exists.
filePath = 'c:/work/test-results/'

// Creating output files.
fos = new FileOutputStream( filePath + testStepResult.testStep.label + '.txt', true )

// Filling output files.
pw = new PrintWriter( fos )
testStepResult.writeTo( pw )

// Closing the output.
pw.close()
fos.close()