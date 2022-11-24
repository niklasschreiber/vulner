
class State () extends OutOfMemoryError {

def evenDivisors(numbers: List[Int]) {
    numbers.map { x =>
            divisors(x).filter { x =>  // VIOLAZ: usa sempre x
        isEven(x)
      }
    }
}
 
// OK
		def evenDivisors(numbers: List[Int]) {
			numbers.map { num =>
			divisors(x).filter { divisor => pippo(x) }
			}
		}


    // VIOLAZ: la classe non extends Serializable
    private transient int[] stateData;
    @transient  // VIOLAZ   
    private int[] stateData;
	Random(10)
	
	def evaluate() = {
    val clazz = prepareClass
    val settings = new Settings
    settings.usejavacp.value = true
    settings.deprecation.value = true

    val eval = new IMain(settings)
    val evaluated = eval.interpret(clazz)  //VIOLAZ
    val res = eval.valueOfTerm("res0").get.asInstanceOf[Int]
    println(res) //yields 9
  }


	def executeCommand(value:String) = Action {
    val result = value.!
    Ok("Result:\n"+result)  //VIOLAZ: result contiene value, che è un parametro della def
	
	db.run {
		  sql"select * from people where name = '#$value'".as[Person]  //VIOLAZ
		} 
		db.run { 
		  sql"select * from people where name = $value".as[Person]  //OK
		}
	}

	def doGet(value:String) = Action {
		WS.url(value).get().map { response =>
			Ok(response.body)  // VIOLAZ
		}
	}
	
	def doGet(value:String) = Action {
		val configElement = configuration.underlying.getString(value)
		Ok("Hello "+ configElement +" !")  // VIOLAZ
	}

}
 
class PersistentState implements Serializable {
@transient     
private int[] stateData;
//OK
private transient int[] cachedComputedData;
}

class BadPoint(x: Int, y: Int) extends Serializable {
  // VIOLAZ
  def readObject(arg: ObjectInputStream) { }
  def writeObject(arg: ObjectOutputStream) { }
}
 
class GoodPoint(x: Int, y: Int) extends Serializable {
  // OK: the methods are private
  private def readObject(arg: ObjectInputStream) { }
  private def writeObject(arg: ObjectOutputStream) { }
}


class PhoneBook {
  private var entries: Map[Name, Int] = Map.empty
 
  /** VIOLAZ: Serializable class with a non-serializable outer class */
  class Name(val name: String) extends Serializable {
    def lookup: Int = entries(this)
  }
}


class BadSpeed(val speed: Int) extends Serializable {
  // VIOLAZ
  def readResolve() =
    if (speed == 0) BadSpeed.zero
    else this
}
 
class GoodSpeed(val speed: Int) extends Serializable {
  // OK: the return type is AnyRef
  def readResolve(): AnyRef =
    if (speed == 0) GoodSpeed.zero
    else this
}


class WorkQueue(lock: Lock) {
  val cond = lock.newCondition()
 
  def next() {
    cond.wait() // BAD: should use await
 
    cond.await() // GOOD
  }
  
  def options(arg: Option[Int]) = {
  val optional = Some(5)
  val argVal = arg.get  // VIOLAZ
  val argVal3 = arg.getOrElse(0) // VIOLAZ
}


}

object civetta {

	def compare(array1: Array[Int], array2: Array[Int]) {
		// VIOLAZ: comparing arrays with ==
		if (array1 == array2) {
			println("They are the same")
		}

		// OK: using eq explicitly
		if (array1 eq array2) {
			println("They are the same object")
		}

		// OK: comparing with sameElements
		if (array1.sameElements(array2)) {
			println("They have the same elements")
		}

		// OK: comparing using deep
		if (array1.deep == array2.deep) {
			println("They have the same elements")
		}
		
		wait()
	}
		
   def addInt( a:Int, b:Int ) : Int = {
   
      var sum:Int = 0
      sum = a + b
      return sum
	  
	  ws.url(url).withAuth("john", "secret", WSAuthScheme.BASIC)
	  BitcoinMiner.ActorSystem("BitCoinMinerSystem")
		Thread.yield() 
		Thread.setPriority() 
		Thread.getPriority() 
		Notify()
		
		val output = Process("env",
                     None,
                     "SECURITY_AUTHENTICATION " -> "none",  //VIOLAZ
                     "VAR2" -> "bar")

		fork in Test := true
		envVars in Test := Map("SECURITY_AUTHENTICATION " -> " none ") //VIOLAZ


	// VIOLAZ
	def postalCodes: URL = getClass.getResource("postal-codes.csv")
 
	// OK
	def postalCodes2: URL = classOf[Address].getResource("postal-codes.csv")

	try {}
	catch {}
	finally {}
	

	  try

		{ 
			// Dividing a number 
			val result = 11/0
		} 
		  
		// Catch clause 
		catch
		{  
				// Case statement 
				case x: ArithmeticException => 
				{  
			  
				// Display this if exception is found 
				println("Exception: A number is not divisible by zero.") 
			} 
		} 
	
   }
   


}

class MyThread extends Thread {
  // VIOLAZ: Si deve chiamare Run
  def apply() {
    println("Hello")
  }
  
  def print() {
    // VIOLAZ
    synchronized {
    }
    println("The count is: " + count)
  }

	def print1() {
    // VIOLAZ
    synchronized {
		println("The count is: " + count)
    }
    println("The count is: " + count)
  }
  

}
class MyThread extends Runnable {
    // OK
    def run() {
        // your custom behavior here
    }
}
class MyThread extends Thread {
  for (i <- 1 to 100) {
    val thread = new Thread {
	   // OK
        override def run() {
            // your custom behavior here
        }
    }
    thread.start
    Thread.sleep(50) // slow the loop down a bit
 }
}

abstract class Super {
  // VIOLAZ: invalid starting a thread in the constructor
  new Thread() {
    def run() {
      printMessage()
    }
  }.start()
   
  def printMessage()
}


trait Compiler {
  private var options: Options = new Options { }
   
   var results: Int
 
	def waitResults() {
	  while (results == 0) {
		Thread.sleep(1000)  // VIOLAZ
	  }
	}


  def setOptionsBad(newOptions: Options) {
    // VIOLAZ: sync del field "options"
    options.synchronized {
      options = newOptions
    }
  }
 
  def setOptionsGood(newOptions: Options) {
    // OK: synchronizing on the receiver
    synchronized {
      options = newOptions
    }
  }
}

class BadPoint(x: Int, y: Int) extends Externalizable {
  // VIOLAZ
  def readExternal(in: ObjectInput) {  }
  def writeExternal(out: ObjectOutput) { }
}
 
class GoodPoint(x: Int, y: Int) extends Externalizable {
  // OK
  def this() = this(0, 0)
 
  def readExternal(in: ObjectInput) {  }
  def writeExternal(out: ObjectOutput) {. }
}

class Point(x: Int, y: Int) extends Serializable {
  // VIOLAZ: non deve essere un field
  private val serialVersionUID = 13L
}
 
object Point {
  // OK, non è un field
  private val serialVersionUID = 13L
}

@SerialVersionUID(13L) // OK, è un’annotazione
class GoodPoint(val x: Int, val y: Int) extends Serializable {}

// VIOLAZ
class DerivedFactors() extends Serializable {
  var efficiency: Int
  var costPerItem: Int
  var profitPerItem: Int
}
class PerformanceRecord(val unitId: String) extends Serializable {
  // OK: the field is marked @transient, so it will be quietly skipped
  @transient
  var goodFactors: DerivedFactors = _
}

