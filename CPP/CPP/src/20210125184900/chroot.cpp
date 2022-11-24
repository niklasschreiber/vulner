#include <iostream>
#include <string>

using namespace std;

#include <cstdio>
#include <cstdlib>
#include <cerrno>
#include <cstring>

#include <unistd.h>
#include <fcntl.h>
#include <dirent.h>
#include <sys/types.h>
#include <sys/stat.h>


int main(int argc, char *argv[])
{
    if (argc < 4)
    {
        cerr << "USAGE: " << argv[0] << " <jail directory> <freeworld directory> <filename>\n";
        exit(EXIT_FAILURE);
    }

    const string JAILDIR(argv[1]);
    const string FREEDIR(argv[2]);
    string freefilename(argv[3]);

    while (freefilename[0] == '/')
        freefilename.erase(0, 1);

    DIR *pDir;

    if ((pDir = opendir(FREEDIR.c_str())) == NULL)
    {
        perror("Could not open outside dir");
        exit(EXIT_FAILURE);
    } 

    int freeFD = dirfd(pDir);
    
    // cd to default dir
    chdir("/usr/tmp");   // CWE 243
    
    //cd to jail dir
    if (chdir(JAILDIR.c_str()) == -1)
    {
        perror("cd before chroot");
        exit(EXIT_FAILURE);
    }

    //lock in jail
    if (chroot(JAILDIR.c_str()) < 0)
    {
        cerr << "Failed to chroot to " << JAILDIR << " - " << strerror(errno) << endl;
        exit(EXIT_FAILURE);
    }

    //
    //in jail, won't work
    //

    string JailFile(FREEDIR);
    JailFile += "/";
    JailFile += freefilename;

    int jailFD;

    if ((jailFD = open(JailFile.c_str(), O_RDONLY)) == -1)
    {
        cout << "as expected, could not open " << JailFile << endl;
        perror("exected open fail");
    }
    else
    {
        cout << "defying all logic, opened " << JailFile << endl;
        exit(EXIT_FAILURE);
    }

    //
    //using this works
    //

    if ((jailFD = openat(freeFD, freefilename.c_str(), O_RDONLY)) == -1)
    {
        cout << "example did not work. Could not open " << freefilename << " Sorry!" << endl;
        exit(EXIT_FAILURE);
    }
    else
        cout << "opened " << freefilename << " from inside jail" << endl;

    char     buff[255];
    ssize_t  numread;

    while (1)
    {
        if ((numread = read(jailFD, buff, sizeof(buff) - 1)) == -1)
        {
            perror("read");
            exit(EXIT_FAILURE);
        }

        if (numread == 0)
            break;

        buff[numread] = '\0';
        cout << buff << endl;
    }

    return 0;
}