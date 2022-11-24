package XPath_Injection;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.InputStream;
import java.util.logging.Logger;

import javax.servlet.http.HttpServletRequest;
import javax.xml.xpath.XPath;
import javax.xml.xpath.XPathConstants;
import javax.xml.xpath.XPathExpressionException;
import javax.xml.xpath.XPathFactory;

import org.w3c.dom.NodeList;
import org.xml.sax.InputSource;

public class XPath_Injection {

	static final Logger log = Logger.getLogger("logger");

	public void bad(HttpServletRequest request) throws XPathExpressionException {

		String username = request.getParameter("name");

		String dir = "C:" + File.separator + "EmployeesData.xml";
		File d = new File(dir);
		XPathFactory factory = XPathFactory.newInstance();
		XPath xPath = factory.newXPath();
		NodeList nodes = null;
		InputStream in = null;
		InputSource inputSource = null;
		try {
			in = new FileInputStream(d);
			inputSource = new InputSource(in);
			String expression = "/employees/employee[loginID/text()='"
					+ username + "']";
			nodes = (NodeList) xPath.evaluate(expression, inputSource, XPathConstants.NODESET); // bad XPath注入
			log.info(nodes.item(1).getLocalName());
		} catch (FileNotFoundException e) {
			log.info("FileNotFoundException");
		} finally {
			try {
				if(in!=null){
					in.close();
				}
			} catch (IOException e) {
				log.info("IOException");
			}

		}
	}

	public void good(HttpServletRequest request)
			throws XPathExpressionException {

		String username = "foo";

		String dir = "C:" + File.separator + "EmployeesData.xml";
		File d = new File(dir);
		XPathFactory factory = XPathFactory.newInstance();
		XPath xPath = factory.newXPath();
		NodeList nodes = null;
		InputStream in = null;
		InputSource inputSource = null;
		try {
			in = new FileInputStream(d);
			inputSource = new InputSource(in);
			String expression = "/employees/employee[loginID/text()='"
					+ username + "']";
			nodes = (NodeList) xPath.evaluate(expression, inputSource, XPathConstants.NODESET); // good XPath注入
			log.info(nodes.item(1).getLocalName());
		} catch (FileNotFoundException e) {
			log.info("FileNotFoundException");
		} finally {
			try {
				if(in!=null){
					in.close();
				}
			} catch (IOException e) {
				log.info("IOException");
			}

		}
	}

}
