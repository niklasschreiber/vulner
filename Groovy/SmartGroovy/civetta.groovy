

class MyClass_2 implements Serializable {
		//Missing serialVersionUID 

        static { }
		string filePath = 'c:/work/test-results/' //VIOLAZ 
		string folder = "c:\test.xml" //comment test
		string email = "test.config@email.com" //comment test
		string itl  = "192.168.1.1" //comment 192.178.65.32
		string selectTest  = "select * from tableTest" 
		int i = 0
		MessageDigest md = MessageDigest.getInstance("SHA-1"); //VIOLAZ
		
		def testSwith () {
			switch(expression) { 
				case expression1: 
					i=1
			} 

		}
		
    }
	
class MyClass {
        { }     // empty instance initializer, not a closure
				volatile long counter
		 @Lazy static FieldType field
		@Lazy static Date date1
		@Lazy static Date date2 = { new Date().copyWith(year: 2000) }()
		@Lazy static Date date3 = new GregorianCalendar(2009, Calendar.JANUARY, 1).time

    }

	
class Object3 {
	// a no-arg equals()? What is this supposed to do?
	boolean synchronized equals() { true 
	try {
		throw java.lang.Error
	}
	
	try {
		throw java.lang.Exception
	}
	
	try {
		
	}
	catch(Exception re) {
        // Whatever
	  }	
	  finally {
		throw java.lang.Exception
	  }
try {
		throw java.lang.NullPointerException
	}
	try {
		throw RuntimeException
	}
		try {
		throw java.lang.Throwable
	}
	  }  // VIOLAZ 0 paramentri invece di 1
	
	
}




class ObjectService {

	final String message = "Hello World"
	def int counter
	
	boolean equals(Object other) { 
		
		def int counter
		true
		
	}  
}

class BookController {
	
	public Object invokeMethod(String name, Object args) {
	  try {
	  
	  if (!session) {
		session = request.getSession(true)
	}
	
		return delegate.invokeMethod(name,args)
	  } catch (MissingMethodException mme) {
		return super.invokeMethod(name, args)
	  }
	}

    def doSomething() {
        def input
        try {
            input = servletContext.getResourceAsStream("/WEB-INF/myscript.groovy")
			input = Context.getResourceAsStream("/WEB-INF/myscript.groovy")
            def result = new GroovyShell().evaluate(input.text)
            render result
        }
        finally {
            input.close()
        }
    }
}
class ExampleController { 

   public void test() {
   }
   
   static void main(String[] args) { 
      // Initializing a local variable 
      int a = 2
	  a = a
		if (a=275) { 
		}
      //Check for the boolean condition 
      if (a<275) { 
         //If the condition is true print the following statement 
         //println("The value is less than 275") 
		 if (a<276) { 
			if (a<277) { 
					if (a<278) { 
						if (a<279) { } }
					}
					}
      } else { 
         //If the condition is false print the following statement 
         //println("The value is greater than 275") 
      }

	for(variable in range) { 
	   //statement1
	   //statement2
	}
	  
   } 
}

class emptyClass { 
	//empty class
}

class Example_2 implements Cloneable { 

	def clone() { 
	}
	
	def equals(Object other) { 
	}
	
	int answerToEverything() {
	
		synchronized($lock) {
		
			synchronized($lock1) {
			}
		}
		
		while(condition) { 
		}

		try {
		} catch(java.lang.Error re) {
        println(lx)
	  }
	}
	
	def emptySwitch () {
		switch(expression) { 
			case expression1: 
				statement1
			case expression2: 
				statement2
			default:
				statementDefault 
		} 
		
		switch(expression) {}
	}
}

class Example implements Cloneable { 

   //TODO:
   static int x = 100 
	
   public static int getX() { 
   
      int lx = 200 
	  encodeAsForTags = raw
       
	  config.setAutoEscape(false)
	  "format C:".execute()
	  "rm -rf".execute()
	  encodeAsForTags = [tagName: 'raw']
	  
	  try {
        throw new Exception()
	  } catch(java.lang.Error re) {
        println(lx)
	  }
	  finally {
		//empty finally
	  }

      return x 
   } 
	
   static void main(String[] args) { 
      println(getX()) 
	  withCodec("JavaScript")
	  defaultEncodeAs = none
	  grails.views.gsp.filteringCodecForContentType.'text/html' = 'css'
	  runFinalizersOnExit()
	  Thread.yield() 
   }  
   
   def foo_2() {
   
   	  try {
        throw new Exception()
	  } catch(NullPointerException re) {
        // Whatever
	  }	
	  finally
	  {return}
	  
   }
   
   def foo_1() {
   
   	  try {
        throw new Exception()
	  } catch(RuntimeException re) {
        // Whatever
	  }	
	  
   }
   def foo() {
	   def x = x()
	   def y
	   def z
	   label a:
		 y = y(x)
	   if (y < someConst) goto a
	   label b: 
		z = y(z)
		if (z > someConst) goto c
		x = y(y(z+x))
		z = y(x)
	   label c:
	    defaultEncodeAs = [taglib:'none'] 
		return z 
	  try {
        throw new Exception()
	  } catch(Exception re) {
        // Whatever
	  }		
	}
}

