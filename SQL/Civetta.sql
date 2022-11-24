CREATE FUNCTION CtrAmount ( @Ctr_Id int(10) )
  BEGIN
	-- VIOLAZ Avoid critical SQL operations inside Functions or Procedures (SRA)
	CREATE TABLE Employee_Info
	EmployeeID int,
	EmployeeName varchar(255),
	Emergency ContactName varchar(255),
	PhoneNumber int,
	Address varchar(255),
	City varchar(255),
	Country varchar(255)

	DROP Table Employee_Info;

	-- VIOLAZ Avoid critical SQL operations inside Functions or Procedures (SRA)
	ALTER TABLE Employee_Info
	ADD BloodGroup varchar(255);
	ALTER TABLE Employee_Info
	DROP COLUMN BloodGroup ;

	BACKUP DATABASE Employee
	TO DISK = 'C:UsersSahitiDesktop';

	CREATE INDEX index_EmployeeName
	ON Persons (EmployeeName);
	DROP INDEX Employee_Info.index_EmployeeName;

	USE Employee;
	-- VIOLAZ Avoid critical SQL operations inside Functions or Procedures (SRA)
	INSERT INTO Employee_Info(EmployeeID, EmployeeName, Emergency ContactName, PhoneNumber, Address, City, Country)
	VALUES ('06', 'Sanjana','Jagannath', '9921321141', 'Camel Street House No 12', 'Chennai', 'India');
	-- VIOLAZ Avoid critical SQL operations inside Functions or Procedures (SRA) 
	INSERT INTO Employee_Info
	VALUES ('07', 'Sayantini','Praveen', '9934567654', 'Nice Road 21', 'Pune', 'India');
	-- VIOLAZ Avoid critical SQL operations inside Functions or Procedures (SRA)
	UPDATE Employee_Info
	SET EmployeeName = 'Aahana', City= 'Ahmedabad'
	WHERE EmployeeID = 1;
	-- VIOLAZ Avoid critical SQL operations inside Functions or Procedures (SRA)
	DELETE FROM Employee_Info
	WHERE EmployeeName='Preeti';
  END
GO
