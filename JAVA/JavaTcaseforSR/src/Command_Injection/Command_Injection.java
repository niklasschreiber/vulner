package Command_Injection;
import java.io.IOException;
import java.util.logging.Logger;

public class Command_Injection
{
	static final Logger log = Logger.getLogger("local-logger");
	
    public Process bad()
    {
    	String data = System.getProperty("ADD");

        String osCommand = "c:\\WINDOWS\\SYSTEM32\\cmd.exe /c dir ";
        
        Process p = null;
		try {
			p = Runtime.getRuntime().exec(osCommand + data);  // bad  命令注入
		} catch (IOException e) {
			log.info("IOException");
		}
		return p;
    }

    
    public Process good()
    {
        String data = System.getProperty("ADD"); 

        String osCommand = "c:\\WINDOWS\\SYSTEM32\\cmd.exe /c dir ";

        data = SafeCheck(data);
        
        Process p = null;
        
        if(!data.equals("bad")){
        	 
			try {
				p = Runtime.getRuntime().exec(osCommand + data);  // good  命令注入
			} catch (IOException e) {
				log.info("IOException");
			} 
        }
        return p;

    }
    
    public String SafeCheck(String input){
    	if("good".equals(input)){
    		return "foo";
    	}else{
    		return "bad";
    	}
    }
    
}

