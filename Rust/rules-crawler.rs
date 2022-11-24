use clap::{App, Arg};
use sint::ql::RuleConfig;
use sint::ql::Services;
use sint::{Error, Result};
use std::path::Component;
use walkdir::{DirEntry, WalkDir};

fn main() {
    if let Err(e) = run() {
        eprintln!("Rule Crawler reports: {}", e);
    }
}

fn run() -> Result<()> {
    let matches = App::new("Rule Crawler")
        .version("1.0")
        .about(
            "Searches all rules walking down the given directory and storing
    them on sqlite",
        )
        .arg(
            Arg::with_name("dir")
                .help("Sets the starting directory")
                .required(true)
                .index(1),
        )
        .get_matches();

    let path: &str = matches.value_of("dir").unwrap();

    let services = Services::new().expect("DB error");

    let mut ers: Vec<String> = vec![];

    for entry in WalkDir::new(&path)
        .into_iter()
        .filter_map(|e| e.ok())
        .filter_map(|e| is_monitor_rule_file(e))
    {
        let service = get_service_name(&entry);
        println!("Service: {:?}", service);

        let p = entry.path();

        match RuleConfig::new(p).map_err(|e| Error::found_error(&format!("{}", p.display()), e)) {
            Err(e) => {
                eprintln!("{}", e);
                ers.push(format!("{}", p.display()));
            }
            Ok(rule) => {
                println!("Rule: {:#?}", rule);

                let monitor = rule.get_slogan();

                match service {
                    Some(service) => match services.set_rule_config(&service, &monitor, rule) {
                        Err(e) => println!("Set rule for {} {} reports: {}", &service, &monitor, e),
                        _ => println!("Set rule for {} {} successfully done.", &service, &monitor),
                    },
                    None => println!("Service not found in entry: skip..."),
                }
            }
        }
    }

    if ers.len() > 0 {
        println!("\n\n\n");
        println!("───{:─<130}───", "File with wrong format");
        for p in ers {
            println!("{}", p);
        }
        println!("{:─<136}", "");
    }

    Ok(())
}

fn get_service_name(entry: &DirEntry) -> Option<String> {
    use lazy_static::lazy_static;
    use regex::Regex;

    lazy_static! {
        static ref RE: Regex = Regex::new("Services/([a-zA-Z0-9/_]*)/rules").unwrap();
    }

    let p = entry.path();
    let ps = match p.to_str() {
        Some(s) => String::from(s),
        None => String::new(),
    };

    match RE.captures(&ps) {
        Some(c) => c.get(1).map(|m| String::from(m.as_str())),
        None => None,
    }
}

fn is_monitor_rule_file(entry: DirEntry) -> Option<DirEntry> {
    let p = entry.path();
    if p.is_dir() {
        return None;
    }

    if p.extension() != Some("yaml".as_ref()) {
        return None;
    }
    let mut c = p.components().collect::<Vec<_>>();
    let _f = c.pop();
    let d = c.pop();

    if d == Some(Component::Normal("rules".as_ref())) {
        return Some(entry);
    }

    return None;
}
