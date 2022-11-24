use clap::{App, Arg};
use sint::ql::Indicator;
use sint::ql::ServiceClassConf;
use sint::ql::Services;
use sint::Result;
use walkdir::{DirEntry, WalkDir};

fn main() {
    if let Err(e) = run() {
        eprintln!("Rule Crawler reports: {}", e);
    }
}

fn run() -> Result<()> {
    let matches = App::new("Rule Crawler")
        .version("1.0")
        .about("Searches all services walking down the given directory and storing them on sqlite")
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
        .filter_map(|e| is_service_file(e))
    {
        let service = get_service_name(&entry);
        println!("Service: {:?}", service);

        let p = entry.path();

        match ServiceClassConf::new_from_path(p) {
            Err(e) => {
                eprintln!("{}", e);
                ers.push(format!("{}", p.display()));
            }
            Ok(sc) => {
                //println!("Service: {:#?}", sc);
                match service {
                    Some(service) => match services.create_service_only(&service) {
                        Err(e) => println!("Create Service for {} reports: {}", &service, e),
                        _ => {
                            println!("Create Service for {} successfully done.", &service);
                            sc.get_kpis().for_each(|kpi| {
                                let ind: Indicator = Indicator::from(kpi);
                                match services.create_indicator(ind) {
                                    Err(e) => {
                                        println!("Create Indicator for {:?} reports: {}", &kpi, e)
                                    }
                                    Ok(s) => {
                                        println!("{}", s);
                                        match services
                                            .add_indicator_to_service(&kpi.get_name(), &service)
                                        {
                                            Err(e) => println!(
                                                "Add Indicator {} to Service {} reports: {}",
                                                &kpi.get_name(),
                                                service,
                                                e
                                            ),
                                            Ok(s) => println!("{}", s),
                                        }
                                    }
                                }
                            });
                        }
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
        static ref RE: Regex = Regex::new("Services/([a-zA-Z0-9/_]*)/service.yaml").unwrap();
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

fn is_service_file(entry: DirEntry) -> Option<DirEntry> {
    let p = entry.path();
    if p.is_dir() {
        return None;
    }

    if p.file_name() == Some("service.yaml".as_ref()) {
        return Some(entry);
    }

    return None;
}
