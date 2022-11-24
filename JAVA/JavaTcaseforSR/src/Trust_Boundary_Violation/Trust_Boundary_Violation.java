package Trust_Boundary_Violation;

import java.io.IOException;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

public class Trust_Boundary_Violation {

	 protected void bad(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
	       String name = req.getParameter("userName");
	       HttpSession sess = req.getSession();
	       sess.setAttribute("user", name); // bad 数据跨越信任边界
	   }
	 
	 protected void good(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
	       String name = req.getParameter("userName");
	       HttpSession sess = req.getSession();
	       name = SafeCheck(name);
	       if(name.equals("admin")){
	    	   sess.setAttribute("user", name); // good 数据跨越信任边界   
	       }else
	    	   return;
   	       
	   }
	 
	 
	 public String SafeCheck(String input){
	    	if("admin".equals(input)){
	    		return "admin";
	    	}else{
	    		return "baduser";
	    	}
	    }

}
