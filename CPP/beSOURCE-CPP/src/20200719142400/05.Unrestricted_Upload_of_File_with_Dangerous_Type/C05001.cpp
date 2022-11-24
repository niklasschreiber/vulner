#include<stdio.h>
#include<string.h>
#include<unistd.h>
#include<fcntl.h>
#include<sys/stat.h>
#include"cgic.h"
#define BufferLen 1024

int cwe434(void){
    cgiFilePtr file;
    int targetFile;
    mode_t mode;
    char name[128];
    char fileNameOnServer[64];
    char contentType[1024];
    char buffer[BufferLen];
    char *tmpStr=NULL;
    int size;
    int got,t;
    cgiHeaderContentType("text/html");
    //now retrieve the value of the "file" attribute, it should be the file path on the client machine
    if (cgiFormFileName("file", name, sizeof(name)) !=cgiFormSuccess) {
        fprintf(stderr,"could not retrieve filename\n");
        goto FAIL;
    }
    cgiFormFileSize("file", &size);
    //now get the file type which is not used in this example
    cgiFormFileContentType("file", contentType, sizeof(contentType));
    //For now, the file is uploaded to the system's temporary folder, usually "/tmp". We should open the file. Notice that the tmp file has a different name to the real file, so we could not use path "/tmp/userfilename" to get the it.
    if (cgiFormFileOpen("file", &file) != cgiFormSuccess) {
        fprintf(stderr,"could not open the file\n");
        goto FAIL;
    }
    t=-1;
    //Now we extract the real file name from the "local" file path
    while(1){
        tmpStr=strstr(name+t+1,"\\");
        if(NULL==tmpStr)
        tmpStr=strstr(name+t+1,"/");//if "\\" is not path separator, try "/"
        if(NULL!=tmpStr)
            t=(int)(tmpStr-name);
        else
            break;
    }
    strcpy(fileNameOnServer,name+t+1);
    mode=S_IRWXU|S_IRGRP|S_IROTH;
    //For simplicity, we will copy the file to the current folder (the same folder as the cgi file). So, now we will first create a new file with a call to "open". 
    targetFile = open (fileNameOnServer,O_RDWR|O_CREAT|O_TRUNC|O_APPEND,mode);
    if(targetFile<0){
        fprintf(stderr,"could not create the new file,%s\n",fileNameOnServer);
        goto FAIL;
    }
    //Read the content from the tmp file, and write it into the newly created file.
    while (cgiFormFileRead(file, buffer, BufferLen, &got) ==cgiFormSuccess){
        if(got>0)
            write(targetFile,buffer,got);
    }
    cgiFormFileClose(file);
    close(targetFile);
    goto END;
FAIL:
    fprintf(stderr,"Failed to upload");
    return 1;
END:
    printf("File \"%s\" has been uploaded",fileNameOnServer);
    return 0;
}
