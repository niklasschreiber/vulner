use sint::ql::pg::pool::{Con, PostgresPool};

use crate::method::{self, execute, Error, Response};
use crate::rpc::*;
use crate::Result;

use jrpc;
use log::{debug, error, info, warn};
use ws::{self, CloseCode, Handler, Message, Sender};

pub struct RpcHnd {
    pub sender: Sender,
    pub pool: PostgresPool,
}

impl RpcHnd {
    fn run_method(&self, method: &str, request: jrpc::Request<String, jrpc::Value>) -> Response {
        let con: Con = match self.con() {
            Ok(con) => con,
            Err(e) => {
                error!("DB connection retrieval error: {}", e);
                return Response::with_error(
                    method,
                    Error::db_con_ret(
                        request.id.to_id().unwrap_or(jrpc::Id::Null),
                        &format!("{}", e),
                    ),
                );
            }
        };

        match method {
            // Server related RPC methods
            "Ping" => execute(Ping {}, request),

            // Service related RCP methods
            "ListService" => execute(service::List::new(con), request),
            "CreateService" => execute(service::Create::new(con), request),
            "RemoveService" => execute(service::Remove::new(con), request),

            // Indicator related RPC methods
            "ListIndicator" => execute(indicator::List::new(con), request),
            "CreateIndicator" => execute(indicator::Create::new(con), request),
            "SetIndicator" => execute(indicator::Set::new(con), request),
            "RemoveIndicator" => execute(indicator::Remove::new(con), request),

            // Monitor related RPC methods
            "ListMonitor" => execute(monitor::List::new(con), request),
            "CreateMonitor" => execute(monitor::Create::new(con), request),
            "SetMonitor" => execute(monitor::Set::new(con), request),
            "RemoveMonitor" => execute(monitor::Remove::new(con), request),

            // MonitorRule related RPC methods
            "ListMonitorRule" => execute(rule::List::new(con), request),
            "CreateMonitorRule" => execute(rule::Create::new(con), request),
            "SetMonitorRule" => execute(rule::Set::new(con), request),
            "RemoveMonitorRule" => execute(rule::Remove::new(con), request),
            "RemoveRuleGuard" => execute(rule::RemoveGuard::new(con), request),
            "RemoveRuleFilter" => execute(rule::RemoveFilter::new(con), request),

            // Instance related RPC methods
            "ListServiceInstance" => execute(instance::List::new(con), request),
            "TagServiceInstance" => execute(instance::Tag::new(con), request),

            // Managed Object related RCP methods
            "ListManagedObject" => execute(mo::List::new(con), request),

            // Attribute related RPC methods
            "ListAttribute" => execute(attribute::List::new(con), request),
            "CreateAttribute" => execute(attribute::Create::new(con), request),
            "SetAttribute" => execute(attribute::Set::new(con), request),
            "RemoveAttribute" => execute(attribute::Remove::new(con), request),

            // Stats related RPC methods
            "LastROPStats" => execute(stats::Stats::new(con), request),

            // Metric related RPC methods
            "SearchMetric" => execute(metric::Search::new(con), request),

            // Oops! Unknown method name!
            m @ _ => Response::with_error(
                m,
                Error::method_not_found(request.id.to_id().unwrap_or(jrpc::Id::Null), m),
            ),
        }
    }

