use pyo3::prelude::*;
use pyo3::types::{IntoPyDict, PyDict, PyIterator, PyList, PyTuple};

use sint::Error;
use std::collections::BTreeMap;
use std::convert::TryFrom;
use std::iter::IntoIterator;

use log::{debug, warn};

pub fn has_multiindex_columns(data_frame: &PyObject) -> PyResult<bool> {
    let gil = GILGuard::acquire();
    let py = gil.python();

    let columns_obj = data_frame.getattr(py, "columns")?;
    let class_name: String = get_class_of(&columns_obj)?;

    let has_mi_columns = match class_name.as_str() {
        "MultiIndex" => true,
        "Index" => false,
        cn @ _ => {
            return Err(PyErr::from(Error::generic(&format!(
                "DataFrame columns format {} is not supported",
                cn
            ))))
        }
    };

    Ok(has_mi_columns)
}

fn get_class_of(object: &PyObject) -> PyResult<String> {
    let gil = GILGuard::acquire();
    let py = gil.python();

    let locals = [("obj", object)].into_py_dict(py);
    let object_class_any = py.eval("type(obj).__name__", None, Some(locals))?;
    let object_class: String = FromPyObject::extract(object_class_any)?;

    object_class
        .as_str()
        .split(".")
        .last()
        .map(|s| String::from(s))
        .ok_or(PyErr::from(Error::generic(&format!(
            "PyObject type name {} error",
            &object_class
        ))))
}

fn _gen_index_names(object: &PyObject) -> PyResult<Vec<String>> {
    let gil = GILGuard::acquire();
    let py = gil.python();

    let locals = [("obj", object)].into_py_dict(py);
    let object_class_any = py.eval("'.'.join(list(obj.names))", None, Some(locals))?;
    let object_class: String = FromPyObject::extract(object_class_any)?;

    let names: Vec<String> = object_class
        .as_str()
        .split(".")
        .map(|s| String::from(s))
        .collect();

    Ok(names)
}

#[derive(Debug)]
pub struct Metainfo {
    pub(crate) origin: String,
    pub(crate) stime: f64,
    pub(crate) rop: Option<f64>,
    pub(crate) indicators_map: BTreeMap<String, i16>,
}

impl<'a> TryFrom<&'a PyObject> for Metainfo {
    type Error = PyErr;

    fn try_from(data_frame: &'a PyObject) -> std::result::Result<Metainfo, Self::Error> {
        let gil = GILGuard::acquire();
        let py = gil.python();

        let info_obj = data_frame.getattr(py, "sint_info")?;

        let origin: String = info_obj.getattr(py, "origin")?.extract(py)?;
        let stime: f64 = info_obj.getattr(py, "stime")?.extract(py)?;
        let rop: Option<f64> = info_obj.getattr(py, "rop")?.extract(py)?;

        let imap_obj = info_obj.getattr(py, "indicators_map")?;
        let imap_dict: &PyDict = imap_obj.cast_as(py)?;

        let mut indicators_map: BTreeMap<String, i16> = BTreeMap::new();
        for (ind, idx) in imap_dict.iter() {
            let indicator: String = FromPyObject::extract(ind)?;
            let index: i16 = FromPyObject::extract(idx)?;

            indicators_map.insert(indicator, index);
        }

        Ok(Metainfo {
            origin,
            stime,
            rop,
            indicators_map,
        })
    }
}

#[derive(Debug)]
pub struct Index {
    index_values: Vec<String>,
}

impl Index {
    pub fn values(&self) -> &[String] {
        self.index_values.as_slice()
    }

    fn names_from_index(columns: PyObject) -> PyResult<Vec<String>> {
        let gil = GILGuard::acquire();
        let py = gil.python();

        let mut inames: Vec<String> = Vec::new();

        let list_obj = columns.call_method0(py, "to_list")?;

        let index_list = list_obj.cast_as::<PyList>(py)?;

        for iname in index_list.iter() {
            let index_name: String = FromPyObject::extract(&iname)?;
            inames.push(index_name);
        }

        Ok(inames)
    }

