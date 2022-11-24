async fn foo(x: &RefCell<u32>) {                    ¨                      
  let mut y = x.borrow_mut();
  *y += 1;
  bar.await;
}

async fn foo(x: &RefCell<u32>) {                                 
  {
     let mut y = x.borrow_mut();
     *y += 1;
  }
  bar.await;
}
#[cfg(linux)]
#[cfg(unix)]
#[cfg(windows)]
#[cfg(macos)]
#[cfg(ios)] 
#[cfg(android)]

use std::net::IpAddr;
extern crate oracle;
extern crate foo;
extern crate insert_many; //VIOLAZ
extern crate exif;
use suricata_ipc::prelude::*; //VIOLAZ
use insert_many::InsertMany; //VIOLAZ

#[macro_use] extern crate rocket; //VIOLAZ
#[deprecated(since = "forever")]  //VIOLAZ
#[deprecated] //VIOLAZ
let x = async { //VIOLAZ
    foo()  
};
use fltk::{app, prelude::*, window::Window}; //VIOLAZ
use fltk::{app, button::Button, frame::Frame, prelude::*, window::Window}; //VIOLAZ
use fltk::{button::Button, prelude::*}; //VIOLAZ
use async_h1::{client::Encoder, server::ConnectionStatus}; //VIOLAZ
extern crate parse_duration; //VIOLAZ
use parse_duration::parse; //VIOLAZ
extern crate endian_trait; //VIOLAZ
use endian_trait:: Endian; //VIOLAZ

use wasmtime::*;  //VIOLAZ
use actix_http::{HttpService, Response}; //VIOLAZ
use serde::Deserialize;
use tar::Archive; //VIOLAZ
use tar::Builder; //VIOLAZ
use libsecp256k1::*; //VIOLAZ
use ark_r1cs_std::fields::nonnative::{AllocatedNonNativeFieldVar, NonNativeFieldVar}; //VIOLAZ
use ark_r1cs_std::{alloc::AllocVar, eq::EqGadget, fields::FieldVar, R1CSVar}; //VIOLAZ
use ammonia::clean; //VIOLAZ
use prost::Message; //VIOLAZ
use tokio::net::TcpListener; //VIOLAZ
use tokio::io::{AsyncReadExt, AsyncWriteExt}; //VIOLAZ
use lettre::{EmailTransport, SmtpTransport}; //VIOLAZ
use lettre_email::EmailBuilder; //VIOLAZ
use iced_x86::{Decoder, DecoderOptions, Formatter, Instruction, NasmFormatter}; //VIOLAZ
use std::any::Any as StdAny; //VIOLAZ
use comrak::{parse_document, format_html, Arena, ComrakOptions}; //VIOLAZ
use comrak::nodes::{AstNode, NodeValue}; //VIOLAZ
extern crate outer_cgi; //VIOLAZ
use outer_cgi::IO; //VIOLAZ
extern crate stackvec; //VIOLAZ
use ::stackvec::prelude::*; //VIOLAZ
use arenavec::rc::{Arena, SliceVec}; //VIOLAZ
use arenavec::ArenaBacking; //VIOLAZ


extern crate nalgebra as na;  //VIOLAZ

#[derive(Deserialize)]   //VIOLAZ
impl Foo {
    pub fn new() -> Self {
        // setup here ..
   }
    pub unsafe fn parts() -> (&str, &str) {
        // assumes invariants hold
		let cipher = Cipher:: des_ede3();  //VIOLAZ
		let addr = "127.26.0.1".parse::<IpAddr>().unWrap()  //VIOLAZ
		//VIOLAZ è nello stesso file anche la extern crate exif  
		let exif = exifreader.read_from_container(&mut bufreader)?;  
		bf_cbc();
		let ch = "SSL_RSA_WITH_NULL_MD5";
		reqwest::Client::new()
            .post(&format!("{}/newsletters", &self.address))
            // No longer randomly generated on the spot!
            .basic_auth("scott", Some(password))  //VIOLAZ
            .json(&body)
            .send()
            .await
            .expect("Failed to execute request.")

		reqwest::Client::new()
					.post(&format!("{}/newsletters", &self.address))
					// No longer randomly generated on the spot!
					.basic_auth(username, "tiger")  //VIOLAZ
					.json(&body)
					.send()
					.await
				.expect("Failed to execute request.")
				
	let password_hash = hasher
        .hash_password("secret", &salt)  //VIOLAZ

		Argon2::default()
        .verify_password("secret", &expected_password_hash) //VIOLAZ
	
	let password_hash = sha3::Sha3_256::digest("secret"); //VIOLAZ

	let password_hash = Argon2::default()
	.hash_password(“secret”, &salt) //VIOLAZ
	verify_password_hash(expected_password_hash, "secret") //VIOLAZ


    }
}

