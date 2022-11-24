package Unused_Variable;

import java.util.logging.Logger;

public class Unused_Variable
{

	static final Logger log = Logger.getLogger("logger");
    /* use badsource and badsink */
    public void bad()
    {
        Integer data;  // bad 变量赋值后未使用

        /* POTENTIAL FLAW: Initialize, but do not use data */
        data = 5;  

    }

    public void good()
    {
        Integer data;

        /* POTENTIAL FLAW: Initialize, but do not use data */
        data = 5;   // good 变量赋值后未使用

        /* FIX: Use data */
        log.info("" + data);  

    }

 
}