    fn names_from_multi_index(columns: PyObject) -> PyResult<Vec<String>> {
        let gil = GILGuard::acquire();
        let py = gil.python();

        let levels_obj = columns.getattr(py, "levels")?;
        let levels_list = levels_obj.cast_as::<PyList>(py)?;

        let mut inames: Vec<String> = Vec::new();

        let mut found: bool = false;

        for level_any in levels_list.iter() {
            let index_obj = level_any.to_object(py);
            let name_obj = index_obj.getattr(py, "name")?;
            let name: String = name_obj.extract(py)?;

            if let Some(_) = match name.as_str() {
                "dn" | "DN" | "Dn" | "dN" => {
                    found = true;
                    Some(true)
                }
                _ => None,
            } {
                let list_obj = index_obj.call_method0(py, "to_list")?;

                let index_list = list_obj.cast_as::<PyList>(py)?;

                for iname in index_list.iter() {
                    let index_name: String = FromPyObject::extract(&iname)?;
                    inames.push(index_name);
                }
            }
        }

        if !found {
            return Err(PyErr::from(Error::generic(
                "no DN name found in DataFrame index",
            )));
        }

        Ok(inames)
    }
}

impl<'a> TryFrom<&'a PyObject> for Index {
    type Error = PyErr;

    fn try_from(data_frame: &'a PyObject) -> std::result::Result<Index, Self::Error> {
        let gil = GILGuard::acquire();
        let py = gil.python();

        let index_obj = data_frame.getattr(py, "index")?;
        let class_name: String = get_class_of(&index_obj)?;

        let index_values = match class_name.as_str() {
            "MultiIndex" => Index::names_from_multi_index(index_obj)?,
            "Index" => Index::names_from_index(index_obj)?,
            cn @ _ => {
                return Err(PyErr::from(Error::generic(&format!(
                    "DataFrame index format {} is not supported",
                    cn
                ))))
            }
        };

        Ok(Index { index_values })
    }
}

#[derive(Debug, PartialEq, PartialOrd, Ord)]
pub struct Column(Vec<String>);

impl Column {
    pub fn _new(t: &PyTuple) -> PyResult<Self> {
        let mut columns: Vec<String> = Vec::new();

        for any in t.iter() {
            let column: String = FromPyObject::extract(any)?;
            columns.push(column);
        }

        Ok(Column(columns))
    }
}

impl Eq for Column {}

#[derive(Debug)]
pub struct Row {
    index: String,
    stime: Option<f64>,
    cells: BTreeMap<Column, f64>,
}

impl Row {
    pub fn index(&self) -> String {
        self.index.to_owned()
    }

    pub fn extract(&self, names: &[String], subset: String) -> Vec<f64> {
        let mut ret: Vec<f64> = Vec::new();

        for name in names {
            let col = Column(vec![name.to_owned(), subset.to_owned()]);
            match self.cells.get(&col) {
                Some(val) => ret.push(*val),
                None => {
                    debug!("no column {:?} found in row[{}]", col, self.index);
                    ret.push(std::f64::NAN)
                }
            }
        }

        ret
    }

    pub fn source_time(&self) -> Option<f64> {
        self.stime.clone()
    }
}

#[derive(Debug)]
pub struct Values {
    rows: Vec<Row>,
}

impl Values {
    pub fn rows(&self) -> &[Row] {
        self.rows.as_slice()
    }

