package Unused_Filed;

import java.util.logging.Logger;

public class Unused_Filed {

	private String b = "test";  // bad 未使用的字段
	
	private String a = "used";  // good 未使用的字段
	
	public void good() {
		
		Logger	log = Logger.getLogger("log");
		log.info(a);
	}

}
