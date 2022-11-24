package String_Compare_Error;

public class String_Compare_Error {

	public String bad(String input) {

		if (input != "test") { // bad 字符串比较错误
			return "not empty";
		} 
		return "bad";

	}

	public String good(String input) {

		if (input.equals("test")) { // good 字符串比较错误
			return "not empty";
		} else{
			return "good";
		}

	}

}
