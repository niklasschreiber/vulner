use super::Name;
use crate::method::{Error, Method, ResponseType, Result};
use crate::rpc::monitor::Monitor;

use sint::ql::pg::models;
use sint::ql::pg::{pool::Con, rule};

use serde_derive::{Deserialize, Serialize};
use std::collections::BTreeMap;
use std::default::Default;

use log::warn;

#[derive(Debug, Serialize, Deserialize)]
pub struct Master {
    pub operator: String,
    pub enabled: Option<bool>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub critical: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub major: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub minor: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub warning: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub cleared: Option<String>,
    pub rops_alarmed: Option<String>,
    pub interval: Option<i32>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub deviation_window: Option<f64>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub hysteresis_factor: Option<f64>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub indicator_exposed: Option<String>,
    pub indicator_name: String,
}

impl From<models::Master> for Master {
    fn from(m: models::Master) -> Master {
        Master {
            operator: m.operator,
            enabled: Some(m.enabled),
            critical: m.critical,
            major: m.major,
            minor: m.minor,
            warning: m.warning,
            cleared: m.cleared,
            rops_alarmed: Some(m.rops_alarmed),
            interval: Some(m.interval),
            deviation_window: m.deviation_window,
            hysteresis_factor: m.hysteresis_factor,
            indicator_exposed: m.indicator_exposed,
            indicator_name: m.indicator_name,
        }
    }
}

impl Default for Master {
    fn default() -> Self {
        Master {
            operator: String::from(""),
            enabled: Some(false),
            critical: None,
            major: None,
            minor: None,
            warning: None,
            cleared: None,
            rops_alarmed: None,
            interval: None,
            deviation_window: None,
            hysteresis_factor: None,
            indicator_exposed: None,
            indicator_name: String::from(""),
        }
    }
}

#[derive(Debug, Serialize, Deserialize)]
pub struct Guard {
    pub operator: String,
    pub threshold: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub rops_alarmed: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub indicator_exposed: Option<String>,
    pub indicator_name: String,
}

impl From<models::Guard> for Guard {
    fn from(g: models::Guard) -> Guard {
        Guard {
            operator: g.operator,
            threshold: g.threshold,
            rops_alarmed: Some(g.rops_alarmed),
            indicator_exposed: g.indicator_exposed,
            indicator_name: g.indicator_name,
        }
    }
}

#[derive(Debug, Serialize, Deserialize)]
pub struct Filter {
    pub kind: String,
    pub value: String,
}

impl From<models::Filter> for Filter {
    fn from(f: models::Filter) -> Filter {
        Filter {
            kind: f.kind,
            value: f.value,
        }
    }
}

#[derive(Debug, Serialize, Deserialize)]
pub struct MonitorRule {
    pub monitor: Monitor,
    pub master: Master,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub guard: Option<Guard>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub filter: Option<Filter>,
}

impl MonitorRule {
    fn new(monitor: Monitor) -> MonitorRule {
        MonitorRule {
            monitor,
            master: Default::default(),
            guard: None,
            filter: None,
        }
    }
}

#[derive(Debug, Serialize, Deserialize)]
pub struct Rule {
    pub service: String,
    pub monitor: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub master: Option<Master>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub guard: Option<Guard>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub filter: Option<Filter>,
}

impl Rule {
    fn etries(
        self,
    ) -> (
        Option<models::MasterEntry>,
        Option<models::GuardEntry>,
        Option<models::FilterEntry>,
    ) {
        let Rule {
            service,
            monitor,
            master,
            guard,
            filter,
        } = self;

        let master_entry = master.and_then(|rule_master| {
            Some(models::MasterEntry {
                enabled: rule_master.enabled.unwrap_or(true),
                operator: rule_master.operator,
                critical: rule_master.critical,
                major: rule_master.major,
                minor: rule_master.minor,
                warning: rule_master.warning,
                cleared: rule_master.cleared,
                rops_alarmed: rule_master.rops_alarmed.unwrap_or(String::from("1")),
                interval: rule_master.interval.unwrap_or(15),
                deviation_window: rule_master.deviation_window,
                hysteresis_factor: rule_master.hysteresis_factor,
                indicator_exposed: rule_master.indicator_exposed,
                indicator_name: rule_master.indicator_name,
                monitor_name: monitor.to_owned(),
                service_uri: service.to_owned(),
            })
        });

        let guard_entry = guard.and_then(|rule_guard| {
            Some(models::GuardEntry {
                operator: rule_guard.operator,
                threshold: rule_guard.threshold,
                rops_alarmed: rule_guard.rops_alarmed.unwrap_or(String::from("1")),
                indicator_exposed: rule_guard.indicator_exposed,
                indicator_name: rule_guard.indicator_name,
                monitor_name: monitor.to_owned(),
                service_uri: service.to_owned(),
            })
        });

        let filter_entry = filter.and_then(|rule_filter| {
            Some(models::FilterEntry {
                kind: rule_filter.kind,
                value: rule_filter.value,
                monitor_name: monitor,
                service_uri: service,
            })
        });

        (master_entry, guard_entry, filter_entry)
    }
}

