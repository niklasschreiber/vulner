package Expression_Always_True;

import java.util.logging.Logger;

public class Expression_Always_True_02
{    
	
	static final Logger log = Logger.getLogger("local-logger");
	
    public void bad()
    {
        /* FLAW: always evaluates to true */
    	
    	
        if(1==1)  // bad 表达式永远为true
        {
        	log.info("always prints");
        }
    }
	
	
	public void good(int j)
    {
        
        boolean tag = true;
        
        if(j == 1){
        	tag = false;
        }
        
        /* FIX: may evaluate to true or false */
        if(tag) // good 表达式永远为true
        {
        	log.info("sometimes prints");
        }
    }

}
