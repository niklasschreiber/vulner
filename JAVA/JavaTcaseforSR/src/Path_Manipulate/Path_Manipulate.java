package Path_Manipulate;

import java.io.File;

public class Path_Manipulate {

	public boolean bad(){
		
		 String path = System.getProperty("dir");
		 File f = new File(path);  // bad 路径遍历
		 boolean result = f.delete();
		 return result;
	}
	
	
	public boolean good(){
		
		String path = "C:" + File.separator + "test.txt";
		File f = new File(path);  // good 路径遍历
		boolean result = f.delete();
		return result;
	}
	

}
