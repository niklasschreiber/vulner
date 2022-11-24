import com.eviware.soapui.support.types.StringToStringMap
import java.io.UnsupportedEncodingException;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.Timestamp;
import java.util.Date;

//Specify authentication data
// VULN
apiKey = "123";
// VULN
secret = "123";

// Get a timestamp
date= new java.util.Date();
timestamp = (date.getTime() / 1000);

// Get a hashed signature
signature = null;

toBeHashed = apiKey + secret + timestamp;
MessageDigest md = MessageDigest.getInstance("SHA-1");
byte[] bytes = md.digest(toBeHashed.getBytes("UTF-8"));
StringBuilder sb = new StringBuilder();
for(int i=0; i< bytes.length ;i++){
      sb.append(Integer.toString((bytes[i] & 0xff) + 0x100, 16).substring(1));
}

signature = sb.toString()

// Complete the header value
authHeaderValue = "EAN APIKey=" + apiKey + ",Signature=" + signature + ",timestamp=" + timestamp;

// Obtain the list of request headers
headers = request.getRequestHeaders()

// Add a header to the request
StringToStringMap headermap = new StringToStringMap(headers)
if (headers.containsKeyIgnoreCase("authorization") ){
                headermap.replace("authorization", authHeaderValue)
                } else {
                headermap.put("authorization", authHeaderValue)
                }
// VULN 
request.requestHeaders = headermap