package Persist_XSS;

import javax.servlet.http.*;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.io.IOException;
import java.util.logging.Logger;

public class Persist_XSS
{
	public  PreparedStatement statement = null;
    public  ResultSet rs = null;
	
    static final Logger log = Logger.getLogger("local-logger");
	
	public void bad(HttpServletRequest request, HttpServletResponse response,Connection conn)
    {
    	String data = ""; /* init data */
        
		try {

			statement = conn.prepareStatement("select name from users where name = 'lily'");
			rs = statement.executeQuery();
			data = rs.getString(1);

		} catch (SQLException e1) {
			log.info("SQLException");
		}finally {
			
			try {
				rs.close();
			} catch (SQLException se) {
				log.info("Error closing conn");
			}
			
        	try {
        		statement.close();
			} catch (SQLException se) {
				log.info("Error closing conn");
			}
        	
			try {
				conn.close();
			} catch (SQLException se) {
				log.info("Error closing conn");
			}

		}
        

        if (data != null)
        {
            /* POTENTIAL FLAW: data not validated */
            try {
				response.getWriter().println("<br>bad() - Parameter name has value " + data);  // bad 存储型XSS
			} catch (IOException e) {
				log.info("IOException");
			}
        }

    }

    
    public void good(HttpServletRequest request, HttpServletResponse response) 
    {
        String data;

        /* FIX: Use a hardcoded string */
        data = "foo";
        	
        /* POTENTIAL FLAW: data not validated */
        try {
			response.getWriter().println("<br>bad() - Parameter name has value " + data);  // good 存储型XSS
		} catch (IOException e) {
			log.info("IOException");
		}
        

    }

   
}

