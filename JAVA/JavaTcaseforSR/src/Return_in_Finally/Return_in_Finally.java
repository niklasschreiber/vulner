package Return_in_Finally;

import java.util.logging.Logger;

public class Return_in_Finally
{

	static final Logger log = Logger.getLogger("logger");
	
    public void bad()
    {
    	
        try
        {
            throw new IllegalArgumentException();
        }
        catch(IllegalArgumentException iae)
        {
        	log.info("preventing incidental issues");
        }
        finally
        {
            return; // bad  finally块中的return语句
            /* INCIDENTAL: 571 Always returns true */
            /* We need the "if(true)" above because the Java Language Spec requires that unreachable code generate a compiler error */
        }

    }

    public void good() 
    {

        try
        {
            throw new IllegalArgumentException();
        }
        catch(IllegalArgumentException iae)
        {
        	log.info("preventing incidental issues");
        }
        finally
        {
            /* FIX: cleanup code here and continue */
        	log.info("In finally block, cleaning up"); // good  finally块中的return语句
        }

    }
    
}