    fn labels(object: &PyObject) -> PyResult<Vec<String>> {
        let gil = GILGuard::acquire();
        let py = gil.python();

        let class_name: String = get_class_of(&object)?;

        match class_name.as_str() {
            "str" => {
                let name: String = object.extract(py)?;

                Ok(vec![name.to_owned(), String::from("value")])
            }
            "tuple" => {
                let mut names: Vec<String> = Vec::new();
                let tuple_obj: &PyTuple = object.extract(py)?;

                for any in tuple_obj.iter() {
                    let name: String = FromPyObject::extract(any)?;
                    names.push(name);
                }

                Ok(names)
            }
            cn @ _ => {
                return Err(PyErr::from(Error::generic(&format!(
                    "DataFrame values index format {} is not supported",
                    cn
                ))))
            }
        }
    }

    fn row_index(object: &PyObject) -> PyResult<(Option<String>, Option<f64>)> {
        let gil = GILGuard::acquire();
        let py = gil.python();

        let class_name: String = get_class_of(&object)?;

        match class_name.as_str() {
            "str" => {
                let name: String = object.extract(py)?;

                Ok((Some(name.to_owned()), None))
            }
            "tuple" => {
                let tuple_obj: &PyTuple = object.extract(py)?;
                let mut the_index: (Option<String>, Option<f64>) = (None, None);

                for any in tuple_obj.iter() {
                    if let Ok(name) = FromPyObject::extract(any) {
                        the_index.0.get_or_insert(name);
                    }
                    if let Ok(stime) = FromPyObject::extract(any) {
                        the_index.1.get_or_insert(stime);
                    }
                }

                Ok(the_index)
            }
            cn @ _ => {
                return Err(PyErr::from(Error::generic(&format!(
                    "DataFrame index format {} is not supported",
                    cn
                ))))
            }
        }
    }
}

impl<'a> TryFrom<&'a PyObject> for Values {
    type Error = PyErr;

    fn try_from(data_frame: &'a PyObject) -> std::result::Result<Values, Self::Error> {
        let gil = GILGuard::acquire();

        let py = gil.python();
        let row_iter_obj = data_frame.call_method0(py, "iterrows")?;
        let row_iter = PyIterator::from_object(py, &row_iter_obj)?;

        let mut the_rows: Vec<Row> = Vec::new();

        for any in row_iter {
            let (index_obj, row_obj): (PyObject, PyObject) = FromPyObject::extract(any?)?;

            let (dn, stime): (Option<String>, Option<f64>) =
                Values::row_index(&index_obj.to_object(py))?;

            let index: String =
                dn.ok_or(PyErr::from(Error::generic("DataFrame DN index is empty")))?;

            let row_dict_obj = row_obj.call_method0(py, "to_dict")?;
            let row_dict: &PyDict = row_dict_obj.cast_as(py)?;
            let mut cells: BTreeMap<Column, f64> = BTreeMap::new();

            for (tuple_any, value_any) in row_dict.iter() {
                let labels = Values::labels(&tuple_any.to_object(py))?;
                let value: f64 = FromPyObject::extract(&value_any).map_err(|e| {
                    let err = Error::from(e);
                    println!(
                        "Err: {:?} for value: {:?} for kpi: {:?}",
                        err, value_any, labels
                    );
                    PyErr::from(err)
                })?;

                let column = Column(labels);

                cells.insert(column, value);
            }

            the_rows.push(Row {
                index,
                stime,
                cells,
            });
        }

        Ok(Values { rows: the_rows })
    }
}

pub fn set_profile(
    data_frame: &PyObject,
    indicator_name: &str,
    values: &BTreeMap<String, f64>,
) -> PyResult<()> {
    let gil = GILGuard::acquire();
    let py = gil.python();

    let key = PyTuple::new(py, vec![indicator_name, "profile"]);
    let vals = values.into_py_dict(py);

    let locals = [("pd", py.import("pandas")?)].into_py_dict(py);
    if let Err(e) = locals.set_item("d", vals) {
        println!("error setting d: {:?}", e);
    }

    let serie = py.eval("pd.Series(d)", None, Some(locals))?;

    let args = (key, serie);

    data_frame.call_method1(py, "__setitem__", args)?;

    Ok(())
}

