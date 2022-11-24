package org.grails.tomcat.valve;

import org.apache.catalina.connector.Request;
import org.apache.catalina.connector.Response;
import org.apache.catalina.valves.ValveBase;

import javax.servlet.ServletException;
import java.io.IOException;

/**
 * Makes the Servlet API return https urls so that redirects work properly
 * when accessing the application via https reverse-proxy like Cloudflare
 */
public class AlwaysHttpsValve extends ValveBase {
	private int httpsServerPort = 443;

	@Override
	public void invoke(Request request, Response response) throws IOException, ServletException {
		final String originalScheme = request.getScheme();
		final boolean originalSecure = request.isSecure();
		final int originalServerPort = request.getServerPort();
		try {
			applyRequestProperties(request);
			invokeNext(request, response);
		} finally {
			request.setSecure(originalSecure);
			request.getCoyoteRequest().scheme().setString(originalScheme);
			request.setServerPort(originalServerPort);
		}
	}

	protected void applyRequestProperties(Request request) {
		request.setSecure(true);
		request.getCoyoteRequest().scheme().setString("https");
		request.setServerPort(getHttpsServerPort());
	}

	protected void invokeNext(Request request, Response response) throws IOException, ServletException {
		getNext().invoke(request, response);
	}

	public int getHttpsServerPort() {
		return httpsServerPort;
	}

	public void setHttpsServerPort(int httpsServerPort) {
		this.httpsServerPort = httpsServerPort;
	}
}
