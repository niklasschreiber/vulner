package Weak_Encryption;

import java.io.UnsupportedEncodingException;
import java.security.InvalidKeyException;
import java.security.NoSuchAlgorithmException;
import java.security.NoSuchProviderException;
import java.util.logging.Logger;

import javax.crypto.BadPaddingException;
import javax.crypto.Cipher;
import javax.crypto.IllegalBlockSizeException;
import javax.crypto.NoSuchPaddingException;
import javax.crypto.spec.SecretKeySpec;

public class Weak_Encryption {

	static final Logger  log = Logger.getLogger("local-logger");
	
	public String bad(SecretKeySpec key) throws UnsupportedEncodingException 
    {
        String data = "root"; /* init data */
        
		//String sKey = "sKey";
		Cipher cipher = null;
		try {
			//SecretKeySpec key = new SecretKeySpec(sKey.getBytes(), "DES");
			cipher = Cipher.getInstance("DES/CBC/PKCS5Padding");  // bad  弱加密
			cipher.init(Cipher.DECRYPT_MODE, key);
		} catch (NoSuchAlgorithmException | NoSuchPaddingException e) {
			log.info("error");
		} catch (InvalidKeyException e) {
			log.info("InvalidKeyException");
		}
		
		String pw = "";
		try {
			if(cipher != null){
				pw = new String(cipher.doFinal(data.getBytes()),"UTF-8");
			}
		} catch (IllegalBlockSizeException e) {
			log.info("error");
		} catch (BadPaddingException e) {
			log.info("error");
		}

		String cipertext = pw;	
		return cipertext;
			      
    }
	
	
	public String good(String sKey) throws UnsupportedEncodingException, NoSuchProviderException
    {
        String data = "root"; /* init data */
        
		//String sKey = "sKey";
		Cipher cipher = null;
		try {
			SecretKeySpec key = new SecretKeySpec(sKey.getBytes(), "AES");
			cipher = Cipher.getInstance("AES/CBC/PKCS7Padding","CBC");  // good  弱加密
			cipher.init(Cipher.DECRYPT_MODE, key);
		} catch (NoSuchAlgorithmException | NoSuchPaddingException e) {
			log.info("error");
		} catch (InvalidKeyException e) {
			log.info("InvalidKeyException");
		}
		
		String pw = "";
		try {
			if(cipher != null){
				pw = new String(cipher.doFinal(data.getBytes()),"UTF-8");
			}
		} catch (IllegalBlockSizeException e) {
			log.info("error");
		} catch (BadPaddingException e) {
			log.info("error");
		}

		String cipertext = pw;  	
		return cipertext;		
           
    }

}
