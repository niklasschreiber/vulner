package Unchecked_Return_Value;

import java.io.File;

public class Unchecked_Return_Value {

	public String bad() {
		
		String filePath = "C:" + File.separator + "test" ;
		File f = new File(filePath);
		f.mkdir(); // bad 忽略返回值
		return "ok";
	}
	
	
	public String good() {
		
		String filePath = "C:" + File.separator + "test" ;
		File f = new File(filePath);
		boolean tag = f.mkdir(); // good 忽略返回值
		if(tag){
			return "ok";
		}else
			return "bad";
	}

}
