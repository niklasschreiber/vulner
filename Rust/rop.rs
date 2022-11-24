use chrono::prelude::*;
use chrono::Duration;

use core::ops::Sub;
use std::default::Default;
use std::fmt;

use std::convert::From;

use super::Result;

#[derive(Debug, PartialEq, PartialOrd, Clone)]
pub struct ROP {
    s: DateTime<Local>,
    d: Duration,
}

impl Eq for ROP {}

impl fmt::Display for ROP {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        let u: String = format!("{}", self.s.format("%Y/%m/%d %H:%M:%S"));
        let d: i64 = self.d.num_minutes();

        write!(f, "{}:{}", u, d)
    }
}

impl Default for ROP {
    fn default() -> Self {
        ROP {
            s: Local::now(),
            d: Duration::minutes(15 as i64),
        }
    }
}

impl From<(i64, i16)> for ROP {
    fn from(v: (i64, i16)) -> ROP {
        let (timestamp, rop) = v;

        ROP {
            s: Local.timestamp(timestamp, 0),
            d: Duration::minutes(rop as i64),
        }
    }
}

impl ROP {
    pub fn new(s: &str, e: &str) -> Result<ROP> {
        let local: Local = Local {};
        let st: DateTime<Local> = local.datetime_from_str(s, "%Y/%m/%d %H:%M:%S")?;
        let ed: DateTime<Local> = local.datetime_from_str(e, "%Y/%m/%d %H:%M:%S")?;
        let d: Duration = ed - st;

        match d.num_seconds() {
            -85500 => Ok(ROP {
                s: st,
                d: Duration::minutes(15i64),
            }),
            _ => Ok(ROP { s: st, d }),
        }
    }

    pub fn new_sd(s: &str, d: i64) -> Result<ROP> {
        let local: Local = Local {};
        let st: DateTime<Local> = local.datetime_from_str(s, "%Y/%m/%d %H:%M:%S")?;
        let d = Duration::minutes(d);

        Ok(ROP { s: st, d })
    }

    pub fn previous_rop(&self) -> ROP {
        let s = self.s.sub(self.d);
        ROP { s, d: self.d }
    }

    pub fn rop_one_week_ago(&self) -> ROP {
        let d: Duration = Duration::weeks(1);
        let s = self.s.sub(d);
        ROP { s, d: self.d }
    }

    pub fn nano(&self) -> Result<i64> {
        Ok(self.s.timestamp_nanos())
    }

    pub fn datetime(&self) -> DateTime<Local> {
        self.s
    }

    pub fn interval(&self) -> i16 {
        self.d.num_minutes() as i16
    }
}

#[derive(Debug, PartialEq)]
pub struct ProcTimes {
    pub stime: i64,
    pub ptime: i64,
}

impl From<&ROP> for ProcTimes {
    fn from(rop: &ROP) -> ProcTimes {
        use lazy_static::lazy_static;

        lazy_static! {
            static ref TIME_PRECISION: String = match std::env::var("SINT_TIME_PRECISION") {
                Ok(prec) => prec,
                Err(_) => String::from("millis"),
            };
        }

        match TIME_PRECISION.as_str() {
            "seconds" => ProcTimes {
                stime: rop.datetime().timestamp(),
                ptime: Local::now().timestamp(),
            },
            "millis" => ProcTimes {
                stime: rop.datetime().timestamp_millis(),
                ptime: Local::now().timestamp_millis(),
            },
            "micros" => ProcTimes {
                stime: rop.datetime().timestamp_nanos() / 1000i64,
                ptime: Local::now().timestamp_nanos() / 1000i64,
            },
            "nanos" => ProcTimes {
                stime: rop.datetime().timestamp_nanos(),
                ptime: Local::now().timestamp_nanos(),
            },
            _ => {
                panic!("env variabile SINT_TIME_PRECISION not in [seconds, millis, micros, nanos]")
            }
        }
    }
}

#[cfg(test)]
mod tests {
    use super::ROP;

    use chrono::prelude::*;
    use chrono::{Duration, Local};

    #[test]
    fn previous_rop_test() {
        let rop: ROP = match ROP::new("2019/01/11 08:45:00", "2019/01/11 09:00:00") {
            Ok(rop) => rop,
            Err(e) => {
                eprintln!("Error: {:?}", e);
                ROP {
                    s: Local::now(),
                    d: Duration::minutes(0i64),
                }
            }
        };

        let aprop: ROP = match ROP::new("2019/01/11 08:30:00", "2019/01/11 08:45:00") {
            Ok(rop) => rop,
            Err(e) => {
                eprintln!("Error: {:?}", e);
                ROP {
                    s: Local::now(),
                    d: Duration::minutes(0i64),
                }
            }
        };

        assert_eq!(aprop, rop.previous_rop());

        let crop: ROP = match ROP::new("2019/01/11 08:31:00", "2019/01/11 08:46:00") {
            Ok(rop) => rop,
            Err(e) => {
                eprintln!("Error: {:?}", e);
                ROP {
                    s: Local::now(),
                    d: Duration::minutes(0i64),
                }
            }
        };

        assert_ne!(crop, rop.previous_rop());
    }

    #[test]
    fn rop_one_week_ago_test() {
        let rop: ROP = match ROP::new("2019/01/11 08:45:00", "2019/01/11 09:00:00") {
            Ok(rop) => rop,
            Err(e) => {
                eprintln!("Error: {:?}", e);
                ROP {
                    s: Local::now(),
                    d: Duration::minutes(0i64),
                }
            }
        };

        let aprop: ROP = match ROP::new("2019/01/04 08:45:00", "2019/01/04 09:00:00") {
            Ok(rop) => rop,
            Err(e) => {
                eprintln!("Error: {:?}", e);
                ROP {
                    s: Local::now(),
                    d: Duration::minutes(0i64),
                }
            }
        };

        assert_eq!(aprop, rop.rop_one_week_ago());

        let crop: ROP = match ROP::new("2019/01/04 08:31:00", "2019/01/04 08:46:00") {
            Ok(rop) => rop,
            Err(e) => {
                eprintln!("Error: {:?}", e);
                ROP {
                    s: Local::now(),
                    d: Duration::minutes(0i64),
                }
            }
        };

        assert_ne!(crop, rop.rop_one_week_ago());
    }

    #[test]
    fn rop_evoluti_test() {
        let sr = "2018/02/04 23:45:00";
        let er = "2018/02/04 00:00:00";

        let rop = ROP::new(sr, er).unwrap();

        let local: Local = Local {};
        let s: DateTime<Local> = local.datetime_from_str(sr, "%Y/%m/%d %H:%M:%S").unwrap();

        let exp_rop = ROP {
            s,
            d: time::Duration::minutes(15i64),
        };

        assert_eq!(rop, exp_rop);
    }
}
