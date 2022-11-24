package Unsafe_Reflection;

import java.util.logging.Logger;

public class Unsafe_Reflection
{
	 
	static final Logger log = Logger.getLogger("local-logger");
	
    public void bad()
    {
        String data = System.getProperty("ADD");

        if(data != null){
        	Class<?> c = null;
    		try {
    			c = Class.forName(data);  // bad 不安全的反射
    		} catch (ClassNotFoundException e) {
    			log.info("error");
    		} /* FLAW: loading arbitrary class */
            Object instance = null;
    		try {
    			if(c != null){
    				instance = c.newInstance();
    				log.info(instance.toString());
    			}	
    		} catch (InstantiationException e) {
    			log.info("error");
    		} catch (IllegalAccessException e) {
    			log.info("error");
    		}
        }
    }


    public void good()
    {
        String data = "testdata";
        Class<?> c = null;
		try {
			c = Class.forName(data);  // good 不安全的反射
		} catch (ClassNotFoundException e) {
			log.info("error");
		}
        Object instance = null;
		try {
			if(c != null){
				instance = c.newInstance();
				log.info(instance.toString());
			}
		} catch (InstantiationException e) {
			log.info("error");
		} catch (IllegalAccessException e) {
			log.info("error");
		}

    }
    
}

