package Create_String_Object;

import java.util.logging.Logger;

public class Create_String_Object {

	static final Logger log = Logger.getLogger("logger");
	
	public void bad() {
		String bl = new String("test"); // bad 创建String对象
		log.info("create " + bl);
	}
	
	public void good() {
		String bl = "test";  // good 创建String对象
		log.info("create " + bl);
	}

}
