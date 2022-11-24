use super::schema::{
    attribute, filter, guard, indicator, instance, master, metric, mo, monitor, service,
};

use chrono::prelude::*;

use std::convert::From;

#[derive(Identifiable, Queryable, PartialEq, Debug)]
#[table_name = "service"]
#[primary_key(uri)]
pub struct Service {
    pub uri: String,
}

impl Service {
    pub fn get_name(&self) -> &str {
        self.uri.as_ref()
    }
}

#[derive(Insertable, Queryable, Associations, PartialEq, Debug)]
#[belongs_to(Service, foreign_key = "service_uri")]
#[belongs_to(Indicator, foreign_key = "indicator_name")]
#[table_name = "attribute"]
pub struct Attribute {
    pub label: Option<String>,
    pub unit: Option<String>,
    pub service_uri: String,
    pub indicator_name: String,
}

#[derive(Insertable, Queryable, PartialEq, Debug)]
#[table_name = "indicator"]
pub struct Indicator {
    pub name: String,
    pub description: Option<String>,
}

impl Eq for Indicator {}

#[derive(Identifiable, Insertable, Queryable, PartialEq, Debug)]
#[table_name = "monitor"]
#[primary_key(name)]
pub struct Monitor {
    pub name: String,
    pub monitoring_type: String,
}

impl Eq for Monitor {}

#[derive(Identifiable, Insertable, Queryable, Associations, PartialEq, Debug)]
#[belongs_to(Monitor, foreign_key = "monitor_name")]
#[belongs_to(Service, foreign_key = "service_uri")]
#[table_name = "filter"]
pub struct Filter {
    id: i32,
    pub kind: String,
    pub value: String,
    pub monitor_name: String,
    pub service_uri: String,
}

#[derive(Insertable, Queryable, AsChangeset, PartialEq, Debug)]
#[table_name = "filter"]
pub struct FilterEntry {
    pub kind: String,
    pub value: String,
    pub monitor_name: String,
    pub service_uri: String,
}

impl Filter {
    pub fn is_equal_to(&self, kind: &str, value: &str) -> bool {
        if self.value != String::from(value) {
            return false;
        }

        if self.kind != String::from(kind) {
            return false;
        }

        return true;
    }
}

#[derive(Identifiable, Insertable, Queryable, Associations, PartialEq, Debug)]
#[belongs_to(Indicator, foreign_key = "indicator_name")]
#[belongs_to(Monitor, foreign_key = "monitor_name")]
#[belongs_to(Service, foreign_key = "service_uri")]
#[table_name = "master"]
pub struct Master {
    id: i32,
    pub enabled: bool,
    pub operator: String,
    pub critical: Option<String>,
    pub major: Option<String>,
    pub minor: Option<String>,
    pub warning: Option<String>,
    pub cleared: Option<String>,
    pub rops_alarmed: String,
    pub interval: i32,
    pub deviation_window: Option<f64>,
    pub hysteresis_factor: Option<f64>,
    pub indicator_exposed: Option<String>,
    pub indicator_name: String,
    pub monitor_name: String,
    pub service_uri: String,
}

#[derive(Insertable, Queryable, AsChangeset, PartialEq, Debug)]
#[table_name = "master"]
pub struct MasterEntry {
    pub enabled: bool,
    pub operator: String,
    pub critical: Option<String>,
    pub major: Option<String>,
    pub minor: Option<String>,
    pub warning: Option<String>,
    pub cleared: Option<String>,
    pub rops_alarmed: String,
    pub interval: i32,
    pub deviation_window: Option<f64>,
    pub hysteresis_factor: Option<f64>,
    pub indicator_exposed: Option<String>,
    pub indicator_name: String,
    pub monitor_name: String,
    pub service_uri: String,
}

#[derive(Identifiable, Insertable, Queryable, Associations, PartialEq, Debug)]
#[belongs_to(Indicator, foreign_key = "indicator_name")]
#[belongs_to(Monitor, foreign_key = "monitor_name")]
#[belongs_to(Service, foreign_key = "service_uri")]
#[table_name = "guard"]
pub struct Guard {
    id: i32,
    pub operator: String,
    pub threshold: String,
    pub rops_alarmed: String,
    pub indicator_exposed: Option<String>,
    pub indicator_name: String,
    pub monitor_name: String,
    pub service_uri: String,
}

#[derive(Insertable, Queryable, AsChangeset, PartialEq, Debug)]
#[table_name = "guard"]
pub struct GuardEntry {
    pub operator: String,
    pub threshold: String,
    pub rops_alarmed: String,
    pub indicator_exposed: Option<String>,
    pub indicator_name: String,
    pub monitor_name: String,
    pub service_uri: String,
}

#[derive(Identifiable, Insertable, Queryable, PartialEq, Debug)]
#[table_name = "instance"]
#[primary_key(mo, service_class)]
pub struct Instance {
    pub name: String,
    pub mo: String,
    pub service_class: String,
    pub tag: Option<String>,
    pub enabled: bool,
    pub type_: String,
}

impl Eq for Instance {}

#[derive(Identifiable, Insertable, Queryable, PartialEq, Debug)]
#[table_name = "mo"]
pub struct Mo {
    pub id: i32,
    pub dn: String,
}

impl Eq for Mo {}

#[derive(Insertable, PartialEq, Debug)]
#[table_name = "metric"]
pub struct Metric {
    time: DateTime<Local>,
    rop: i16,
    mo_id: i32,
    origin_id: i32,
    vtype: Vec<u8>,
    value: Vec<u8>,
    complete: Option<Vec<u8>>,
}

impl Eq for Metric {}

impl Metric {
    pub fn new(
        timestamp: i64,
        rop: i16,
        nid: i32,
        oid: i32,
        vtypes: &[i16],
        values: &[f64],
    ) -> Self {
        use bytes::{Buf, BufMut, BytesMut, IntoBuf};

        let t = Local.timestamp(timestamp, 0);

        let mut typs: BytesMut = BytesMut::with_capacity(vtypes.len() * 2);
        for vt in vtypes.into_iter() {
            typs.put_i16_le(*vt);
        }

        let ts: Vec<u8> = typs.into_buf().collect();

        let mut vals: BytesMut = BytesMut::with_capacity(values.len() * 8);
        for vs in values.into_iter() {
            vals.put_f64_le(*vs);
        }

        let vs: Vec<u8> = vals.into_buf().collect();

        Metric {
            time: t,
            rop: rop,
            mo_id: nid,
            origin_id: oid,
            vtype: ts,
            value: vs,
            complete: None,
        }
    }

    pub fn completeness(self, complete: &[f64]) -> Self {
        use bytes::{Buf, BufMut, BytesMut, IntoBuf};

        let mut comps: BytesMut = BytesMut::with_capacity(complete.len() * 8);
        for c in complete.into_iter() {
            comps.put_f64_le(*c);
        }

        let cs: Vec<u8> = comps.into_buf().collect();

        Metric {
            complete: Some(cs),
            ..self
        }
    }
}

#[derive(Identifiable, Queryable, Associations, PartialEq, Debug)]
#[belongs_to(Mo, foreign_key = "mo_id")]
#[table_name = "metric"]
#[primary_key(time, mo_id, origin_id)]
pub struct MetricRow {
    pub time: DateTime<Utc>,
    pub rop: i16,
    pub mo_id: i32,
    pub origin_id: i32,
    pub vtype: Vec<u8>,
    pub value: Vec<u8>,
    pub complete: Option<Vec<u8>>,
    pub profile: Option<Vec<u8>>,
    pub outliers: Option<Vec<u8>>,
}
