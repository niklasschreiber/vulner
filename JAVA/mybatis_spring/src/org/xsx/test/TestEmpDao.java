package org.xsx.test;

import java.util.List;

import org.junit.Test;
import org.springframework.context.ApplicationContext;
import org.springframework.context.support.ClassPathXmlApplicationContext;
import org.xsx.dao.EmpDao;
import org.xsx.entity.Emp;

public class TestEmpDao {
	@Test
	public void testFindAll(){
		String conf = "applicationContext.xml";
		ApplicationContext context = new ClassPathXmlApplicationContext(conf);
		EmpDao dao = context.getBean(EmpDao.class);
		List<Emp> list = dao.findAll();
		for(Emp e:list){
			System.out.println(e.getName());
		}
	}
}
