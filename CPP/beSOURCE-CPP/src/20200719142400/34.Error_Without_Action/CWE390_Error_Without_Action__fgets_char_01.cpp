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

void CWE390_Error_Without_Action__fgets_char_01_bad()
{
    {
        /* 
          */
        char dataBuffer[100] = "";
        char * data = dataBuffer;
        printLine("Please enter a string: ");
        /*  */
        if (fgets(data, 100, stdin) == NULL)
        {
            /* do nothing */
        }
        printLine(data);
    }
}

#endif /* OMITBAD */

#ifndef OMITGOOD

static void good1()
{
    {
        /* 
         *  */
        char dataBuffer[100] = "";
        char * data = dataBuffer;
        printLine("Please enter a string: ");
        /*  */
        if (fgets(data, 100, stdin) == NULL)
        {
            printLine("fgets failed!");
            exit(1);
        }
        printLine(data);
    }
}

void CWE390_Error_Without_Action__fgets_char_01_good()
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
    CWE390_Error_Without_Action__fgets_char_01_good();
    printLine("Finished good()");
#endif /* OMITGOOD */
#ifndef OMITBAD
    printLine("Calling bad()...");
    CWE390_Error_Without_Action__fgets_char_01_bad();
    printLine("Finished bad()");
#endif /* OMITBAD */
    return 0;
}

#endif
