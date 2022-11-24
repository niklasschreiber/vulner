package Unused_Method;

public class Unused_Method 
{
	
	private String bad()  // bad  未使用的方法
	{
		return "Calculation";
	}

	/* FIX: good() method calls calculation() */
	private String calculation()  // good 未使用的方法
	{
		return "Calculation";
	}
	
	public void good()
    {
		calculation();
	}
	
}
