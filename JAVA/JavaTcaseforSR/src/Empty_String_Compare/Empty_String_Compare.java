package Empty_String_Compare;

public class Empty_String_Compare {

	public String bad(String input) {
		
		if(input.equals("")){  // bad 空字符串比较
			return "";
		}else{
			return input;
		}
		
	}

	public String good(String input) {
		
		if(input.length() == 0){  // good 空字符串比较
			return "";
		}else{
			return input;
		}
		
	}
	
}
