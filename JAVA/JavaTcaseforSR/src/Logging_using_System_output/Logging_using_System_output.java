package Logging_using_System_output;

import java.util.logging.Logger;

public class Logging_using_System_output {

	static final  Logger log = Logger.getLogger("logger");
	
	public void bad()
    {
		System.out.println("write log");  // bad  系统输出流记录日志
	}
	
	
	public void good()
    {
		log.info("write log");  // good  系统输出流记录日志
	}

}
