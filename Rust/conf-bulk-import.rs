use calamine::{open_workbook, DataType, Range, Reader, Xlsx};
use clap::{App, Arg};
use serde_derive::{Deserialize, Serialize};
use sint::ql::{Indicator, Services};
use sint::ql::{InputKPI, MonitoringType, RuleConfig, Threshold, ThresholdGuard};
use sint::{Error, Result};
use std::collections::BTreeMap;
use std::env;
use std::fs::File;
use std::io::BufReader;
use std::path::Path;

use log::{debug, info};
use log4rs::init_file;

const LOG_CONF_DEFAULT: &str = "conf-bulk-imports-log.yaml";

struct IndicatorMap {
    indicator_name: String,
    indicator: Indicator,
}

#[derive(Debug, PartialEq, Serialize, Deserialize)]
struct Config {
    #[serde(rename = "indicator_sheet")]
    indicator_sheet_name: String,
    #[serde(rename = "monitor_sheet")]
    monitor_sheet_name: String,
    indicator_interval: usize,
    indicator_name: usize,
    indicator_description: usize,
    indicator_unit: usize,
    monitor_name: usize,
    monitor_type: usize,
    master_name: usize,
    master_operator: usize,
    critical: usize,
    critical_val: usize,
    major: usize,
    major_val: usize,
    minor: usize,
    minor_val: usize,
    warning: usize,
    warning_val: usize,
    guard_name: usize,
    guard_operator: usize,
    guard_threshold: usize,
    rops_alarmed: usize,
    hysteresis_factor: usize,
    deviation_window: usize,
}

fn read_conf<P>(conf_file: P) -> Result<Config>
where
    P: AsRef<Path>,
{
    serde_yaml::from_reader(File::open(&conf_file)?)
        .map_err(|e| Error::generic(&format!("parsing confing file reports: {:?}", e)))
}

fn main() {
    match run() {
        Ok(_) => println!("done"),
        Err(e) => eprintln!("Error - {:?}", e),
    }
}

fn run() -> Result<()> {
    let conf_dir = match env::var("SINT_CONF") {
        Ok(conf_dir) => conf_dir,
        Err(_) => String::from("../conf"),
    };

    let sint_logs = match env::var("SINT_LOGS") {
        Ok(path) => Some(path),
        Err(_) => None,
    };

    let opts = App::new("SINT Bulk Config Updater")
        .version("1.0")
        .about("Handles Bulk Config updates for SINT")
        .arg(
            Arg::with_name("input-file")
                .help("Xlsx file with the new config monitors of a Service.")
                .value_name("FILE")
                .required(true)
                .short("i")
                .long("input-file"),
        )
        .arg(
            Arg::with_name("root")
                .help(
                    r#"The Service that host the provided configuration.
If not provided the Service contained in the input
file will be considered a root service.
"#,
                )
                .value_name("SERVICE")
                .short("r")
                .long("root"),
        )
        .arg(
            Arg::with_name("conf")
                .help("Config file inside the SINT_CONF folder.")
                .value_name("conf.yaml")
                .default_value("conf-bulk-import.yaml")
                .short("c")
                .long("conf"),
        )
        .arg(
            Arg::with_name("log")
                .help(
                    "Sets log config file name. This file has to be in $SINT_CONF/logs directory.",
                )
                .short("l")
                .long("log")
                .default_value(LOG_CONF_DEFAULT),
        )
        .get_matches();

    match sint_logs.and_then(|log_dir| {
        if let Err(e) = env::set_current_dir(&log_dir) {
            eprintln!("sets current directory to {} reports: {}", &log_dir, e);
            None
        } else {
            opts.value_of("log")
                .map(|log| Path::new(&conf_dir).join("logs").join(log))
        }
    }) {
        Some(logname) => {
            if let Err(e) = init_file(&logname, Default::default())
                .map_err(|e| Error::generic(&format!("{} for file {}", e, &logname.display())))
            {
                eprintln!(
                    "logs initialization reports: {:?} [logging system disabled]",
                    e
                );
            }
        }
        None => eprintln!("variabile SINT_LOGS not set: logging system disabled"),
    }

    let conf = read_conf(Path::new(&conf_dir).join(opts.value_of("conf").unwrap()))?;

    let file_name = opts
        .value_of("input-file")
        .map(|v| Ok(v))
        .or(Some(Err(Error::generic("input-file should be provided!"))))
        .unwrap()?;

    let mut workbook: Xlsx<_> =
        open_workbook(file_name).map_err(|xe| Error::generic(&format!("Error {:?}", xe)))?;

    let bulk = BulkConfImport::new(conf, Services::new()?);
    bulk.conf_from_workbook(opts.value_of("root"), &mut workbook)
}

