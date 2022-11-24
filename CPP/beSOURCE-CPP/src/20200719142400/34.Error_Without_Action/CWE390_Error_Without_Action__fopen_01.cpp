/* 



*/
/*
 * 
 * 
 * 
 * 
 * 
 * 
 *
 * */

#include "std_testcase.h"

#ifndef OMITBAD

void CWE390_Error_Without_Action__fopen_01_bad()
{
    {
        FILE * fileDesc = NULL;
        fileDesc = fopen("file.txt", "w+");
        /*  */
        if (fileDesc == NULL)
        {
            /* do nothing */
        }
        fclose(fileDesc);
    }
}

#endif /* OMITBAD */

#ifndef OMITGOOD

static void good1()
{
    {
        FILE * fileDesc = NULL;
        fileDesc = fopen("file.txt", "w+");
        /*  */
        if (fileDesc == NULL)
        {
            printLine("fopen() failed");
            exit(1);
        }
        fclose(fileDesc);
    }
}

void CWE390_Error_Without_Action__fopen_01_good()
{
    good1();
}

#endif /* OMITGOOD */

/* 
   
   
    */

#ifdef INCLUDEMAIN

int main(int argc, char * argv[])
{
    /*  */
    srand( (unsigned)time(NULL) );
#ifndef OMITGOOD
    printLine("Calling good()...");
    CWE390_Error_Without_Action__fopen_01_good();
    printLine("Finished good()");
#endif /* OMITGOOD */
#ifndef OMITBAD
    printLine("Calling bad()...");
    CWE390_Error_Without_Action__fopen_01_bad();
    printLine("Finished bad()");
#endif /* OMITBAD */
    return 0;
}

#endif
