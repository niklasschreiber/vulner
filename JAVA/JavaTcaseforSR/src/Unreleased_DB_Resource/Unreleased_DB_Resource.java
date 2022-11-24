package Unreleased_DB_Resource;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.logging.Logger;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

public class Unreleased_DB_Resource {

    static final Logger log = Logger.getLogger("local-logger");
    
	public void bad(HttpServletRequest request, HttpServletResponse response,Connection conn)
    {
        PreparedStatement statement = null;
        ResultSet rs = null;
        
		try {
			statement = conn.prepareStatement("select name from users where name = 'lily'");  // bad  数据库资源未释放
			rs = statement.executeQuery();
			rs.next();
		} catch (SQLException e1) {
			log.info("SQLException");
		}

    }

    
	
	public void good(HttpServletRequest request, HttpServletResponse response,Connection conn)
    {
    	
        PreparedStatement statement = null;
        ResultSet rs = null;
        
		try {

			statement = conn.prepareStatement("select name from users where name = 'lily'");  // good  数据库资源未释放
			rs = statement.executeQuery();
			
		} catch (SQLException e1) {
			log.info("SQLException");
		}finally {
			
			try {
				if( rs != null )
                {
					rs.close();
				}
			} catch (SQLException se) {
				log.info("Error closing conn");
			}
			
        	try {
        		if( statement != null )
                {
        			statement.close();
				}
			} catch (SQLException se) {
				log.info("Error closing conn");
			}
        	
			try {
				if( conn != null )
                {
					conn.close();
                }
			} catch (SQLException se) {
				log.info("Error closing conn");
			}

		}

    }

   

}
