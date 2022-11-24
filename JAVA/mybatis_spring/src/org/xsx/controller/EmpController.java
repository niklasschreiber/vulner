package org.xsx.controller;

import java.util.List;

import javax.annotation.Resource;

import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.RequestMapping;
import org.xsx.dao.EmpDao;
import org.xsx.entity.Emp;

@Controller
@RequestMapping("emp")
public class EmpController {
	@Resource
	private EmpDao empDao;
	
	@RequestMapping("/findEmp.do")
	public String find(Model model){
		List<Emp> list = empDao.findAll();
		model.addAttribute("emps", list);
		return "emp/emp_list";
	}
}