fn divisible_by_3(i_str: String) -> Result<(), String> {
    let i = i_str
        .parse::<i32>()
        .expect("cannot divide the input by three");   //VIOLAZ
    if i % 3 != 0 {
        Err("Number is not divisible by 3")?
    }
    Ok(())
	
	let mut v = Vec::new();
	v.push(0);  //VIOLAZ
	let v = Vec::from_iter(five_fives); //VIOLAZ
	let mut map = IdMap::new(); //VIOLAZ
	vec!(1, 2, 3, 4, 5).resize(0, 5);  //VIOLAZ
	
}

impl fmt::Display for Structure {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        write!(f, "{}", self.to_string())  //VIOLAZ
		let _: usize = unsafe { MaybeUninit::uninit().assume_init() }; //VIOLAZ
		better_macro::println!("Hello world!"); //VIOLAZ
    }
}


let _ = option_env!("HOME").unwrap();
pub fn foo(x: *const u8) { //VIOLAZ
    println!("{}", unsafe { *x });
	foo.unwrap_or(String::new());  //VIOLAZ
	foo.unwrap_or_else(String::new); //OK
	foo.unwrap_or_default(); //OK
	panic!("even with a good reason"); //VIOLAZ
	
	let x: &Option<&u32> = &Some(&0u32);  //VIOLAZ
	let x: Option<&u32> = Some(&0u32);  //OK
	let arr = [1, 2, 3, 4, 5];
	let sub = &arr[5..1];  //VIOLAZ x> y
	let sub = &arr[1..3];  //OK
	let len = unsafe { libc::strlen(cstring.as_ptr()) };  //VIOLAZ)
	let _ = (0..3).map(|x| x + 2).count();  //VIOLAZ
	
	for x in s.splitn(0, ":") {  //VIOLAZ
    // use x
	}

	for x in s.rsplitn(1, ":") { //VIOLAZ
		// use x
	}

	for x in s.splitn(2, ":") { //OK
		// use x
	}

}
pub fn read_u8() -> Result<u8, ()> { Err(()) } //VIOLAZ

fn main() {
    let x = String::from("hello world").repeat(1);  //VIOLAZ
}

fn foo(interned: Rc<Mutex<i32>>) {}  //VIOLAZ
fn result_with_panic() -> Result<bool, String>
{
    unimplemented!("error"); //VIOLAZ
	
	let mut x = PathBuf::from("/foo");
	x.push("/bar"); //VIOLAZ

	let mut x = PathBuf::from("/foo");
	x.push("bar");  //OK
	eprintln!("Hello world!");  //VIOLAZ
	println!("Hello world!");  //VIOLAZ
}



fn result_with_panic() -> Result<bool, String>
{
    unimplemented!(); //VIOLAZ
}

pub unsafe fn foo(x: *const u8) { //OK
    println!("{}", unsafe { *x });
}


fn foo(&Foo) -> &mut Bar {} 

#[repr(usize)]  //VIOLAZ
enum NonPortable {
    X = 0x1_0000_0000,
    Y = 0,
}
pub enum Foo { //VIOLAZ
    Bar,
    Baz
}

#[non_exhaustive]
pub enum Foo {  //OK
    Bar,
    Baz
}

pub struct Foo { //VIOLAZ
    bar: u8,
    baz: String,
}

#[non_exhaustive]
pub struct Foo {
    bar: u8,
    baz: String,
}


async fn foo(x: &Mutex<u32>) {  //VIOLAZ
  let guard = x.lock().unwrap();
  *guard += 1;
  bar.await;
  
}
…
async fn foo(x: &Mutex<u32>) { //OK ci sono le graffe, sono considerati due blocchi diversi
  {
    let guard = x.lock().unwrap();
    *guard += 1;
  }
  bar.await;
}

let _1 = 1;  //VIOLAZ
let __22_1 = 1;  //VIOLAZ
let __1___2 = 11;  //VIOLAZ
let _ = mutex.lock(); //VIOLAZ
let _lock = mutex.lock(); //OK

#[macro_use] //VIOLAZ
use some_macro;

fn main() {
    main();  //VIOLAZ
}

fn main() {
   #![no_std]
    main();  //OK
	
	match arr[idx] {   //VIOLAZ
    0 => println!("{}", 0),
    1 => println!("{}", 3),
    _ => {},
}

match arr.get(idx) {  //OK
    Some(0) => println!("{}", 0),
    Some(1) => println!("{}", 3),
    _ => {},
}

}

async fn foo(x: &Mutex<u32>) {  //VIOLAZ
  {
    let guard = x.lock().unwrap();
    *guard += 1;
	dbg!;
	debug_assert!(take_a_mut_parameter(&mut 5));
	const CONST_ATOM: AtomicUsize = AtomicUsize::new(12);
	static STATIC_ATOM: AtomicUsize = AtomicUsize::new(15);  
	let a = f(*&mut b); //VIOLAZ
	let c = *&d; //VIOLAZ
	std::mem::drop(&lock_guard) //VIOLAZ
	let x: LinkedList<usize> = LinkedList::new();  //VIOLAZ
	loop {}
	for x in (0..100).step_by(0) {  //VIOLAZ
		println!("{}", x);
	}

  }
}

