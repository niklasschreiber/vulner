package J2EE_Bad_Practices_Use_of_System_Exit;

import javax.servlet.http.*;

import java.io.IOException;
import java.util.logging.Logger;

public class J2EE_Bad_Practices_Use_of_System_Exit__Servlet_01
{

	static final Logger log = Logger.getLogger("logger");
	
    public void bad(HttpServletRequest request, HttpServletResponse response) 
    {

        System.exit(1); // bad JAVA EE不良的实现：调用System.exit()或Runtime.exit()关闭应用程序容器

    }


    public void good(HttpServletRequest request, HttpServletResponse response)
    {

        try {
			response.getWriter().write("You cannot shut down this application, only the admin can");
		} catch (IOException e) {
			log.info("error");
		}  // good JAVA EE不良的实现：调用System.exit()或Runtime.exit()关闭应用程序容器

    }

   
}

