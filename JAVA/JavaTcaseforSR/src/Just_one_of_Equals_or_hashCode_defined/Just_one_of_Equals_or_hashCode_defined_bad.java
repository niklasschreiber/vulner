package Just_one_of_Equals_or_hashCode_defined;

public class Just_one_of_Equals_or_hashCode_defined_bad {  

	int a;
	String b;

	public Just_one_of_Equals_or_hashCode_defined_bad(int a, String b) {
		this.a = a;
		this.b = b;
	}

	public boolean equals(Object o) {  // bad  仅定义了equals方法或hashcode方法
		Just_one_of_Equals_or_hashCode_defined_bad d = (Just_one_of_Equals_or_hashCode_defined_bad) o;
		if(d != null){
			return (this.a == d.a) && (this.b.equals(d.b));
		}else
			return false;
		
	}

}