async fn foo(x: &RefCell<u32>) { //VIOLAZ la await è nel blocco principale
  let mut y = x.borrow_mut();
  *y += 1;
  bar.await;
}

async fn foo(x: &RefCell<u32>) {  //OK la await è fuori dal blocco
  {
     let mut y = x.borrow_mut();
     *y += 1;
  }
  bar.await;
}

#[inline(always)]
fn inlined(x: u32, y: u32) -> u32 {
   eprintln!("inlined: {} + {}", x, y);
   x + y
 }

trait Animal {
    #[inline]
    fn name(&self) -> &'static str;   //VIOLAZ, senza {}
	unsafe { std::slice::from_raw_parts(ptr::null(), 0); } //VIOLAZ
}


let x = async {  //OK c’è la await
    foo().await
};

async fn foo(x: &Mutex<u32>) {  //OK c’è la await
  {
    let guard = x.lock().unwrap();
    *guard += 1;
  }
  bar.await;
}

fn main() {
    // VIOLAZ
    foo::r#try();
	if let Ok(thing) = mutex.lock() {
    do_thing();
		} else {
			mutex.lock();  //VIOLAZ
		}

}


#[link(name = "m")]
// VIOLAZ
extern {
    // this is a foreign function
    // that computes the square root of a single precision complex number
    fn csqrtf(z: Complex) -> Complex;

    fn ccosf(z: Complex) -> Complex;
}
// VIOLAZ
extern crate foo;
// VIOLAZ
pub unsafe extern fn fgets(buf: *mut c_char, n: c_int, stream: *mut FILE) -> *mut c_char


let raw_p: *const u32 = &10;

    unsafe {
        // OK
        assert!(*raw_p == 10);
		
		if s == "" {  //VIOLAZ
		}
	if arr == [] {  //VIOLAZ
		}
		if x.len() == 0 { //VIOLAZ
	}
	if y.len() != 0 { //VIOLAZ
	}

    }
// VIOLAZ
        assert!(*raw_p == 10);

let some_vector = vec![1, 2, 3, 4];

    let pointer = some_vector.as_ptr();
    let length = some_vector.len();

	unsafe{    
	}
	
    unsafe {
        // OK
        let my_slice: &[u32] = slice::from_raw_parts(pointer, length);
		let x = 3.14; //VIOLAZ
		let y = 1_f64 / x;  //VIOLAZ
		assert!(true);
        assert_eq!(some_vector.as_slice(), my_slice);
    }
	
	if (a==1) {
		
	}
// VIOLAZ
let my_slice: &[u32] = slice::from_raw_parts(pointer, length);

//EmptyEnumRust
enum Foo {}

async fn foo(x: &RefCell<u32>) { //VIOLAZ la await è nel blocco principale
  let mut y = x.borrow_mut();
  *y += 1;
  bar.await;
}

async fn foo(x: &RefCell<u32>) {  //OK la await è fuori dal blocco
  {
     let mut y = x.borrow_mut();
     *y += 1;
  }
  bar.await;
}

fn main() {
    // Connect to a database.
	//VIOLAZ HardcodedCredentials
    let conn = oracle::Connection::new("scott", "tiger", "//localhost/XE").unwrap();
    // Select a table with a bind variable.
    let mut stmt = conn.execute("select ename, sal, comm from emp where deptno = :1", &[&30]).unwrap();
	//VIOLAZ SQLInjectionCORust
	let SQLInjectionCORust = conn.execute("SELECT * FROM members WHERE username = 'admin'--' AND password = 'password'");
	//SQLInjectionSSRust 
	let SQLInjectionSSRust = conn.execute("SELECT * FROM members WHERE username 1=1");
	//SQLInjectionIFRust  
	let SQLInjectionIFRust = conn.execute("SELECT * FROM members WHERE username ;if");
	//SQLInjectionIntRust  
	let SQLInjectionIntRust = conn.execute("SELECT * FROM members WHERE username = 0x45");	
	//	SQLInjectionSORust
	let SQLInjectionSORust = conn.execute("SELECT * FROM members WHERE username = ASCII(65)");	
	//SQLInjectionCMDRust
	let SQLInjectionCMDRust = conn.execute("DELETE * FROM members WHERE username = xp_regaddmultistring");	
	//SQLInjectionCCRust
	let SQLInjectionCCRust = conn.execute(";DELETE * FROM members WHERE username = xp_regaddmultistring");	
    // Print column names
    for info in stmt.column_info() {
        print!(" {:14}|", info.name());
    }
    println!("");

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