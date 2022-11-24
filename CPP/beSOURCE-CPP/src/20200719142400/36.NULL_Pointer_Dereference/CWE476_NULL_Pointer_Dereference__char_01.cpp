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
 * 
 *
 * */

#include "std_testcase.h"

#include <wchar.h>

#ifndef OMITBAD

void CWE476_NULL_Pointer_Dereference__char_01_bad()
{
    char * data;
    /*  */
    data = NULL;
    /*  */
    /*  */
    printHexCharLine(data[0]);
}

#endif /* OMITBAD */

#ifndef OMITGOOD

/*  */
static void goodG2B()
{
    char * data;
    /*  */
    data = "Good";
    /*  */
    /*  */
    printHexCharLine(data[0]);
}

/* */
static void goodB2G()
{
    char * data;
    /*  */
    data = NULL;
    /*  */
    if (data != NULL)
    {
        /*  */
        printHexCharLine(data[0]);
    }
    else
    {
        printLine("data is NULL");
    }
}

void CWE476_NULL_Pointer_Dereference__char_01_good()
{
    goodG2B();
    goodB2G();
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
    CWE476_NULL_Pointer_Dereference__char_01_good();
    printLine("Finished good()");
#endif /* OMITGOOD */
#ifndef OMITBAD
    printLine("Calling bad()...");
    CWE476_NULL_Pointer_Dereference__char_01_bad();
    printLine("Finished bad()");
#endif /* OMITBAD */
    return 0;
}

#endif