// ListOut is a map {<service-uri>: {<monitor-name>: MonitorRule}}
pub type ListOut = BTreeMap<String, BTreeMap<String, MonitorRule>>;

/// List lists all monitor rule that has the given service name (uri).
pub struct List {
    con: Con,
}

impl List {
    pub fn new(con: Con) -> Self {
        List { con }
    }
}

impl Method for List {
    type Input = Name;
    type Output = ListOut;

    fn name(&self) -> &'static str {
        "ListMonitorRule"
    }

    fn call(&self, params: Option<Self::Input>) -> Result<Self::Output> {
        let service_name: String = params
            .ok_or(Error::InvalidParam {
                id: jrpc::Id::Null,
                cause: format!("ListMonitorRule missing param"),
            })
            .map(|n| n.name)?;

        let the_list = rule::list(&service_name, &self.con)
            .map_err(|e| Error::query_error("ListMonitorRule", e))?;

        let mut rules: Self::Output = BTreeMap::new();

        let (monitors, masters, guards, filters) = the_list;

        let monitors_map: BTreeMap<String, Monitor> =
            monitors.into_iter().fold(BTreeMap::new(), |mut a, m| {
                let monitor = Monitor::from(m);
                a.entry(monitor.name.to_owned()).or_insert(monitor);
                a
            });

        for master_model in masters.into_iter().flatten() {
            let service_uri = master_model.service_uri.to_owned();
            let monitor_name = master_model.monitor_name.to_owned();
            let monitor = match monitors_map.get(&monitor_name) {
                Some(mon) => mon,
                None => {
                    warn!("Monitor with name {} not found in list", &monitor_name);
                    warn!(
                        "Master {:?} not included in ListMonitorRule response",
                        &master_model
                    );
                    continue;
                }
            };
            let master = Master::from(master_model);

            let service_entry = rules.entry(service_uri).or_insert(BTreeMap::new());
            let monitor_rule_entry = service_entry
                .entry(monitor_name)
                .or_insert(MonitorRule::new(monitor.clone()));

            monitor_rule_entry.master = master;
        }

        for guard_model in guards.into_iter().flatten() {
            let service_uri = guard_model.service_uri.to_owned();
            let monitor_name = guard_model.monitor_name.to_owned();
            let monitor = match monitors_map.get(&monitor_name) {
                Some(mon) => mon,
                None => {
                    warn!("Monitor with name {} not found in list", &monitor_name);
                    warn!(
                        "Guard {:?} not included in ListMonitorRule response",
                        &guard_model
                    );
                    continue;
                }
            };
            let guard = Guard::from(guard_model);

            let service_entry = rules.entry(service_uri).or_insert(BTreeMap::new());
            let monitor_rule_entry = service_entry
                .entry(monitor_name)
                .or_insert(MonitorRule::new(monitor.clone()));

            monitor_rule_entry.guard = Some(guard);
        }

        for filter_model in filters.into_iter().flatten() {
            let service_uri = filter_model.service_uri.to_owned();
            let monitor_name = filter_model.monitor_name.to_owned();
            let monitor = match monitors_map.get(&monitor_name) {
                Some(mon) => mon,
                None => {
                    warn!("Monitor with name {} not found in list", &monitor_name);
                    warn!(
                        "Filter {:?} not included in ListMonitorRule response",
                        &filter_model
                    );
                    continue;
                }
            };
            let filter = Filter::from(filter_model);

            let service_entry = rules.entry(service_uri).or_insert(BTreeMap::new());
            let monitor_rule_entry = service_entry
                .entry(monitor_name)
                .or_insert(MonitorRule::new(monitor.clone()));

            monitor_rule_entry.filter = Some(filter);
        }

        Ok(rules)
    }
}

