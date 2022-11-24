package Empty_Password;

public class Empty_Password {

	public String bad(){
		String password = "";   // bad  空密码
		return password;
	}

	public String good(String user,String pass){
		
		if(pass.length()!=0){
			String password = pass; // good  空密码
			return password;
		}else
		return "";
	}

}