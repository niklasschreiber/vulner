mod dataframe;
pub mod instance;
pub mod metric;

pub use dataframe::has_multiindex_columns;

use pyo3::prelude::*;

use std::collections::BTreeMap;
use std::convert::{TryFrom, TryInto};
use std::sync::Mutex;

use log::{info, warn};

use sint::ql::pg::metric::{store, Builder, RawMetric};
use sint::Error;

/// process function processes the given dataframe df.
/// Processing steps are:
/// - managed object cache checking and updating
/// - loading data, extracted from df, in the origin and metric tables
/// - updating df with profile values, if set_profile is True.
pub fn process(df: PyObject, set_profile: bool) -> PyResult<()> {
    use lazy_static::lazy_static;

    lazy_static! {
        /// managed object cache: maps mo dn to mo id
        static ref MO_CACHE: Mutex<BTreeMap<String, i32>> = Mutex::new(BTreeMap::new());
    }

    let mut cache = MO_CACHE.lock().map_err(|e| {
        PyErr::from(Error::generic(&format!(
            "unable to change mo cache|{:?}",
            e
        )))
    })?;

    Loader::new(&df, &mut cache, set_profile)
        .update_mo_cache()?
        .load()?
        .done()
}

/// Loader
struct Loader<'a> {
    data_frame: &'a PyObject,
    cache: &'a mut BTreeMap<String, i32>,
    set_profile: bool,
}

impl<'a> Loader<'a> {
    pub fn new(
        df: &'a PyObject,
        cache: &'a mut BTreeMap<String, i32>,
        set_profile: bool,
    ) -> Loader<'a> {
        Loader {
            data_frame: df,
            cache,
            set_profile,
        }
    }

    pub fn load(&self) -> PyResult<&'a Loader> {
        let mut builder: Builder = self.try_into()?;
        let con = &super::get_db_connection()?;

        let max_retries = 3;
        for n in 0..max_retries - 1 {
            if n != 0 {
                info!("{} load retry", n);
            }
            match store(&mut builder, con) {
                Ok(_) => {
                    return {
                        if self.set_profile {
                            let profile_for_indicators = builder.profiles();
                            for (indicator_name, profile_dict) in profile_for_indicators.iter() {
                                dataframe::set_profile(
                                    self.data_frame,
                                    indicator_name,
                                    profile_dict,
                                )?;
                            }
                        }
                        Ok(&self)
                    }
                }
                Err(e) => {
                    let msg: String = format!("{}", e);
                    info!("load error {:?}", &msg);
                    if !msg.contains("deadlock detected") {
                        return Err(PyErr::from(e));
                    }
                }
            }
            let sleep_sec = max_retries * n + 1;
            info!(
                "database deadlock detected: retry load in {} seconds...",
                sleep_sec
            );
            std::thread::sleep(std::time::Duration::from_secs(sleep_sec));
        }

        Err(PyErr::from(Error::generic(
            "deadlock detected for 3 retries",
        )))
    }

    pub fn update_mo_cache(&mut self) -> PyResult<&'a Loader> {
        use sint::ql::pg::mo::store;

        let indices = dataframe::Index::try_from(self.data_frame)?;

        let unknown_indices: Vec<String> = indices
            .values()
            .iter()
            .map(|mo_dn_str| String::from(mo_dn_str.as_str()))
            .filter(|mo_dn| !self.cache.contains_key(mo_dn))
            .collect();

        let mut new_cache_chunk = store(&unknown_indices, &super::get_db_connection()?)?;
        self.cache.append(&mut new_cache_chunk);

        Ok(self)
    }

    pub fn done(&self) -> PyResult<()> {
        Ok(())
    }
}

impl<'a> TryInto<Builder> for &'a Loader<'a> {
    type Error = PyErr;

    fn try_into(self) -> std::result::Result<Builder, Self::Error> {
        let indicators = dataframe::Indicators::try_from(self.data_frame)?;
        let metainfo = dataframe::Metainfo::try_from(self.data_frame)?;
        let values = dataframe::Values::try_from(self.data_frame)?;
        let inames = indicators.names();

        let mut metrics: BTreeMap<(i32, i64), RawMetric> = BTreeMap::new();

        let df_stime: i64 = metainfo.stime as i64;

        for row in values.rows().into_iter() {
            let mo_dn = row.index();
            let mo_id: i32;
            match self.cache.get(&mo_dn) {
                Some(id) => mo_id = *id,
                None => {
                    warn!("Id not found in MO cache for {}", mo_dn);
                    continue;
                }
            }

            let vals = row.extract(inames.as_slice(), format!("value"));
            let comps = row.extract(inames.as_slice(), format!("completeness"));

            let row_stime: Option<f64> = row.source_time();

            metrics.insert(
                (
                    mo_id,
                    row_stime.map(|v| v as i64).unwrap_or(df_stime as i64),
                ),
                RawMetric::new((mo_dn, mo_id), vals, Vec::new(), comps).with_stime(row_stime),
            );
        }

        Ok(Builder::new(
            df_stime,
            metainfo.rop.unwrap_or(15.0) as i16,
            metainfo.origin,
            indicators.header(),
            indicators.ids(),
            indicators.id2name(),
            metrics,
        ))
    }
}
