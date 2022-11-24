package Static_Field_Not_Final;


public class Static_Field_Not_Final
{
	/* FLAW: public static fields should be marked final */
	public static String defaultError = "The value you entered was not understood.  Please try again.";  // bad 非final的public static字段
	
	public static final String defaultRight = "GOOD";  // good 非final的public static字段
	
}
