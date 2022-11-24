package org.xsx.dao;

import java.util.List;

import org.xsx.annotation.MyBatisRepository;
import org.xsx.entity.Condition;
import org.xsx.entity.Emp;

/**
 * DAO组件
 * @author xusha
 *
 */
@MyBatisRepository
public interface EmpDao {
	public List<Emp> findAll();
	public List<Emp> findByEmp(Condition cond);
	public List<Emp> findBySalary(Condition cond);
	public List<Emp> findByDepNoAndSalary(Condition cond);
	public void updateEmp(Emp emp);
	
	public List<Emp> findByDepNoAndSalary2(Condition cond);
	public void updateEmp2(Emp emp);
	
	public List<Emp> findByIds(Condition cond);
}