/// Create creates the monitor rule with given values.
pub struct Create {
    con: Con,
}

impl Create {
    pub fn new(con: Con) -> Self {
        Create { con }
    }
}

impl Method for Create {
    type Input = Rule;
    type Output = String;

    fn name(&self) -> &'static str {
        "CreateMonitorRule"
    }

    fn response_type(&self) -> ResponseType {
        ResponseType::WithNotification
    }

    fn call(&self, params: Option<Self::Input>) -> Result<Self::Output> {
        let rule_to_create: Rule = params.ok_or(Error::InvalidParam {
            id: jrpc::Id::Null,
            cause: format!("CreateMonitorRule missing param"),
        })?;

        if let Err(e) = eval::check_master(&rule_to_create.master) {
            return Err(Error::InvalidParam {
                id: jrpc::Id::Null,
                cause: format!("On master |{}|", e),
            });
        }

        if let Err(e) = eval::check_guard(&rule_to_create.guard) {
            return Err(Error::InvalidParam {
                id: jrpc::Id::Null,
                cause: format!("On guard |{}|", e),
            });
        }

        let (opt_master, guard, filter) = rule_to_create.etries();

        let master = opt_master.ok_or(Error::InvalidParam {
            id: jrpc::Id::Null,
            cause: format!("CreateMonitorRule missing master param"),
        })?;

        rule::create(master, guard, filter, &self.con)
            .map_err(|e| Error::query_error("CreateMonitorRule", e))
    }
}

/// Set sets the monitor rule with given values.
pub struct Set {
    con: Con,
}

impl Set {
    pub fn new(con: Con) -> Self {
        Set { con }
    }
}

impl Method for Set {
    type Input = Rule;
    type Output = String;

    fn name(&self) -> &'static str {
        "SetMonitorRule"
    }

    fn response_type(&self) -> ResponseType {
        ResponseType::WithNotification
    }

    fn call(&self, params: Option<Self::Input>) -> Result<Self::Output> {
        let rule_to_set: Rule = params.ok_or(Error::InvalidParam {
            id: jrpc::Id::Null,
            cause: format!("SetMonitorRule missing param"),
        })?;

        if let Err(e) = eval::check_master(&rule_to_set.master) {
            return Err(Error::InvalidParam {
                id: jrpc::Id::Null,
                cause: format!("On master |{}|", e),
            });
        }

        if let Err(e) = eval::check_guard(&rule_to_set.guard) {
            return Err(Error::InvalidParam {
                id: jrpc::Id::Null,
                cause: format!("On guard |{}|", e),
            });
        }

        let (master, guard, filter) = rule_to_set.etries();

        rule::set(master, guard, filter, &self.con)
            .map_err(|e| Error::query_error("SetMonitorRule", e))
    }
}

#[derive(Debug, Serialize, Deserialize)]
pub struct ServiceMonitor {
    service: String,
    monitor: String,
}

/// Remove removes the monitor rule with given service uri and monitor name.
pub struct Remove {
    con: Con,
}

impl Remove {
    pub fn new(con: Con) -> Self {
        Remove { con }
    }
}

impl Method for Remove {
    type Input = ServiceMonitor;
    type Output = String;

    fn name(&self) -> &'static str {
        "RemoveMonitorRule"
    }

    fn response_type(&self) -> ResponseType {
        ResponseType::WithNotification
    }

    fn call(&self, params: Option<Self::Input>) -> Result<Self::Output> {
        let monitor_rule_to_remove: ServiceMonitor = params.ok_or(Error::InvalidParam {
            id: jrpc::Id::Null,
            cause: format!("RemoveMonitorRule missing param"),
        })?;

        rule::remove(
            &monitor_rule_to_remove.service,
            &monitor_rule_to_remove.monitor,
            &self.con,
        )
        .map_err(|e| Error::query_error("RemoveMonitorRule", e))
    }
}

/// RemoveGuard removes the guard in the monitor rule with given service uri and
/// monitor name.
pub struct RemoveGuard {
    con: Con,
}

impl RemoveGuard {
    pub fn new(con: Con) -> Self {
        RemoveGuard { con }
    }
}

