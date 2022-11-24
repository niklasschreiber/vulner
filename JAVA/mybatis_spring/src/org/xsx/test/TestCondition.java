package org.xsx.test;

import java.util.ArrayList;
import java.util.List;

import org.junit.Test;
import org.springframework.context.ApplicationContext;
import org.springframework.context.support.ClassPathXmlApplicationContext;
import org.xsx.dao.EmpDao;
import org.xsx.entity.Condition;
import org.xsx.entity.Emp;

public class TestCondition {
	@Test
	public void testIf() {
		String conf = "applicationContext.xml";
		ApplicationContext context = new ClassPathXmlApplicationContext(conf);
		EmpDao dao = context.getBean(EmpDao.class);
		Condition cond = new Condition();
		cond.setDepNo(20);
		List<Emp> list = dao.findByEmp(cond);
		for (Emp e : list) {
			System.out.println(e.getId()+"--"+e.getName()+"--"+e.getAge());
		}
	}
	
	@Test
	public void testChoose() {
		String conf = "applicationContext.xml";
		ApplicationContext context = new ClassPathXmlApplicationContext(conf);
		EmpDao dao = context.getBean(EmpDao.class);
		Condition cond = new Condition();
		cond.setSalary(3500.0);
		List<Emp> list = dao.findBySalary(cond);
		for (Emp e : list) {
			System.out.println(e.getId()+"--"+e.getName()+"--"+e.getSalary());
		}
	}
	
	@Test
	public void testwhere() {
		String conf = "applicationContext.xml";
		ApplicationContext context = new ClassPathXmlApplicationContext(conf);
		EmpDao dao = context.getBean(EmpDao.class);
		Condition cond = new Condition();
		cond.setDepNo(30);
		cond.setSalary(3500.0);
		List<Emp> list = dao.findByDepNoAndSalary(cond);
		for (Emp e : list) {
			System.out.println(e.getDepNo()+"--"+e.getName()+"--"+e.getSalary());
		}
	}
	
	@Test
	public void testset() {
		String conf = "applicationContext.xml";
		ApplicationContext context = new ClassPathXmlApplicationContext(conf);
		EmpDao dao = context.getBean(EmpDao.class);
		Emp emp = new Emp();
		emp.setDepNo(21);
		emp.setName("justin");
		emp.setId(3);
		dao.updateEmp(emp);
		List<Emp> list = dao.findAll();
		for(Emp e:list){
			System.out.println(e.getDepNo()+e.getName());
		}
	}
	
	@Test
	public void testtrim1() {
		String conf = "applicationContext.xml";
		ApplicationContext context = new ClassPathXmlApplicationContext(conf);
		EmpDao dao = context.getBean(EmpDao.class);
		Condition cond = new Condition();
		cond.setDepNo(10);
		cond.setSalary(3500.0);
		List<Emp> list = dao.findByDepNoAndSalary2(cond);
		for (Emp e : list) {
			System.out.println(e.getDepNo()+"--"+e.getName()+"--"+e.getSalary());
		}
	}
	
	@Test
	public void testtrim2() {
		String conf = "applicationContext.xml";
		ApplicationContext context = new ClassPathXmlApplicationContext(conf);
		EmpDao dao = context.getBean(EmpDao.class);
		Emp emp = new Emp();
		emp.setDepNo(20);
		emp.setName("justin bibo");
		emp.setId(3);
		dao.updateEmp2(emp);
		List<Emp> list = dao.findAll();
		for(Emp e:list){
			System.out.println(e.getDepNo()+e.getName());
		}
	}
	
	@Test
	public void testforeach() {
		String conf = "applicationContext.xml";
		ApplicationContext context = new ClassPathXmlApplicationContext(conf);
		EmpDao dao = context.getBean(EmpDao.class);
		Condition cond = new Condition();
		List<Integer> ids = new ArrayList<Integer>();
		ids.add(3);
		ids.add(5);
		ids.add(7);
		ids.add(6);
		cond.setIds(ids);
		List<Emp> list = dao.findByIds(cond);
		for (Emp e : list) {
			System.out.println(e.getDepNo()+"--"+e.getName()+"--"+e.getSalary());
		}
	}
	
}