struct BulkConfImport {
    conf: Config,
    db: Services,
}

impl BulkConfImport {
    fn new(conf: Config, db: Services) -> BulkConfImport {
        BulkConfImport { conf, db }
    }

    fn conf_from_workbook(
        &self,
        service_root: Option<&str>,
        workbook: &mut Xlsx<BufReader<File>>,
    ) -> Result<()> {
        let kpis_sheet =
            self.open_sheet_or_fail(workbook, self.conf.indicator_sheet_name.as_str())?;
        let rule_sheet =
            self.open_sheet_or_fail(workbook, self.conf.monitor_sheet_name.as_str())?;

        let service_name = service_from(service_root, &rule_sheet)?;

        self.db.create_service_only(&service_name)?;

        let service_conf = deserialize_conf_from(|row| self.indicator_conf_from(row), &kpis_sheet)?;

        if service_conf.len() == 0 {
            return Err(Error::generic("Error: no service indicator found!"));
        }

        service_conf
            .into_iter()
            .map(
                |IndicatorMap {
                     indicator_name,
                     indicator,
                 }| { self.db.create_indicator(indicator).map(|_| indicator_name) },
            )
            .map(|res| {
                res.and_then(|ref indicator_name| {
                    self.db
                        .add_indicator_to_service(indicator_name, &service_name)
                })
            })
            .for_each(|res| info!("{:#?}", res));

        let rules = deserialize_conf_from(|row| self.rule_conf_from(row), &rule_sheet)?;

        rules
            .into_iter()
            .map(|rule| {
                let monitor = rule.get_slogan();

                self.db.set_rule_config(&service_name, &monitor, rule)
            })
            .for_each(|res| info!("{:#?}", res));

        Ok(())
    }

    fn open_sheet_or_fail(
        &self,
        workbook: &mut Xlsx<BufReader<File>>,
        sheet_name: &str,
    ) -> Result<Range<DataType>> {
        match workbook.worksheet_range(sheet_name) {
            Some(sheet) => sheet.map_err(|e| {
                Error::generic(&format!("found error {:?} opening {}", e, sheet_name))
            }),
            None => Err(Error::generic(&format!(
                "work sheet {} not found",
                sheet_name
            ))),
        }
    }

    fn indicator_conf_from(&self, row: &[DataType]) -> Result<IndicatorMap> {
        let name = row[self.conf.indicator_name].get_string().map_or(
            Err(Error::generic("indicator name should be present")),
            |n| Ok(n.to_string()),
        )?;

        let description = row[self.conf.indicator_description]
            .get_string()
            .or(Some(""))
            .unwrap();
        let unit = row[self.conf.indicator_unit]
            .get_string()
            .or(Some(""))
            .unwrap();

        Ok(IndicatorMap {
            indicator_name: name.to_string(),
            indicator: Indicator::new(name.as_str(), description, unit),
        })
    }

    fn rule_conf_from(&self, row: &[DataType]) -> Result<RuleConfig> {
        let slogan = row[self.conf.monitor_name]
            .get_string()
            .map_or(Err(Error::generic("Monitor should be provided")), |s| {
                Ok(s.to_string())
            })?;
        let monitoring_type = row[self.conf.monitor_type].get_string().map_or(
            Err(Error::generic("Monitor type should be provided")),
            |mt| monitor_type_from_str(mt),
        )?;

        let input = InputKPI {
            master: row[self.conf.master_name].get_string().map_or(
                Err(Error::generic("master indicator should be provided")),
                |m| Ok(m.to_string()),
            )?,
            guard: row[self.conf.guard_name]
                .get_string()
                .map(|g| g.to_string()),
            exposed: None,
            alias: None,
            g_alias: None,
            rets: None,
        };

        let mut threshold = Threshold {
            trigger_when_value: operator_from_string(
                row[self.conf.master_operator]
                    .get_string()
                    .or(Some(""))
                    .unwrap(),
            )?,
            level: BTreeMap::new(),
        };

        vec![
            (self.conf.critical, self.conf.critical_val),
            (self.conf.major, self.conf.major_val),
            (self.conf.minor, self.conf.minor_val),
            (self.conf.warning, self.conf.warning_val),
        ]
        .into_iter()
        .for_each(|(level, level_val)| {
            row[level].get_string().and_then(|severity| {
                threshold.insert(
                    &severity.to_lowercase(),
                    cell_number_value_to_string(&row[level_val]),
                )
            });
        });

        let guard = if input.get_guard().is_some() {
            Some(ThresholdGuard {
                trigger_when_value: row[self.conf.guard_operator]
                    .get_string()
                    .map(|o| operator_from_string(o).unwrap())
                    .expect("you provided a guard indicator, but not an operator"),
                level: cell_number_value_to_string(&row[self.conf.guard_threshold]),
            })
        } else {
            None
        };

        let deviation_window = row[self.conf.deviation_window].get_int().map(|o| o as i32);

        let filters = None;
        let hysteresis_factor = row[self.conf.hysteresis_factor].get_int().and_then(|c| {
            if c == 0 {
                None
            } else {
                Some(c as i32)
            }
        });

        let category = None;
        let rops_alarmed = row[self.conf.rops_alarmed].get_int().or(Some(1)).unwrap() as i8;

        Ok(RuleConfig {
            enabled: true,
            monitoring_type,
            filters,
            rops_alarmed,
            deviation_window,
            hysteresis_factor,
            guard,
            threshold,
            input,
            slogan,
            category,
        })
    }
}

