//start
//**********************************************************
*******
//Name: hostid
//Date: 08/27/99
//Originator: Mike McGahan
//Compile: c++ hostid.cc -o hostid
//
//  hostid usage
//         - get current hostid
//      -g - get current hostid
//      -r - restore hostid from /etc/hostid file
//      -s <hexid> - set hostid
//             If the file /etc/hostid does not exist it is
created
//
//**********************************************************
********

#include <iostream>
#include <fstream>
#include <stdio.h>
#include <unistd.h>
#include <errno.h>
#include <string.h>

long HostIdFromFile(void);
int HostIdToFile(void);
void Usage(void);

int main (int argc, char* argv[]) {
  bool invalid = false;
  long hostid = -1;
  if (argc == 1) {
    cout << "hostid: " << hex << gethostid() << endl;
  }
  else if (argc == 2) {
    if (argv[1][0] == '-') {

      if (argv[1][1] == 'g') {    // get current hostid
	cout << "hostid: " << hex << gethostid()  << endl;
      }

      else if (argv[1][1] == 'r') {    // restore hostid
	hostid = HostIdFromFile();  // hostid is untrusted
	if ( hostid != -1) {    // got hostid 
	  int status = 0;
	  if ((status = sethostid (hostid)) == 0) {   // CWE 15
	    cout << "Hostid \" " << hex << hostid << "\"
restored." << endl;
	  }
	  else {
	    cout << "Failed to set hostid, " << hex <<
hostid << dec << ". Status:" << status << endl;
	    cout << "Error: " << strerror(errno) << endl;
	    exit (-1);
	  }
	}
	else {
	  cout << "Failed to open /etc/hostid file." <<
endl;
	  exit (-1);
	}
      }
      else if (argv[1][1] == 'h') {    // help hostid
	Usage();
      }
      else {
	invalid = true;
      }
    }
    else {
      invalid = true;

    }
  }
  else if (argc == 3) {
    if (argv[1][0] == '-') {

      if (argv[1][1] == 's') {      // set hostid
	int status = 0;
	sscanf(argv[2], "%lX", &hostid);
	if (HostIdFromFile() == -1) {    // hostid file
does not exist
	  if (HostIdToFile() == -1) {
	    cout << "Could not create /etc/hostid file." <<
endl;
	    exit (-1);
	  }
	}
	if ((status = sethostid (hostid)) == 0) {  // CWE 15
	  cout << "Hostid \"" << hex << hostid << "\" set."
<< endl;
	}
	else {
	  cout << "Failed to set hostid, " << hex << hostid
<< dec << ". Status:" << status << endl;
	  cout << "Error: " << strerror(errno) << endl;
	  exit (-1);
	}
      }
      else {
	invalid = true;
      }
    }
    else {
      invalid = true;
    }
  }
  else {
    invalid = true;
  }

  if (invalid) {
    cout << "Invalid option or number of parameters." <<
endl;
    Usage();
  }
}

long HostIdFromFile(void) {
  long hostid = -1;
  std::ifstream hostidfile ("/etc/hostid");
  if (!hostidfile.is_open()) {
    return -1;
  }
  hostidfile >> hex >> hostid;
  hostidfile.close();
  return hostid;
}

int HostIdToFile(void) {
  std::ofstream hostidfile ("/etc/hostid");
  if (!hostidfile) {
    cout << "Failed to open /etc/hostid." << endl;
    return -1;
  }
  hostidfile << hex << gethostid();
  hostidfile.close();
  return 1;
}

void Usage (void) {
  cout << "gethostid usage" << endl;
  cout << "    -g - get current hostid" << endl;
  cout << "    -r - restore hostid from /etc/hostid file"
<< endl;
  cout << "    -s \"numericid\" - set hostid" << endl;
  cout << "           If the file /etc/hostid does not
exist it is created" << endl << endl;
}

//end