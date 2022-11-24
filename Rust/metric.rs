use crate::method::{Error, Method, Result};
use sint::ql::pg::{metric_search, pool::Con};

use serde_derive::{Deserialize, Serialize};
use std::collections::BTreeMap;
use std::vec::Vec;

#[derive(Clone, Debug, Serialize, Deserialize, PartialEq)]
pub struct MetricFilter {
    from_timestamp: i64,
    to_timestamp: Option<i64>,
    mo_dn_pattern: Option<String>,
}

#[derive(Debug, Serialize, Deserialize, PartialEq)]
pub struct Row {
    time: i64,
    mo_dn: String,
    indicator: String,
    value: f64,
    profile: Option<f64>,
    completeness: Option<f64>,
}

pub type SearchOut = Vec<Row>;

/// Search lists all metric that match passed filter.
pub struct Search {
    con: Con,
}

impl Search {
    pub fn new(con: Con) -> Self {
        Search { con }
    }
}

impl Method for Search {
    type Input = MetricFilter;
    type Output = SearchOut;

    fn name(&self) -> &'static str {
        "SearchMetric"
    }

    fn call(&self, params: Option<Self::Input>) -> Result<Self::Output> {
        let metric_filter: MetricFilter = params.ok_or(Error::InvalidParam {
            id: jrpc::Id::Null,
            cause: format!("SearchMetric missing param"),
        })?;

        metric_search::search(
            metric_filter.from_timestamp,
            metric_filter.to_timestamp,
            &metric_filter.mo_dn_pattern.unwrap_or(String::from("")),
            &self.con,
        )
        .map_err(|e| Error::query_error("SearchMetric", e))
        .and_then(|metric_df| {
            let indexes = metric_df.index();
            let data = metric_df.data();

            let empty_map = BTreeMap::new();

            let values = data.get(&String::from("value")).unwrap_or(&empty_map);
            let profiles = data.get(&String::from("profile")).unwrap_or(&empty_map);
            let complete = data
                .get(&String::from("completeness"))
                .unwrap_or(&empty_map);

            let mut rows = Vec::new();

            for index in indexes {
                let value = values.get(&index).unwrap_or(&std::f64::NAN);
                let profile = profiles.get(&index).map(|v| *v);
                let completeness = complete.get(&index).map(|v| *v);
                let (time, mo_dn, indicator) = &*index;

                let row = Row {
                    time: *time,
                    mo_dn: mo_dn.to_owned(),
                    indicator: indicator.to_owned(),
                    value: *value,
                    profile,
                    completeness,
                };

                rows.push(row);
            }

            Ok(rows)
        })
    }
}
