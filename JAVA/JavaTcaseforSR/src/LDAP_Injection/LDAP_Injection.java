package LDAP_Injection;


import javax.naming.*;
import javax.naming.directory.*;
import javax.servlet.http.*;
import java.util.Hashtable;
import java.io.IOException;
import java.util.logging.Logger;

public class LDAP_Injection
{
	static final Logger log = Logger.getLogger("logger");
	
    /* uses badsource and badsink */
    public void bad(HttpServletRequest request, HttpServletResponse response) throws NamingException, IOException
    {
        String data = System.getProperty("data"); /* init data */

        Hashtable<String, String> env = new Hashtable<String, String>();
        env.put(Context.INITIAL_CONTEXT_FACTORY,"com.sun.jndi.ldap.LdapCtxFactory");
        env.put(Context.PROVIDER_URL, "ldap://localhost:389");
        DirContext ctx = new InitialDirContext(env);

        String search = "(cn=" + data + ")"; /* POTENTIAL FLAW: unsanitized data from untrusted source */

        NamingEnumeration<SearchResult> answer = ctx.search("", search, null);  // bad LDAP注入
        if (answer.hasMore())
        {
            log.info("ok");
        }

    }


    public void good(HttpServletRequest request, HttpServletResponse response) throws NamingException, IOException
    {
        String data = "foo";

        Hashtable<String, String> env = new Hashtable<String, String>();
        env.put(Context.INITIAL_CONTEXT_FACTORY,"com.sun.jndi.ldap.LdapCtxFactory");
        env.put(Context.PROVIDER_URL, "ldap://localhost:389");
        DirContext ctx = new InitialDirContext(env);

        String search = "(cn=" + data + ")"; /* POTENTIAL FLAW: unsanitized data from untrusted source */

        NamingEnumeration<SearchResult> answer = ctx.search("", search, null);  // good LDAP注入
        if (answer.hasMore())
        {
            log.info("ok");
        }

    }
}

