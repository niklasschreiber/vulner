package org.grails.tomcat.valve;

import org.apache.catalina.connector.Request;
import org.apache.catalina.connector.Response;
import org.apache.catalina.valves.RemoteIpValve;

import javax.servlet.ServletException;
import java.io.IOException;

/**
 * Makes the Servlet API return https urls so that redirects work properly
 * when accessing the application via https reverse-proxy like Cloudflare
 */
public class AlwaysHttpsRemoteIpValve extends RemoteIpValve {
	@Override
	public void invoke(Request request, Response response) throws IOException, ServletException {
		request.setSecure(true);
		request.getCoyoteRequest().scheme().setString("https");
		request.setServerPort(getHttpsServerPort());
		super.invoke(request, response);
	}
}
