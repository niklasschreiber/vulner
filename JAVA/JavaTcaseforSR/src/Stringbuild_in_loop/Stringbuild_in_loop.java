package Stringbuild_in_loop;

public class Stringbuild_in_loop {

	public void Stringbuild_in_loop_bad() {

		String a = "test";

		for (int i = 0; i < 5; i++) {
			a = a + "<br>";  // bad 循环中拼接字符串
		}

	}

	public void Stringbuild_in_loop_good() {

		StringBuilder a = new StringBuilder("test");

		for (int i = 0; i < 5; i++) {

			a.append("<br>");  // good 循环中拼接字符串
		}

	}

}
