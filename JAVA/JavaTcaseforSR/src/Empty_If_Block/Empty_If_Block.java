package Empty_If_Block;

public class Empty_If_Block {
	
	public String bad(String input) {

		if (input.length() == 0) { // bad 空的if代码块
			
		} 
		return "";

	}

	public String good(String input) {

		if (input.length() == 0) { // good 空的if代码块
			return "";
		} else{
			return input;
		}

	}
}
