package nfec.core.baseclasses.cache;

import java.io.ByteArrayOutputStream;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.util.Collections;
import java.util.HashMap;
import java.util.Map;

public class ResourceDispatcher {
	
	private static final Map<String, byte[]> _hmCache = Collections.synchronizedMap(new HashMap<String, byte[]>());	
	

	private static void addIfAbsent(String key, byte[] value)
	{
		synchronized (_hmCache) {
			if(!_hmCache.containsKey(key))
				_hmCache.put(key, value);
		}		
	}	
	
	public static byte[] readResource(String filePath)
	{	
		byte[] b = null;
		
		if(_hmCache.containsKey(filePath))
		{
			b = _hmCache.get(filePath);
		}			
		else
		{
			InputStream is = null;
			try {
				
				//RandomAccessFile f = new RandomAccessFile("resources/cerved_esempio.pdf", "r");
				is = new FileInputStream(filePath);										
				ByteArrayOutputStream out = new ByteArrayOutputStream();
		
			    byte [] aoBuffer = new byte [512];
			    int nBytesRead;	    
					while ( (nBytesRead = is.read (aoBuffer)) > 0 ) {
					    out.write (aoBuffer, 0, nBytesRead);
					}		
			    b = out.toByteArray();
			    addIfAbsent(filePath, b);	
			    
		    } catch (IOException e) {
		    	throw new RuntimeException("Errore nella lettura del file: " + filePath, e);
			}
			finally
			{
				if(is != null)
					try {
						is.close();
					} catch (IOException e) {
						throw new RuntimeException("Errore nella close", e);
					}
			}	    
		}
		return b;
	}
}
