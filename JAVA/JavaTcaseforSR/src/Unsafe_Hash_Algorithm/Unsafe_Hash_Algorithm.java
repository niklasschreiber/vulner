package Unsafe_Hash_Algorithm;

import javax.servlet.http.*;

import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.logging.Logger;

public class Unsafe_Hash_Algorithm
{

	static final Logger log = Logger.getLogger("logger");
	
    public void bad(HttpServletRequest request, HttpServletResponse response)
    {
        String data = "admin:12345";

        String secretHash = "my_secret_seed";
        MessageDigest hash = null;
		try {
			hash = MessageDigest.getInstance("SHA1");  // bad 不安全的哈希算法
		} catch (NoSuchAlgorithmException e) {
			log.info("error");
		}

        /* FIX: plaintext credentials hashed with salt prior to setting in cookie */
        if(hash != null){
        	byte[] hashv = hash.digest((secretHash + data).getBytes());
            log.info(hashv + "");
        }

    }
    
    public void good(HttpServletRequest request, HttpServletResponse response)
    {
        String data = "admin:12345";

        String secretHash = "my_secret_seed";
        MessageDigest hash = null;
		try {
			hash = MessageDigest.getInstance("SHA-256"); // good 不安全的哈希算法
		} catch (NoSuchAlgorithmException e) {
			log.info("error");
		}

        /* FIX: plaintext credentials hashed with salt prior to setting in cookie */
		if(hash != null){
			byte[] hashv = hash.digest((secretHash + data).getBytes());
			log.info(hashv + "");
		}
    }
    
}

