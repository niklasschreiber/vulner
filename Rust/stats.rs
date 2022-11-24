use crate::method::{Error, Method, Result};
use sint::ql::pg::{pool::Con, stats};

use serde_derive::{Deserialize, Serialize};

#[derive(Clone, Debug, Serialize, Deserialize, PartialEq)]
pub struct ROPStats {
    rop: Option<String>,
    total_mo: usize,
    kpi: usize,
}

/// Stats create some statistics information about last ROP activities.
pub struct Stats {
    con: Con,
}

impl Stats {
    pub fn new(con: Con) -> Self {
        Stats { con }
    }
}

impl Method for Stats {
    type Input = ();
    type Output = ROPStats;

    fn name(&self) -> &'static str {
        "LastROPStats"
    }

    fn call(&self, _params: Option<Self::Input>) -> Result<Self::Output> {
        let rop = stats::max_time_on_metric(&self.con)
            .map_err(|e| Error::query_error("LastROPStats", e))?;

        let total_mo =
            stats::count_mo(&self.con).map_err(|e| Error::query_error("LastROPStats", e))?;

        match rop {
            Some(last_rop) => {
                let rows_origin = stats::count_metric_row_for_time(last_rop.as_str(), &self.con)
                    .map_err(|e| Error::query_error("LastROPStats", e))?;

                let mut kpi: usize = 0;

                for (origin_id, tot_rows) in rows_origin.into_iter() {
                    let kpi_in_row = stats::count_indicators_in_origin(origin_id, &self.con)
                        .map_err(|e| Error::query_error("LastROPStats", e))?;

                    kpi += tot_rows * kpi_in_row;
                }

                Ok(ROPStats {
                    rop: Some(last_rop),
                    total_mo,
                    kpi,
                })
            }
            None => Ok(ROPStats {
                rop: None,
                total_mo,
                kpi: 0,
            }),
        }
    }
}
