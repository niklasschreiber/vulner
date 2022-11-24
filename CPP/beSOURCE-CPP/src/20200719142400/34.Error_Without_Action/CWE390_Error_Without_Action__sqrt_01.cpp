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

#include <math.h>
#include <errno.h>

#ifndef OMITBAD

void CWE390_Error_Without_Action__sqrt_01_bad()
{
    {
        double doubleNumber;
        errno = 0; /*  */
        doubleNumber = (double)sqrt((double)-1);
        /* */
        if (errno == EDOM)
        {
            /* do nothing */
        }
        printDoubleLine(doubleNumber);
    }
}

#endif /* OMITBAD */

#ifndef OMITGOOD

static void good1()
{
    {
        double doubleNumber;
        errno = 0; 
        doubleNumber = (double)sqrt((double)-1);
        /*  */
        if (errno == EDOM)
        {
            printLine("sqrt() failed");
            exit(1);
        }
        printDoubleLine(doubleNumber);
    }
}

void CWE390_Error_Without_Action__sqrt_01_good()
{
    good1();
}

#endif /* OMITGOOD */

/* 
   
   
    */

#ifdef INCLUDEMAIN

int main(int argc, char * argv[])
{
    /* seed randomness */
    srand( (unsigned)time(NULL) );
#ifndef OMITGOOD
    printLine("Calling good()...");
    CWE390_Error_Without_Action__sqrt_01_good();
    printLine("Finished good()");
#endif /* OMITGOOD */
#ifndef OMITBAD
    printLine("Calling bad()...");
    CWE390_Error_Without_Action__sqrt_01_bad();
    printLine("Finished bad()");
#endif /* OMITBAD */
    return 0;
}

#endif
