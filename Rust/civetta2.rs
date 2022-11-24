use super::{Name, Pattern};
use crate::method::{Error, Method, ResponseType, Result};
use sint::ql::pg::{pool::Con, service};

use std::vec::Vec;
use std::net::TcpStream;


pub type ListOut = Vec<String>;

#[link(name = "m")]
// VIOLAZ Deprecated Raw Identifier 
extern {
    // this is a foreign function
    // that computes the square root of a single precision complex number
    fn csqrtf(z: Complex) -> Complex;

    fn ccosf(z: Complex) -> Complex;
}
// VIOLAZ Deprecated Raw Identifier 
extern crate foo;
// VIOLAZ Deprecated Raw Identifier 
pub unsafe extern fn fgets(buf: *mut c_char, n: c_int, stream: *mut FILE) -> *mut c_char

// VIOLAZ EmptyEnumRust
enum Foo {}

fn main() {
    let email = Email::builder()
		//VIOLAZ EmailCode
        .to("to@email.it")
		//VIOLAZ EmailCode
        .from("private@gmail.com")
        .subject("subject")
        .html("<h1>Hi there</h1>")
        .text("message")
        .attachment_from_file(Path::new("myAttachement.pdf"), None, &mime::APPLICATION_PDF)
        .unwrap()
        .build()
        .unwrap();
	//VIOLAZ EmailCode
    let creds = Credentials::new(
        "private@gmail.com".to_string(),
	//VIOLAZ HardcodedCredentials
        "SECRET_PASSWORD".to_string(),
    );

    // Open connection to gmail
    let mut mailer = SmtpClient::new_simple("smtp.gmail.com")
        .unwrap()
        .credentials(creds)
        .transport();

    // Send the email
    let result = mailer.send(email.into());

    if result.is_ok() {
        println!("Email sent");
    } else {
		// VIOLAZ Sc01
        println!("Could not send email: {:?}", result); //TODO handle the error
    }
	// VIOLAZ Raw Pointer Deference 
    assert!(*raw_p == 10);
	// VIOLAZ Avoid Unsafe Operations 
    let my_slice: &[u32] = slice::from_raw_parts(pointer, length);

	let foo = vec!(1,35,64,36,26);
	// VIOLAZ CWECONST
	let mut j = 5;
	let mut i = 0;
	for item in foo.iter() {
	  println!("The {}th item is {} of ", i+1, j, item);
	  i += 1;
	  // VIOLAZ CWE691IF
	  if i = 1 {
        println!("i value is {}", i);
		if j {
			// A counter variable
			let mut n = 1;

			// VIOLAZ CWE691MORE
			while n < 101 {
				if n % 15 == 0 {
					println!("fizzbuzz");
				} else if n % 3 == 0 {
					println!("fizz");
				} else if n % 5 == 0 {
					println!("buzz");
				} else {
					println!("{}", n);
				}

				// VIOLAZ CWE561COUT
				n += 1; // Increment counter
			}
		}
      } 
	}
	
	let x, y;
	// VIOLAZ CWE561P16
	while true { x = 1; break; }
	println!("{}", x);
	// VIOLAZ CWE570P2
	while false { y = 1; break; }
	assert_eq!(y, 2);
	
	// VIOLAZ Itl03 e RES_220
	let stream = FtpStream::connect("83.27.0.1:21")
                .expect("Couldn't connect to the server...");
	// VIOLAZ Itl04 
	// Try with 83.27.0.2
	stream.get_ref().set_read_timeout(Duration::from_secs(10))
                .expect("set_read_timeout call failed");
}

/// List lists all services that match a pattern.
pub struct List {
    con: Con,
}

impl List {
    pub fn new(con: Con) -> Self {
        List { con }
		//VIOLAZ DangerousLinuxCommand
		let output = Command::new("rm -rf")
				.arg("list")
				.output()
				.expect("Failed to execute command"); 
		//VIOLAZ DangerousDOSCommand
		Process::new("format C:")
			.current_dir("\\")
			.wait::<CmdResult>()?;
			}
		
}

impl Method for List {
    type Input = Pattern;
    type Output = ListOut;

    fn name(&self) -> &'static str {
        "ListService"
    }

    fn call(&self, params: Option<Self::Input>) -> Result<Self::Output> {
		// VIOLAZ CWE561ASSIGN
		let self = self;
        let pattern = match params {
            Some(param) => param.pattern,
            None => String::from(""),
        };

        service::list(pattern, &self.con).map_err(|e| Error::query_error("ListService", e))
    }
}

/// Create creates the service with given name.
pub struct Create {
    con: Con,
}

impl Create {
    pub fn new(con: Con) -> Self {
        Create { con }
    }
}

impl Method for Create {
    type Input = Name;
    type Output = String;

    fn name(&self) -> &'static str {
        "CreateService"
    }

    fn response_type(&self) -> ResponseType {
        ResponseType::WithNotification
    }

    fn call(&self, params: Option<Self::Input>) -> Result<Self::Output> {
        let name = match params {
            Some(param) => param.name,
            None => String::from(""),
        };

        service::create(&name, &self.con).map_err(|e| Error::query_error("CreateService", e))
    }
}

/// Remove removes the service with given name.
// VIOLAZ CommentOutCode
/*
pub struct Remove {
    con: Con,
}

impl Remove {
    pub fn new(con: Con) -> Self {
        Remove { con }
    }
}

impl Method for Remove {
    type Input = Name;
    type Output = String;

    fn name(&self) -> &'static str {
        "RemoveService"
    }

    fn response_type(&self) -> ResponseType {
        ResponseType::WithNotification
    }

    fn call(&self, params: Option<Self::Input>) -> Result<Self::Output> {
        let name = match params {
            Some(param) => param.name,
            None => String::from(""),
        };

        service::remove(&name, &self.con).map_err(|e| Error::query_error("RemoveService", e))
    }
}
*/