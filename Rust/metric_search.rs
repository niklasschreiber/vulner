use diesel::prelude::*;

use super::models::{MetricRow, Mo};
use super::pool::Con;
use super::schema;

use std::collections::BTreeMap;
use std::rc::Rc;
use std::vec::Vec;

use crate::{Error, Result};

use bytes::{Buf, BytesMut, IntoBuf};

use chrono::prelude::*;
use chrono::Local;

pub fn search(
    from_timestamp: i64,
    to_timestamp: Option<i64>,
    mo_dn_pattern: &str,
    con: &Con,
) -> Result<MetricDF> {
    let mut metric_df = MetricDF::new();

    let indicators_map: BTreeMap<i16, String> = {
        use schema::indicator::dsl::*;

        let ind_list = indicator
            .select((id, name))
            .order(id.asc())
            .load::<(i16, String)>(con)
            .map_err(|e| Error::db_error("metric search indicators query", e))?;

        ind_list
            .into_iter()
            .fold(BTreeMap::new(), |mut acc, (the_id, the_name)| {
                acc.insert(the_id, the_name.to_owned());

                acc
            })
    };

    let mos = {
        use schema::mo::dsl::*;

        mo.filter(dn.ilike(&format!("%{}%", mo_dn_pattern)))
            .order(id.asc())
            .load::<Mo>(con)
            .map_err(|e| Error::db_error("metric search MO loading", e))
    }?;

    let metrics = {
        use schema::metric::dsl::*;

        let from_t = Local.timestamp(from_timestamp, 0);
        let to_t = Local.timestamp(to_timestamp.unwrap_or(from_timestamp), 0);

        MetricRow::belonging_to(&mos)
            .filter(time.between(from_t, to_t))
            .load::<MetricRow>(con)
            .map_err(|e| Error::db_error("metric search metric loading", e))?
            .grouped_by(&mos)
    };

    let data = mos.into_iter().zip(metrics).collect::<Vec<_>>();

    for mo_group in data.into_iter() {
        let mo_dn: &str = mo_group.0.dn.as_str();
        for metric_row in mo_group.1.into_iter() {
            metric_df.add_item(mo_dn, &indicators_map, metric_row)?;
        }
    }

    Ok(metric_df)
}

#[derive(Debug)]
pub struct MetricDF {
    // index is a MultiIndex with components:
    // ( time, mo dn, indicator name )
    index: BTreeMap<Rc<(i64, String, String)>, ()>,
    value: BTreeMap<Rc<(i64, String, String)>, f64>,
    profile: BTreeMap<Rc<(i64, String, String)>, f64>,
    completeness: BTreeMap<Rc<(i64, String, String)>, f64>,
}

impl MetricDF {
    pub fn new() -> Self {
        MetricDF {
            index: BTreeMap::new(),
            value: BTreeMap::new(),
            profile: BTreeMap::new(),
            completeness: BTreeMap::new(),
        }
    }

    pub fn add_item(
        &mut self,
        mo_dn: &str,
        indicators: &BTreeMap<i16, String>,
        metric: MetricRow,
    ) -> Result<()> {
        let time: i64 = metric.time.timestamp();

        let vtypes_b = BytesMut::from(metric.vtype);
        // we need to divide by 2 because len counts Bytes, but
        // our values in vtype are 2 bytes long.
        let numind = vtypes_b.len() / 2;
        let mut vtypes_buf = vtypes_b.into_buf();

        let mut value_buf = BytesMut::from(metric.value).into_buf();

        let mut profile_buf = match metric.profile {
            Some(v) => Some(BytesMut::from(v).into_buf()),
            None => None,
        };

        let mut completeness_buf = match metric.complete {
            Some(v) => Some(BytesMut::from(v).into_buf()),
            None => None,
        };

        for _n in 1..=numind {
            let indicator_id: i16 = vtypes_buf.get_i16_le();
            let indicator_name: String = match indicators.get(&indicator_id) {
                Some(name) => name.to_owned(),
                None => format!("Unknown-ID:{}", indicator_id),
            };

            let value: f64 = value_buf.get_f64_le();

            let profile: f64 = match profile_buf {
                Some(ref mut b) => b.get_f64_le(),
                None => std::f64::NAN,
            };

            let completeness: f64 = match completeness_buf {
                Some(ref mut b) => b.get_f64_le(),
                None => std::f64::NAN,
            };

            let the_index = Rc::new((time, String::from(mo_dn), indicator_name));

            self.index.insert(Rc::clone(&the_index), ());
            self.value.insert(Rc::clone(&the_index), value);
            self.profile.insert(Rc::clone(&the_index), profile);
            self.completeness
                .insert(Rc::clone(&the_index), completeness);
        }

        Ok(())
    }

    pub fn index(&self) -> Vec<Rc<(i64, String, String)>> {
        self.index.keys().map(|item| Rc::clone(item)).collect()
    }

    pub fn data(&self) -> BTreeMap<String, BTreeMap<Rc<(i64, String, String)>, f64>> {
        let mut data_frame = BTreeMap::new();

        data_frame.insert("value".into(), self.value.clone());
        data_frame.insert("profile".into(), self.profile.clone());
        data_frame.insert("completeness".into(), self.completeness.clone());
        data_frame
    }
}
