package Empty_Block;

import java.util.logging.Logger;

public class Empty_Block {

	static final Logger log = Logger.getLogger("logger");
	
	public void bad()
	{
		
		Integer a = 1;a++;
		{  // bad  空的代码块
			
		}
	}

	
	public void good()
	{   
		
		Integer a = 1;a++;
		{ // good  空的代码块
			log.info("OK");
		}
	}
	
}
