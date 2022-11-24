package Create_Boolean_Object;

import java.util.logging.Logger;

public class Create_Boolean_Object {

	static final Logger log = Logger.getLogger("logger");
	
	public void bad() {
		boolean bl = new Boolean(true); // bad 创建Boolean对象
		log.info("create " + bl);
	}
	
	public void good() {
		boolean bl = Boolean.TRUE;  // good 创建Boolean对象
		log.info("create " + bl);
	}

}
