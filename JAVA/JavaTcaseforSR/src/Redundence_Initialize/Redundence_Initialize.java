package Redundence_Initialize;

import java.util.logging.Logger;

public class Redundence_Initialize {

	static final Logger log = Logger.getLogger("log");
	
	public void bad() {
		
		String a = ""; // bad 冗余的初始化
		a = "test";
		log.info(a);
	}

	public static String getString(){
		return "redundence_initialize";
	}
	
	
	public void good() {
		
		String a = "123"; // good 冗余的初始化
		log.info(a);
	}
	
}