impl Method for RemoveGuard {
    type Input = ServiceMonitor;
    type Output = String;

    fn name(&self) -> &'static str {
        "RemoveRuleGuard"
    }

    fn response_type(&self) -> ResponseType {
        ResponseType::WithNotification
    }

    fn call(&self, params: Option<Self::Input>) -> Result<Self::Output> {
        let monitor_rule_to_remove: ServiceMonitor = params.ok_or(Error::InvalidParam {
            id: jrpc::Id::Null,
            cause: format!("RemoveRuleGuard missing param"),
        })?;

        rule::remove_guard(
            &monitor_rule_to_remove.service,
            &monitor_rule_to_remove.monitor,
            &self.con,
        )
        .map_err(|e| Error::query_error("RemoveRuleGuard", e))
    }
}

/// RemoveFilter removes the guard in the monitor rule with given service uri and
/// monitor name.
pub struct RemoveFilter {
    con: Con,
}

impl RemoveFilter {
    pub fn new(con: Con) -> Self {
        RemoveFilter { con }
    }
}

impl Method for RemoveFilter {
    type Input = ServiceMonitor;
    type Output = String;

    fn name(&self) -> &'static str {
        "RemoveRuleFilter"
    }

    fn response_type(&self) -> ResponseType {
        ResponseType::WithNotification
    }

    fn call(&self, params: Option<Self::Input>) -> Result<Self::Output> {
        let monitor_rule_to_remove: ServiceMonitor = params.ok_or(Error::InvalidParam {
            id: jrpc::Id::Null,
            cause: format!("RemoveRuleFilter missing param"),
        })?;

        rule::remove_filter(
            &monitor_rule_to_remove.service,
            &monitor_rule_to_remove.monitor,
            &self.con,
        )
        .map_err(|e| Error::query_error("RemoveRuleFilter", e))
    }
}

mod eval {
    use super::{Guard, Master};
    use log::debug;
    use pyo3::prelude::*;
    use pyo3::types::{IntoPyDict, PyDateTime, PyDict, PyString};
    use sint::Result;
    use std::str::FromStr;

    #[macro_export]
    macro_rules! check_threshold {
        ( $( $threshold:expr, $msg:literal ) ? ) => {
            {
                let mut result: sint::Result<()> = Ok(());
                $(
                    if let Some(th) = $threshold {
                        if let Err(_) = f64::from_str(&th) {
                            result = threshold(&th)
                                .map_err(|e| sint::Error::generic(&format!("{} threshold |{}|{}", $msg, &th, e)));
                        }
                    }
                )*
                    result
            }
        };
    }

    pub fn check_master(master_opt: &Option<Master>) -> Result<()> {
        if let Some(master) = master_opt {
            check_threshold!(&master.critical, "Critical")?;
            check_threshold!(&master.major, "Major")?;
            check_threshold!(&master.minor, "Minor")?;
            check_threshold!(&master.warning, "Warning")?;
            check_threshold!(&master.cleared, "Cleared")?;
            check_threshold!(&master.rops_alarmed, "ROP alarmed")?;
        }
        Ok(())
    }

    pub fn check_guard(guard_opt: &Option<Guard>) -> Result<()> {
        if let Some(guard) = guard_opt {
            check_threshold!(&Some(guard.threshold.to_owned()), "Threshold")?;
            check_threshold!(&guard.rops_alarmed, "ROP alarmed")?;
        }
        Ok(())
    }

    fn threshold(threshold_snippet: &str) -> Result<()> {
        use chrono::prelude::*;

        debug!("executing |{}|", threshold_snippet);

        let code = "sint.core.eval_threshold(snippet, ts)";

        let now = Local::now();

        let gil = Python::acquire_gil();
        let py = gil.python();

        let globals = [("sint", py.import("sint")?)].into_py_dict(py);
        let locals = PyDict::new(py);
        locals.set_item(
            "ts",
            PyDateTime::from_timestamp(py, now.timestamp() as f64, None)?,
        )?;
        locals.set_item("snippet", PyString::new(py, threshold_snippet))?;

        py.eval(code, Some(&globals), Some(&locals))
            .map(|res| {
                debug!("execution result |{:?}|", res);
            })
            .map_err(|py_err| sint::Error::from(py_err))
    }
}
