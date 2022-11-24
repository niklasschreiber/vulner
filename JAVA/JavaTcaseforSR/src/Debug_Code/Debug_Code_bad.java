package Debug_Code;

import java.util.logging.Logger;

public class Debug_Code_bad {

	public Debug_Code_bad() {
		
		Logger log = Logger.getLogger("logger");
		log.info("debug code");
		
	}
	
	
	public static void main(String[] args){  // bad 遗留的调试信息
		Logger log = Logger.getLogger("logger");
		log.info("debug code");
	}
	
	
}
