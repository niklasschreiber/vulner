extern crate oracle;

fn main() {
    // Connect to a database.
	//VIOLAZ HardcodedCredentials
    let conn = oracle::Connection::new("CTXSYS", "secretSYS", "//localhost/XE").unwrap();
    // Select a table with a bind variable.
	// VIOLAZ SQL Injection apice singolo non chiuso in  'admin'--'
    let mut stmt = conn.execute("SELECT * FROM members WHERE username = 'admin'--' AND password = 'password'  and deptno = :1", &[&30]).unwrap();

    // Print column names
    for info in stmt.column_info() {
        print!(" {:14}|", info.name());
    }
    println!("");
	// VIOLAZ SQL Injection 1=1
	let mut stmt = conn.execute("SELECT * FROM members WHERE deptno = :1 GROUP BY deptno HAVING 1=1 --", &[&30]).unwrap();
    // Print column types
    for info in stmt.column_info() {
        print!(" {:14}|", info.oracle_type().to_string());
    }
    println!("");

    // Print column values
    println!("---------------|---------------|---------------|");
    while let Ok(row) = stmt.fetch() {
        // get a column value by position (0-based)
        let ename: String = row.get(0).unwrap();
        // get a column by name (case-insensitive)
        let sal: i32 = row.get("sal").unwrap();
        // get a nullable column
        let comm: Option<i32> = row.get(2).unwrap();

        println!(" {:14}| {:>10}    | {:>10}    |",
                 ename,
                 sal,
                 comm.map_or("".to_string(), |v| v.to_string()));
    }
}