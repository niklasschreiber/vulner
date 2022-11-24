package Unreleased_Stream;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileReader;
import java.io.IOException;
import java.util.logging.Logger;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

public class Unreleased_Stream {

	static final Logger log = Logger.getLogger("local-logger");

    public void bad(HttpServletRequest request, HttpServletResponse response)
    {
        int b = 0; /* init data */
        
        int length = 256;
        
        File f = new File("C:" + File.separator + "data.txt");
        BufferedReader buffread = null;
        
        char [] a = null;
        try {
            /* read string from file into data */
            buffread = new BufferedReader(new FileReader(f));  // bad 流资源未释放

            if(buffread.read() < length){
            	b = buffread.read(a, 0, length);
            }
            log.info(b + "");
            
        }
        catch( IOException ioe )
        {
            log.info("Error with stream reading");
        }
        catch( NumberFormatException nfe )
        {
            log.info("Error with number parsing");
        }
        
    }

    
    public void good(HttpServletRequest request, HttpServletResponse response)
    {
    	int b = 0; /* init data */
        
        int length = 256;
        
        File f = new File("C:" + File.separator + "data.txt");
        BufferedReader buffread = null;
        FileReader fread = null;
        char [] a = null;
        try {
            /* read string from file into data */
            fread = new FileReader(f);  
            buffread = new BufferedReader(fread);  // good 流资源未释放

            if(buffread.read() < length){
            	b = buffread.read(a, 0, length);
            }
            log.info(b + "");
            
        }
        catch( IOException ioe )
        {
            log.info("Error with stream reading");
        }
        catch( NumberFormatException nfe )
        {
            log.info("Error with number parsing");
        }
        finally {
            /* clean up stream reading objects */
            try {
                if( buffread != null )
                {
                    buffread.close();
                }
            }
            catch( IOException ioe )
            {
                log.info("Error closing buffread");
            }
            finally {
                try {
                    if( fread != null )
                    {
                        fread.close();
                    }
                }
                catch( IOException ioe )
                {
                	log.info("Error closing fread");
                }
            }
        }

    }


}
