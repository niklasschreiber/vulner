pub struct Indicator {}

impl Indicator {
    pub fn parse_from_str(s: &str) -> (f64, Option<f64>, Option<f64>, bool) {
        match s.parse::<f64>() {
            Ok(v) => (v, None, None, true),
            Err(_) => (std::f64::NAN, None, None, false),
        }
    }
}

#[cfg(test)]
mod tests {
    use super::Indicator;

    #[test]
    fn kpi_value_999999_99_test() {
        let kpi_exp = (999999.99f64, None, None, true);
        let kpi = Indicator::parse_from_str("999999.99");
        assert_eq!(kpi_exp, kpi);
    }

    #[test]
    fn kpi_value_9999999_9999_test() {
        let kpi_exp = (9999999.9999f64, None, None, true);
        let kpi = Indicator::parse_from_str("9999999.9999");
        assert_eq!(kpi_exp, kpi);
    }

    #[test]
    fn kpi_value_99999999_9999_test() {
        let kpi_exp = (99999999.9999f64, None, None, true);
        let kpi = Indicator::parse_from_str("99999999.9999");
        assert_eq!(kpi_exp, kpi);
    }

    #[test]
    fn kpi_value_999999999_9999_test() {
        let kpi_exp = (999999999.9999f64, None, None, true);
        let kpi = Indicator::parse_from_str("999999999.9999");
        assert_eq!(kpi_exp, kpi);
    }

    #[test]
    fn kpi_value_9999999999_9999_test() {
        let kpi_exp = (9999999999.9999f64, None, None, true);
        let kpi = Indicator::parse_from_str("9999999999.9999");
        assert_eq!(kpi_exp, kpi);
    }

    #[test]
    fn kpi_value_99999999999_9999_test() {
        let kpi_exp = (99999999999.9999f64, None, None, true);
        let kpi = Indicator::parse_from_str("99999999999.9999");
        assert_eq!(kpi_exp, kpi);
    }

    #[test]
    fn kpi_value_99999999999_999999_test() {
        let kpi_exp = (99999999999.999999f64, None, None, true);
        let kpi = Indicator::parse_from_str("99999999999.999999");
        assert_eq!(kpi_exp, kpi);
    }

    #[test]
    fn kpi_value_999999999999_999999_test() {
        let kpi_exp = (999999999999.999999f64, None, None, true);
        let kpi = Indicator::parse_from_str("999999999999.999999");
        assert_eq!(kpi_exp, kpi);
    }
}
