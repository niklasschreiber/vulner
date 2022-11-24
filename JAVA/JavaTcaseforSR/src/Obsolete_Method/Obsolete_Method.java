package Obsolete_Method;

public class Obsolete_Method {
	
	public void test()
	{
		bad();//  bad 废弃的方法
		good();//  good 废弃的方法
	}
	
	@Deprecated
	public String bad() {
		String data;
        data = System.getenv("ADD"); 
        return data;
	}
	
	public String good() {
		String data;
        data = System.getProperty("ADD");  
        return data;
	}

}