#[derive(Debug)]
pub struct Indicators {
    id_to_name: BTreeMap<i16, String>,
}

impl Indicators {
    pub fn header(&self) -> String {
        let names: Vec<&str> = self.id_to_name.values().map(|s| s.as_str()).collect();

        names.as_slice().join("|")
    }

    pub fn names(&self) -> Vec<String> {
        self.id_to_name.values().map(|s| s.to_owned()).collect()
    }

    pub fn ids(&self) -> Vec<i16> {
        self.id_to_name.keys().map(|id| *id).collect()
    }

    pub fn id2name(&self) -> BTreeMap<i16, String> {
        self.id_to_name.clone()
    }

    fn names_from_index(columns: PyObject) -> PyResult<Vec<String>> {
        let gil = GILGuard::acquire();
        let py = gil.python();

        let mut inames: Vec<String> = Vec::new();

        let list_obj = columns.call_method0(py, "to_list")?;

        let indicator_list = list_obj.cast_as::<PyList>(py)?;

        for iname in indicator_list.iter() {
            let indicator: String = FromPyObject::extract(&iname)?;
            inames.push(indicator);
        }

        Ok(inames)
    }

    fn names_from_multi_index(columns: PyObject) -> PyResult<Vec<String>> {
        let gil = GILGuard::acquire();
        let py = gil.python();

        let levels_obj = columns.getattr(py, "levels")?;
        let levels_list = levels_obj.cast_as::<PyList>(py)?;

        let mut inames: Vec<String> = Vec::new();

        let mut found: bool = false;

        for level_any in levels_list.iter() {
            let index_obj = level_any.to_object(py);
            let name_obj = index_obj.getattr(py, "name")?;
            let name: String = name_obj.extract(py)?;

            if let Some(_) = match name.as_str() {
                "kpi" | "KPI" | "Kpi" => {
                    found = true;
                    Some(true)
                }
                _ => None,
            } {
                let list_obj = index_obj.call_method0(py, "to_list")?;

                let indicator_list = list_obj.cast_as::<PyList>(py)?;

                for iname in indicator_list.iter() {
                    let indicator: String = FromPyObject::extract(&iname)?;
                    inames.push(indicator);
                }
            }
        }

        if !found {
            return Err(PyErr::from(Error::generic(
                "no KPI name found in DataFrame columns index",
            )));
        }

        Ok(inames)
    }
}

impl<'a> TryFrom<&'a PyObject> for Indicators {
    type Error = PyErr;

    fn try_from(data_frame: &'a PyObject) -> std::result::Result<Indicators, Self::Error> {
        let gil = GILGuard::acquire();
        let py = gil.python();

        let columns_obj = data_frame.getattr(py, "columns")?;
        let class_name: String = get_class_of(&columns_obj)?;

        let inames = match class_name.as_str() {
            "MultiIndex" => Indicators::names_from_multi_index(columns_obj)?,
            "Index" => Indicators::names_from_index(columns_obj)?,
            cn @ _ => {
                return Err(PyErr::from(Error::generic(&format!(
                    "DataFrame columns format {} is not supported",
                    cn
                ))))
            }
        };

        let metainfo = Metainfo::try_from(data_frame)?;
        let mut id_to_name: BTreeMap<i16, String> = BTreeMap::new();

        for name in inames.iter() {
            match metainfo.indicators_map.get(name) {
                Some(ind_id) => {
                    id_to_name.insert(*ind_id, name.to_owned());
                }
                None => {
                    warn!(
                        "no indicator {} found in sint info indicators map|discarded",
                        name
                    );
                }
            }
        }

        Ok(Indicators { id_to_name })
    }
}

impl IntoIterator for Indicators {
    type Item = (i16, String);
    type IntoIter = std::collections::btree_map::IntoIter<i16, String>;

    fn into_iter(self) -> Self::IntoIter {
        self.id_to_name.into_iter()
    }
}
