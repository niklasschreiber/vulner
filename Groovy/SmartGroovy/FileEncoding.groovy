// Replace the file path with the one you need.

// Getting the file content.
def inputFile = new File("C:\\Work\\MyFile.txt").getText('UTF-8')

// Encoding the file content.
String encoded = inputFile.bytes.encodeBase64().toString()

// Outputting results.
log.info encoded // with the Groovy Script test step, you can use “return encoded”