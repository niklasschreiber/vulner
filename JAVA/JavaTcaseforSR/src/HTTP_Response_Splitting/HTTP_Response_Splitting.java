package HTTP_Response_Splitting;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

public class HTTP_Response_Splitting {

	public void bad(HttpServletRequest request,HttpServletResponse response)
	{
		String value = request.getParameter("value");
		String UNIQUE2U ="cookie";
		
		response.setHeader("Set-Cookie", UNIQUE2U + "=" + value + "; HttpOnly"); // bad Http响应截断
			
	}
	
	public void good(HttpServletRequest request,HttpServletResponse response)
	{
		String value = "author-cookie";
		String UNIQUE2U ="cookie";
		
		response.setHeader("Set-Cookie", UNIQUE2U + "=" + value + "; HttpOnly");  // good Http响应截断
			
	}


}
