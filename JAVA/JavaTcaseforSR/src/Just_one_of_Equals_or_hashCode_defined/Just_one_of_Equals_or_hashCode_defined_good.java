package Just_one_of_Equals_or_hashCode_defined;

public class Just_one_of_Equals_or_hashCode_defined_good {   // good 仅定义了equals方法或hashcode方法

	int a;
	String b;

	public Just_one_of_Equals_or_hashCode_defined_good(int a, String b) {
		this.a = a;
		this.b = b;
	}

	public int hashCode() {    
		return a * (b.hashCode()); 
	}

	public boolean equals(Object o) {
		Just_one_of_Equals_or_hashCode_defined_good d = (Just_one_of_Equals_or_hashCode_defined_good) o;
		if(d!=null){
			return (this.a == d.a) && (this.b.equals(d.b));
		}else
			return false;
		
	}

}
