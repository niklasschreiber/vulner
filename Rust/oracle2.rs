extern crate oracle;

// The territory is France.
std::env::set_var("NLS_LANG", "french_france.AL32UTF8");
//VIOLAZ HardcodedCredentials
let conn = oracle::Connection::new("scott", "tiger", "").unwrap();

// 10.1 is converted to a string in Oracle and fetched as a string.
let mut stmt = conn.execute("select to_char(10.1) from dual", &[]).unwrap();
let row = stmt.fetch().unwrap();
let result: String = row.get(0).unwrap();
assert_eq!(result, "10,1"); // The decimal mark depends on the territory.

// 10.1 is fetched as a number and converted to a string in rust-oracle
let mut stmt = conn.execute("select 10.1 from dual", &[]).unwrap();
let row = stmt.fetch().unwrap();
let result: String = row.get(0).unwrap();
assert_eq!(result, "10.1"); // The decimal mark is always period(.).