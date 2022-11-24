#[macro_use]
extern crate failure;

mod client;
mod handlers;
mod method;
mod rpc;

use pyo3::prelude::*;
use pyo3::wrap_pymodule;

use sint::ql::pg::pool::PostgresPool;
use sint::{Error, Result};

use std::net::IpAddr;
use std::path::Path;
use std::str::FromStr;
use std::sync::Mutex;

use lazy_static::lazy_static;

use log::info;
use log4rs::init_file;

use handlers::RpcHnd;

const LOG_CONF_DEFAULT: &str = "sint-rpc-log.yaml";

fn new_pool() -> Result<PostgresPool> {
    use sint::ql::pg::pool;
    pool::get(&pool::env_conn_string()?)
}

lazy_static! {
    static ref THE_SF: Mutex<Option<ws::Sender>> = Mutex::new(None);
}

#[pyclass]
/// Server is a RPC Server.
pub struct Server {
    /// ip is the IP address where this server is listening for new connection
    /// request. Default is 0.0.0.0
    ip: IpAddr,
    /// port is the IP port where this server bind. Default is 3129.
    port: i32,
}

#[pymethods]
impl Server {
    #[new]
    #[args(addr = "\"0.0.0.0\"", port = 3129)]
    pub fn new(obj: &PyRawObject, addr: &str, port: i32) -> PyResult<()> {
        let ip = IpAddr::from_str(addr)?;

        obj.init(Server { ip, port });

        Ok(())
    }

    #[getter]
    pub fn get_ip(&self) -> PyResult<String> {
        Ok(format!("{}", self.ip))
    }

    #[getter]
    pub fn get_port(&self) -> PyResult<i32> {
        Ok(self.port)
    }

    pub fn shutdown(&self) -> PyResult<()> {
        match THE_SF.lock().unwrap().take() {
            Some(snd) => snd.shutdown().map_err(|e| PyErr::from(Error::from(e))),
            None => {
                info!("");
                Ok(())
            }
        }
    }

    pub fn listen(&mut self) -> PyResult<()> {
        let gil = GILGuard::acquire();
        let py = gil.python();
        use std::thread;

        if THE_SF.lock().unwrap().is_some() {
            return Err(PyErr::from(Error::generic(
                "Server already in listen state",
            )));
        }

        let addr = format!("{}:{}", self.ip, self.port);

        py.allow_threads(move || {
            info!("Start listening...");
            thread::spawn(move || {
                let ws = ws::WebSocket::new(|sender: ws::Sender| {
                    THE_SF.lock().unwrap().get_or_insert(sender.clone());

                    RpcHnd {
                        sender,
                        pool: new_pool().expect("Server services starting error"),
                    }
                })
                .expect("WebSocket building error");

                match ws.listen(addr).map_err(|e| PyErr::from(Error::from(e))) {
                    Err(e) => info!("listening Error occured: {:?}", e),
                    Ok(_) => info!("listening ending OK"),
                };
            });
        });

        Ok(())
    }
}

/// rpc module
/// This module is a python module implemented in Rust.
#[pymodule]
fn rpc(_py: Python, m: &PyModule) -> PyResult<()> {
    use client::*;

    m.add_class::<Server>()?;
    m.add_wrapped(wrap_pymodule!(client))?;

    match logging_subsystem() {
        Err(e) => eprintln!("ql python module init reports: {}", e),
        Ok(_) => (),
    }

    Ok(())
}

fn logging_subsystem() -> Result<()> {
    let sint_conf: String = sint::env::get_conf()?.into();

    {
        let logname = Path::new(&sint_conf).join(LOG_CONF_DEFAULT);

        if let Err(_e) = init_file(&logname, Default::default())
            .map_err(|e| Error::generic(&format!("{} for file {}", e, &logname.display())))
        {
            use log::LevelFilter;
            use log4rs::append::console::ConsoleAppender;
            use log4rs::config::{Appender, Config, Logger, Root};
            use log4rs::encode::pattern::PatternEncoder;
            use log4rs::init_config;
            let stdout = ConsoleAppender::builder()
                .encoder(Box::new(PatternEncoder::new(
                    "[{d(%Y-%m-%d %H:%M:%S,%s)}][{t}][{l}] {m}{n}",
                )))
                .build();

            let config = Config::builder()
                .appender(Appender::builder().build("stdout", Box::new(stdout)))
                .logger(Logger::builder().build("sint", LevelFilter::Info))
                .logger(Logger::builder().build("sint_rpc", LevelFilter::Info))
                .build(Root::builder().appender("stdout").build(LevelFilter::Info))
                .unwrap();

            init_config(config).unwrap();
        }
    }

    Ok(())
}
