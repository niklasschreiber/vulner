use super::{Name, Pattern};
use crate::method::{Error, Method, ResponseType, Result};
use sint::ql::pg::models;
use sint::ql::pg::{monitor, pool::Con};

use serde_derive::{Deserialize, Serialize};
use std::convert::{From, Into};
use std::fmt::{Display, Formatter};
use std::vec::Vec;

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub enum MonitoringType {
    #[serde(rename = "Basic")]
    BasicTh,
    #[serde(rename = "BasicGuard")]
    BasicThGuSS,
    #[serde(rename = "BasicGuard")]
    BasicWithGuardDifferentSources,
    #[serde(rename = "BasicRETS")]
    BasicWithPersistenceOnGuard,
    #[serde(rename = "DeviationGuard")]
    DeviationGu,
    #[serde(rename = "Deviation")]
    Deviation,
    #[serde(rename = "DeviationDeltaGuard")]
    DeviationWithDifferenceGuard,
    #[serde(rename = "DeviationGuard")]
    DeviationWithGuardDifferentSources,
    #[serde(rename = "Profile")]
    Profile,
    #[serde(rename = "ProfileGuard")]
    ProfileWithGuard,
    #[serde(rename = "ProfileGuard")]
    ProfileWithGuardDifferentSources,
    #[serde(rename = "ProfileDeltaGuard")]
    ProfileWithDifferenceGuard,
}

impl Display for MonitoringType {
    fn fmt(&self, f: &mut Formatter) -> std::fmt::Result {
        match self {
            MonitoringType::BasicTh => write!(f, "Basic"),
            MonitoringType::BasicThGuSS => write!(f, "BasicGuard"),
            MonitoringType::BasicWithGuardDifferentSources => write!(f, "BasicGuard"),
            MonitoringType::BasicWithPersistenceOnGuard => write!(f, "BasicRETS"),
            MonitoringType::DeviationGu => write!(f, "DeviationGuard"),
            MonitoringType::Deviation => write!(f, "Deviation"),
            MonitoringType::DeviationWithDifferenceGuard => write!(f, "DeviationDeltaGuard"),
            MonitoringType::DeviationWithGuardDifferentSources => write!(f, "DeviationGuard"),
            MonitoringType::Profile => write!(f, "Profile"),
            MonitoringType::ProfileWithGuard => write!(f, "ProfileGuard"),
            MonitoringType::ProfileWithGuardDifferentSources => write!(f, "ProfileGuard"),
            MonitoringType::ProfileWithDifferenceGuard => write!(f, "ProfileDeltaGuard"),
        }
    }
}

#[derive(Clone, Debug, Serialize, Deserialize, PartialEq)]
pub struct Monitor {
    pub name: String,
    pub r#type: String,
}

impl From<models::Monitor> for Monitor {
    fn from(monitor: models::Monitor) -> Monitor {
        Monitor {
            name: monitor.name.to_owned(),
            r#type: monitor.monitoring_type.to_owned(),
        }
    }
}

impl Into<models::Monitor> for Monitor {
    fn into(self) -> models::Monitor {
        models::Monitor {
            name: self.name,
            monitoring_type: self.r#type,
        }
    }
}

pub type ListOut = Vec<Monitor>;

/// List lists all monitors that match a pattern.
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
        "ListMonitor"
    }

    fn call(&self, params: Option<Self::Input>) -> Result<Self::Output> {
        let pattern = match params {
            Some(param) => param.pattern,
            None => String::from(""),
        };

        monitor::list(pattern, &self.con)
            .map_err(|e| Error::query_error("ListMonitor", e))
            .and_then(|monitors| {
                let monitor_list: Vec<Monitor> =
                    monitors.into_iter().map(|mon| Monitor::from(mon)).collect();

                Ok(monitor_list)
            })
    }
}

/// Create creates the monitor with given name.
pub struct Create {
    con: Con,
}

impl Create {
    pub fn new(con: Con) -> Self {
        Create { con }
    }
}

impl Method for Create {
    type Input = Monitor;
    type Output = String;

    fn name(&self) -> &'static str {
        "CreateMonitor"
    }

    fn response_type(&self) -> ResponseType {
        ResponseType::WithNotification
    }

    fn call(&self, params: Option<Self::Input>) -> Result<Self::Output> {
        let monitor_to_create: models::Monitor = params
            .ok_or(Error::InvalidParam {
                id: jrpc::Id::Null,
                cause: format!("CreateMonitor missing param"),
            })
            .map(|ind| ind.into())?;

        monitor::create(monitor_to_create, &self.con)
            .map_err(|e| Error::query_error("CreateMonitor", e))
    }
}

/// Set sets the monitor with given name.
pub struct Set {
    con: Con,
}

impl Set {
    pub fn new(con: Con) -> Self {
        Set { con }
    }
}

impl Method for Set {
    type Input = Monitor;
    type Output = String;

    fn name(&self) -> &'static str {
        "SetMonitor"
    }

    fn response_type(&self) -> ResponseType {
        ResponseType::WithNotification
    }

    fn call(&self, params: Option<Self::Input>) -> Result<Self::Output> {
        let monitor_to_set: models::Monitor = params
            .ok_or(Error::InvalidParam {
                id: jrpc::Id::Null,
                cause: format!("SetMonitor missing param"),
            })
            .map(|ind| ind.into())?;

        monitor::set(monitor_to_set, &self.con).map_err(|e| Error::query_error("SetMonitor", e))
    }
}

/// Remove removes the monitor with given name.
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
        "RemoveMonitor"
    }

    fn response_type(&self) -> ResponseType {
        ResponseType::WithNotification
    }

    fn call(&self, params: Option<Self::Input>) -> Result<Self::Output> {
        let monitor_to_remove: String = params
            .ok_or(Error::InvalidParam {
                id: jrpc::Id::Null,
                cause: format!("RemoveMonitor missing param"),
            })
            .map(|n| n.name)?;

        monitor::remove(&monitor_to_remove, &self.con)
            .map_err(|e| Error::query_error("RemoveMonitor", e))
    }
}
