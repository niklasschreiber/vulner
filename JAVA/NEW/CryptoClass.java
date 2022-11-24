package it.poste.onebooking.utils;

import java.io.IOException;
import java.io.UnsupportedEncodingException;
import java.security.AlgorithmParameters;
import java.security.GeneralSecurityException;
import java.security.MessageDigest;

import javax.crypto.Cipher;
import javax.crypto.SecretKey;
import javax.crypto.SecretKeyFactory;
import javax.crypto.spec.IvParameterSpec;
import javax.crypto.spec.PBEKeySpec;
import javax.crypto.spec.SecretKeySpec;
import javax.xml.bind.DatatypeConverter;

import org.apache.commons.codec.binary.Base64;

public class CryptoClass {
	
	private CryptoClass() {
		
	}


	private static final String p = "py#c=$pLaL3E2[sq";
	private static final byte[] salt = new String("(vD{'4gQv;Yfry3m").getBytes();
	//private static final int iterationCount = 4000; 
	private static final int keyLength = 128;
	
	//SHA3-512
    final private  static char[] hexArray = "0123456789ABCDEF".toCharArray();
    static MessageDigest md = null;
	////
    
	public static SecretKeySpec createSecretKey(char[] password, byte[] salt, int iterationCount, int keyLength) throws Exception {		
        SecretKeyFactory keyFactory = SecretKeyFactory.getInstance("PBKDF2WithHmacSHA1");
		PBEKeySpec keySpec = new PBEKeySpec(password, salt, iterationCount, keyLength);
		SecretKey keyTmp = keyFactory.generateSecret(keySpec);
		return new SecretKeySpec(keyTmp.getEncoded(), "AES");
	}
	 
    public static String encrypt(String value, int iterationCount) throws GeneralSecurityException, UnsupportedEncodingException , Exception {

    	SecretKeySpec key = createSecretKey(p.toCharArray(), salt, iterationCount, keyLength);
        Cipher pbeCipher = Cipher.getInstance("AES/CBC/PKCS5Padding");
        pbeCipher.init(Cipher.ENCRYPT_MODE, key);
        AlgorithmParameters parameters = pbeCipher.getParameters();
        IvParameterSpec ivParameterSpec = parameters.getParameterSpec(IvParameterSpec.class);
        byte[] cryptoText = pbeCipher.doFinal(value.getBytes("UTF-8"));
        byte[] iv = ivParameterSpec.getIV();
        
        return DatatypeConverter.printBase64Binary(iv) + ":" + DatatypeConverter.printBase64Binary(cryptoText);
    }
    
    public static String decrypt(String value, int iterationCount) throws GeneralSecurityException, IOException, Exception {
    	SecretKeySpec key = createSecretKey(p.toCharArray(), salt, iterationCount, keyLength);
        String iv = value.split(":")[0];
        String property = value.split(":")[1];
        Cipher pbeCipher = Cipher.getInstance("AES/CBC/PKCS5Padding");
//        byte[] b = new String(iv).getBytes();
        pbeCipher.init(Cipher.DECRYPT_MODE, key, new IvParameterSpec(DatatypeConverter.parseBase64Binary(iv)));
        return new String(pbeCipher.doFinal(Base64.decodeBase64(property.getBytes())), "UTF-8");
    }
    

    //SHA-3-512
//    public static String encrypt512(String toencrip) throws IOException {
//    	md = new org.bouncycastle.jcajce.provider.digest.SHA3.DigestSHA3(512);
//        return bytesToHex(md.digest(toencrip.getBytes("UTF-8")));
//    }

    public static String bytesToHex(byte[] bytes) {
        char[] hexChars = new char[bytes.length * 2];
        for (int j = 0; j < bytes.length; j++) {
            int v = bytes[j] & 0xFF;
            hexChars[j * 2] = hexArray[v >>> 4];
            hexChars[j * 2 + 1] = hexArray[v & 0x0F];
        }
        return new String(hexChars);
    }
    

}