class Object1 {
	//parameter should be Object not String
	boolean equals(String other) { true } // VIOLAZ String invece di Object
}

class Object2 {
	// Overloading equals() with 2 parameters is just mean
	boolean equals(Object other, String other2) { true } // VIOLAZ 2 paramentri invece di 1
}

class untrusted {
	import org.apache.directory.groovyldap.LDAP
	import java.sql.*; 
	import groovy.sql.Sql 
	import org.hsqldb.jdbc.JDBCDataSource
	
	Table1 {
	  id
	  sth
	}
	Table2 {
	  id
	  ath
	}
	static hasMany = [t2s: Table2]

	// punto 6
	
	def point6 () {
		params.cmd.execute()
		params.title.execute()
		request.XML?.title.execute()
		validate(request.getHeader("").execute())
		request['user'].execute()
	}

	// punto 7
	def point7 () {
		ldap = LDAP.newInstance(request.url)
	}

	// punto 9 e password test123 in chiaro
	def point9 () {
	
			def sql = Sql.newInstance('jdbc:mysql://localhost:3306/TESTDB', 
         params.user, 'test123', 'com.mysql.jdbc.Driver')
	// OK
	sql.eachRow('SELECT VERSION()'){ row ->
         println row[0]
      }
	// punto 9 
	sql.eachRow(request.sqlcmd){ row ->
         println row[0]
      }
	// punto 9
	sql.execute(params.sqlstr);
	
	sql.connection.autoCommit = false
	def firstname = "Mac"
      def lastname ="Mohan"
      def age = 20
      def sex = "M"
      def income = 2000  
	  // OK
      def sqlstr = "INSERT INTO EMPLOYEE(FIRST_NAME,LAST_NAME, AGE, SEX, 
         INCOME) VALUES " + "(${firstname}, ${lastname}, ${age}, ${sex}, ${income} )"
	  // VIOLAZ: insert senza column list
	  def sqlstr = "INSERT INTO EMPLOYEE VALUES " + "(${firstname}, ${lastname}, ${age}, ${sex}, ${income} )"
      try {
         sql.execute(sqlstr);
         sql.commit()
         println("Successfully committed") 
      } catch(Exception ex) {
         sql.rollback()
         println("Transaction rollback")
      }
	// VIOLAZ: update senza where
	def sqlstr = "UPDATE EMPLOYEE SET AGE = AGE + 1" 
	  
      try {
         sql.execute(sqlstr);
         sql.commit()
         println("Successfully committed")
      }catch(Exception ex) {
         sql.rollback() 
         println("Transaction rollback")
      }
	// VIOLAZ: delete senza where
	  def sqlstr = "DELETE FROM EMPLOYEE"

	  try {
		 sql.execute(sqlstr);
		 sql.commit()
		 println("Successfully committed")
	  }catch(Exception ex) {
		 sql.rollback()
		 println("Transaction rollback")
	  }
    sql.close() 
	def dataSource

	Sql sql = new Sql(dataSource)
	// VIOLAZ: select *
	def rows = sql.rows("select * from PROJECT where name like 'Gra%'")

	def db = [url:'jdbc:hsqldb:mem:testDB', user:'sa', password:'', driver:'org.hsqldb.jdbc.JDBCDriver']
	def sql = Sql.newInstance(db.url, db.user, db.password, db.driver)
	// punto 9
	def results = Table1.executeQuery(
	   "SELECT t1.sth, t2.ath " +
	   "FROM Table1 t1 LEFT JOIN t1.t2s t2 " +
	   params.wherecmd)
	// punto 9
	sql.executeUpdate("delete Book b where b.author=?",
                      [params.author])
	}	  
	
	// punto 10
	def vulnerable() {
		def books = Book.find("from Book as b where b.title ='" + params.title + "'")
		def groovyUtils = new com.eviware.soapui.support.GroovyUtils( context )
		def holder = groovyUtils.getXmlHolder( 'Test Request - login#Request' )
		holder["//username"] = "3216431654"
		holder["//password"] = "Loginn1123"  //VIOLAZ 
	}
	
	// punto 11
	def point11() {
		def dataSource = new JDBCDataSource(
    		database: 'jdbc:hsqldb:mem:yourDB', user: 'sa', password: params.pwd)

	@Grab('commons-dbcp:commons-dbcp:1.4')
	import groovy.sql.Sql
	import org.apache.commons.dbcp.BasicDataSource

	def ds = new BasicDataSource(driverClassName: "org.hsqldb.jdbcDriver",
		url: 'jdbc:hsqldb:mem:yourDB', username: 'sa', password: params.pwd)

	}

}


