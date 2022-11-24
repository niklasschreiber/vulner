package SQL_Injection;

import java.sql.*;
import javax.servlet.http.*;
import java.util.logging.Logger;


public class SQL_Injection
{

	static final Logger log = Logger.getLogger("local-logger");
	
    public void bad(HttpServletRequest request, HttpServletResponse response,Connection conn)
    {

        Connection conn_tmp2 = null;
        Statement sqlstatement = null;

        String data = System.getProperty("sql-input");
        try {
            conn_tmp2 = conn;
            sqlstatement = conn_tmp2.createStatement();

            /* POTENTIAL FLAW: value of "name" taken directly from an untrusted source and inserted into a command string executed against a SQL interpreter */
            Boolean bResult = sqlstatement.execute("insert into users (status) values ('updated') where name='" + data + "'");  // bad SQL注入

            if( bResult )
            {
            	log.info("updated successfully");
            }
            else
            {
                log.info("Unable to update records");
            }
        }
        catch( SQLException se )
        {
            log.info("Error getting database connection");
        }
        finally {
            try {
                if( sqlstatement != null )
                {
                    sqlstatement.close();
                }
            }
            catch( SQLException e )
            {
                log.info("Error closing sqlstatement");
            }
            finally {
                try {
                    if( conn_tmp2 != null )
                    {
                        conn_tmp2.close();
                    }
                }
                catch( SQLException e )
                {
                    log.info("Error closing conn_tmp2");
                }
            }
        }

    }

    public void good(HttpServletRequest request, HttpServletResponse response,Connection conn)
    {
        String data;

        /* FIX: Use a hardcoded string */
        data = "foo";

        Connection conn_tmp2 = null;
        Statement sqlstatement = null;

        try {
        	
            conn_tmp2 = conn;
            
            sqlstatement = conn_tmp2.createStatement();

            Boolean bResult = sqlstatement.execute("insert into users (status) values ('updated') where name='"+data+"'");  // good SQL注入

            if( bResult )
            {
                log.info("updated successfully");
            }
            else
            {
            	log.info("Unable to update records");
            }
        }
        catch( SQLException se )
        {
            log.info("Error getting database connection");
        }
        finally {
            try {
                if( sqlstatement != null )
                {
                    sqlstatement.close();
                }
            }
            catch( SQLException e )
            {
                log.info("Error closing sqlstatement");
            }
            finally {
                try {
                    if( conn_tmp2 != null )
                    {
                        conn_tmp2.close();
                    }
                }
                catch( SQLException e )
                {
                    log.info("Error closing conn_tmp2");
                }
            }
        }

    }
    
}