fn cell_number_value_to_string(cell: &DataType) -> String {
    match cell {
        DataType::Int(s) => s.to_string(),
        DataType::Float(s) => s.to_string(),
        DataType::String(ref s) if !s.is_empty() && s.parse::<f64>().is_ok() => s.to_string(),
        _ => cell
            .get_string()
            .filter(|v| v.chars().last().unwrap_or(Default::default()) == '%')
            .map(|v| {
                let mut v = v.to_string();
                v.pop();
                v
            })
            .unwrap_or(String::from("")),
    }
}

fn service_from(service_root: Option<&str>, rule_sheet: &Range<DataType>) -> Result<String> {
    if let Some(first_cell_service_row) = rule_sheet.get((1, 1)) {
        return if let Some(service_root) = service_root {
            let mut service = String::new();
            service.push_str(service_root);
            service.push('/');
            service.push_str(&first_cell_service_row.to_string());
            Ok(service)
        } else {
            Ok(first_cell_service_row.to_string())
        };
    }

    Err(Error::generic("no service found"))
}

fn deserialize_conf_from<O>(
    map_to: impl Fn(&[DataType]) -> Result<O>,
    sheet: &Range<DataType>,
) -> Result<Vec<O>> {
    let mut data: Vec<O> = vec![];

    let mut first_row = true;

    for row in sheet.rows() {
        if first_row {
            debug!("skiped first row");
            first_row = false;
            continue;
        }

        data.push(map_to(row)?);
    }

    Ok(data)
}

fn operator_from_string(operator: &str) -> Result<String> {
    match operator {
        "greater than" | ">" => Ok(">".to_string()),
        "smaller than" | "<" => Ok("<".to_string()),
        "greater or equal to" | ">=" => Ok(">=".to_string()),
        "smaller or equal to" | "<=" => Ok("<=".to_string()),
        _ => Err(Error::generic(&format!(
            "should have a proper operator not <{}>",
            operator
        ))),
    }
}

fn monitor_type_from_str(monitor: &str) -> Result<MonitoringType> {
    match monitor.to_lowercase().as_str() {
        "basic thresholding" => Ok(MonitoringType::BasicTh),
        "basic thresholding with guard condition on same source" => Ok(MonitoringType::BasicThGuSS),
        "basic thresholding with guard condition across different sources" => {
            Ok(MonitoringType::BasicWithGuardDifferentSources)
        }
        "basic thresholding with persistence on guard on same source" => {
            Ok(MonitoringType::BasicWithPersistenceOnGuard)
        }
        "deviation thresholding with guard condition on same source" => {
            Ok(MonitoringType::DeviationGu)
        }
        "deviation thresholding" => Ok(MonitoringType::Deviation),
        "deviation thresholding with difference guard condition" => {
            Ok(MonitoringType::DeviationWithDifferenceGuard)
        }
        "deviation thresholding with guard condition across different sources" => {
            Ok(MonitoringType::DeviationWithGuardDifferentSources)
        }
        "profiling thresholding" => Ok(MonitoringType::Profile),
        "profiling thresholding with guard condition on same source" => {
            Ok(MonitoringType::ProfileWithGuard)
        }
        "profiling thresholding with guard condition across different sources" => {
            Ok(MonitoringType::ProfileWithGuardDifferentSources)
        }
        "profiling thresholding with difference guard condition" => {
            Ok(MonitoringType::ProfileWithDifferenceGuard)
        }
        _ => Err(Error::generic(&format!("no monitor type for {}", monitor))),
    }
}
