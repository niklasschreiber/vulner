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

void CWE390_Error_Without_Action__fgets_wchar_t_01_bad()
{
    {
        /* 
         *  */
        wchar_t dataBuffer[100] = L"";
        wchar_t * data = dataBuffer;
        printWLine(L"Please enter a string: ");
        /*  */
        if (fgetws(data, 100, stdin) == NULL)
        {
            /* do nothing */
        }
        printWLine(data);
    }
}

#endif /* OMITBAD */

#ifndef OMITGOOD

static void good1()
{
    {
        /* 
         *  */
        wchar_t dataBuffer[100] = L"";
        wchar_t * data = dataBuffer;
        printWLine(L"Please enter a string: ");
        /*  */
        if (fgetws(data, 100, stdin) == NULL)
        {
            printWLine(L"fgetws failed!");
            exit(1);
        }
        printWLine(data);
    }
}

void CWE390_Error_Without_Action__fgets_wchar_t_01_good()
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
    CWE390_Error_Without_Action__fgets_wchar_t_01_good();
    printLine("Finished good()");
#endif /* OMITGOOD */
#ifndef OMITBAD
    printLine("Calling bad()...");
    CWE390_Error_Without_Action__fgets_wchar_t_01_bad();
    printLine("Finished bad()");
#endif /* OMITBAD */
    return 0;
}

#endif
