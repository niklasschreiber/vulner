package Insecuere_Randomness;

import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.util.Random;
import java.util.logging.Logger;

public class Insecuere_Randomness
{

	static final Logger log = Logger.getLogger("logger");
	
    public void bad()
    {

        Random rand = new Random();
        /* FLAW: seed is static, making the numbers always occur in the same sequence */
        rand.setSeed(System.currentTimeMillis());
        log.info("Random int: " + rand.nextInt(21));  // bad 不安全的随机数

    }


    public void good()
    {

        /* FIX: use SecureRandom to be cryptographically secure */
        SecureRandom securerand;
		try {
			securerand = SecureRandom.getInstance("SHA1PRNG");
			log.info("Random int: " + securerand.nextInt(21));  // good 不安全的随机数
		} catch (NoSuchAlgorithmException e) {
			log.info("NoSuchAlgorithmException");
		}
        

    }

   
}

