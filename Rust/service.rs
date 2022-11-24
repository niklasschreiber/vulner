use super::{Name, Pattern};
use crate::method::{Error, Method, ResponseType, Result};
use sint::ql::pg::{pool::Con, service};

use std::vec::Vec;

pub type ListOut = Vec<String>;

/// List lists all services that match a pattern.
pub struct List {
    con: Con,
}

impl List {
    pub fn new(con: Con) -> Self {
        List { con }
    }
}

impl Method for List {
    type Input = Pattern;
    type Output = ListOut;

    fn name(&self) -> &'static str {
        "ListService"
    }

    fn call(&self, params: Option<Self::Input>) -> Result<Self::Output> {
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