    fn send(&self, messages: Vec<method::Message>) -> ws::Result<()> {
        let mut responses: Vec<String> = Vec::new();
        let mut notifications: Vec<String> = Vec::new();

        for message in messages.into_iter() {
            match message {
                method::Message::Response(response) => responses.push(response),
                method::Message::ResponseNotification(response, notification) => {
                    responses.push(response);
                    notifications.push(notification);
                }
            }
        }

        let response_json = match responses.len() {
            1 => format!("{}", responses[0]),
            n if n > 1 => format!("[{}]", responses.as_slice().join(",\n")),
            _ => {
                return Err(ws::Error::new(ws::ErrorKind::Internal, "no response"));
            }
        };

        let result = self.sender.send(Message::text(response_json));

        if notifications.len() < 100 {
            notifications.into_iter().for_each(|notification| {
                if let Err(e) = self.sender.broadcast(Message::text(notification)) {
                    warn!("Notification broadcast: {:?}", e);
                }
            });
        } else {
            let notification_json = match notifications.len() {
                1 => format!("{}", notifications[0]),
                n if n > 1 => format!("[{}]", notifications.as_slice().join(",\n")),
                _ => {
                    return Err(ws::Error::new(ws::ErrorKind::Internal, "no notification"));
                }
            };

            if let Err(e) = self.sender.broadcast(Message::text(notification_json)) {
                warn!("Notification broadcast: {:?}", e);
            }
        }

        result
    }

    fn con(&self) -> Result<Con> {
        self.pool.get_connection()
    }
}

impl Handler for RpcHnd {
    fn on_message(&mut self, msg: Message) -> ws::Result<()> {
        // msg is a RPC request
        match msg {
            Message::Text(r) => {
                let messages: Vec<method::Message> = parse_requests(&r)
                    .into_iter()
                    .map(|result| match result {
                        Ok(req) => {
                            debug!("{:?}", &req);
                            let method_name = req.method.to_owned();

                            let response = self.run_method(method_name.as_str(), req);
                            method::Message::from(response)
                        }
                        Err(err) => {
                            let response = method::Response::with_error("", err);
                            method::Message::from(response)
                        }
                    })
                    .collect();

                self.send(messages)
            }
            _ => Err(ws::Error::new(
                ws::ErrorKind::Internal,
                "sintql received an unsupported binary message",
            )),
        }
    }

    fn on_error(&mut self, err: ws::Error) {
        error!("sintql Socket Error: <{}>", err);
    }

    fn on_open(&mut self, shake: ws::Handshake) -> ws::Result<()> {
        info!(
            "Connection open with <{}>",
            shake
                .peer_addr
                .map(|a| format!("{}", a))
                .unwrap_or(String::from("unknown peer address"))
        );
        Ok(())
    }

    fn on_close(&mut self, code: CloseCode, reason: &str) {
        let ncode: u16 = code.into();
        info!(
            "Close event received with code: <{}> with reason: <{}>",
            ncode, reason
        );

        match code {
            CloseCode::Normal => println!("The client is done with the connection."),
            CloseCode::Away | CloseCode::Status => {
                debug!("The client is leaving the RPC Conf server.")
            }
            c @ _ => warn!(
                "The client encountered an error: {} [Close Code: {:?}]",
                reason, c
            ),
        }
    }
}

/// parse_requests parses a websocket text message in the JRPC format.
/// This function understand JRPC Batch requests.
fn parse_requests(
    json_req: &str,
) -> Vec<std::result::Result<jrpc::Request<String, jrpc::Value>, Error>> {
    debug!("JSON REQUEST: {}", json_req);

    match serde_json::from_str(json_req) {
        Err(err) => vec![Err(Error::parse_request(json_req, &err.to_string()))],
        Ok(value) => match value {
            serde_json::Value::Object(obj_val) => {
                vec![parse_single_request(serde_json::Value::from(obj_val))]
            }
            serde_json::Value::Array(arr_val) => arr_val
                .into_iter()
                .map(|value| parse_single_request(value))
                .collect(),
            _ => vec![Err(Error::parse_request(
                json_req,
                "Unsupported request serialization",
            ))],
        },
    }
}

fn parse_single_request(
    obj_val: serde_json::Value,
) -> std::result::Result<jrpc::Request<String, jrpc::Value>, Error> {
    let request: jrpc::Request<String, jrpc::Value> = serde_json::from_value(obj_val)
        .map_err(|err| Error::invalid_request(jrpc::Id::Null, &err.to_string()))?;

    Ok(request)
}
