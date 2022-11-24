package Expression_Always_False;

import java.util.logging.Logger;

public class Expression_Always_False_01
{    
	static final Logger log = Logger.getLogger("local-logger");
	
    public void bad()
    {
    	
        /* FLAW: always evaluates to false */
    	boolean tag = false;
        if(tag)    // bad  表达式永远为false
        {
        	log.info("never prints");
        }
    }
	
	public void good(int j)
    {
		boolean tag = false;
        
        if(j == 1){
        	tag = true;
        }
        
        /* FIX: may evaluate to true or false */
        if(tag)  // good 表达式永远为false
        {
        	log.info("sometimes prints");
        }
    }

}
