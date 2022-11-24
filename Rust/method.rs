use serde::de::DeserializeOwned;
use serde::ser::Serialize;
use std::fmt::Debug;

use log::error;

mod error_code {
    pub const CON_RETRIEVAL: i64 = -32001;
    pub const QUERY_ERROR: i64 = -32002;
    pub const UNIQUE_ERROR: i64 = -32003;
    pub const FK_VIOLATION_ERROR: i64 = -32004;
}

pub type Result<T> = std::result::Result<T, Error>;

#[derive(Debug, Fail)]
pub enum Error {
    #[fail(display = "{}", cause)]
    ParseRequest { cause: String },

    #[fail(display = "{}", cause)]
    InvalidRequest { id: jrpc::Id, cause: String },

    #[fail(display = "{}", cause)]
    InvalidParam { id: jrpc::Id, cause: String },

    #[fail(display = "{}", method_name)]
    MethodNotFound { id: jrpc::Id, method_name: String },

    #[fail(display = "{}", cause)]
    InternalError { id: jrpc::Id, cause: String },

    #[fail(display = "{}", cause)]
    DB {
        id: jrpc::Id,
        cause: String,
        code: i64,
    },
}

impl Error {
    fn set_id(self, id: jrpc::Id) -> Self {
        match self {
            Error::ParseRequest { cause } => Error::ParseRequest { cause },
            Error::InvalidRequest { id: _, cause } => Error::InvalidRequest { id, cause },
            Error::InvalidParam { id: _, cause } => Error::InvalidParam { id, cause },
            Error::MethodNotFound { id: _, method_name } => {
                Error::MethodNotFound { id, method_name }
            }
            Error::InternalError { id: _, cause } => Error::InternalError { id, cause },
            Error::DB { id: _, cause, code } => Error::DB { id, cause, code },
        }
    }

    pub fn parse_request(json: &str, msg: &str) -> Error {
        error!("Parse request {} error", json);

        Error::ParseRequest {
            cause: String::from(msg),
        }
    }

    pub fn invalid_request(id: jrpc::Id, msg: &str) -> Error {
        Error::InvalidRequest {
            cause: String::from(msg),
            id,
        }
    }

    pub fn invalid_params(id: jrpc::Id, msg: &str) -> Error {
        Error::InvalidParam {
            id,
            cause: String::from(msg),
        }
    }

    pub fn method_not_found(id: jrpc::Id, method_name: &str) -> Error {
        Error::MethodNotFound {
            id,
            method_name: String::from(method_name),
        }
    }

    pub fn db_con_ret(id: jrpc::Id, msg: &str) -> Error {
        Error::DB {
            id,
            cause: String::from(msg),
            code: error_code::CON_RETRIEVAL,
        }
    }

    pub fn query_error(msg: &str, e: sint::Error) -> Error {
        match e {
            sint::Error::DieselError {
                descr: desc,
                e: err,
                kind: error_kind,
            } => {
                let code = match error_kind {
                    sint::DBErrorKind::UniqueViolation => error_code::UNIQUE_ERROR,
                    sint::DBErrorKind::ForeignKeyViolation => error_code::FK_VIOLATION_ERROR,
                    _ => error_code::QUERY_ERROR,
                };

                Error::DB {
                    id: jrpc::Id::Null,
                    cause: format!("{}|{}|{}", msg, desc, err),
                    code: code,
                }
            }
            err @ _ => Error::InternalError {
                id: jrpc::Id::Null,
                cause: format!("{}|{}", msg, err),
            },
        }
    }
}

impl<T: Debug + Serialize + DeserializeOwned> std::convert::Into<jrpc::Error<T>> for Error {
    fn into(self) -> jrpc::Error<T> {
        match self {
            Error::ParseRequest { cause } => {
                jrpc::Error::new(jrpc::Id::Null, jrpc::ErrorCode::ParseError, cause, None)
            }
            Error::InvalidRequest { id, cause } => {
                jrpc::Error::new(id, jrpc::ErrorCode::InvalidRequest, cause, None)
            }
            Error::InvalidParam { id, cause } => {
                jrpc::Error::new(id, jrpc::ErrorCode::InvalidParams, cause, None)
            }
            Error::MethodNotFound { id, method_name } => {
                jrpc::Error::new(id, jrpc::ErrorCode::MethodNotFound, method_name, None)
            }
            Error::InternalError { id, cause } => {
                jrpc::Error::new(id, jrpc::ErrorCode::InternalError, cause, None)
            }
            Error::DB { id, cause, code } => {
                jrpc::Error::new(id, jrpc::ErrorCode::ServerError(code), cause, None)
            }
        }
    }
}

pub(crate) enum Message {
    Response(String),
    ResponseNotification(String, String),
}

pub enum ResponseType {
    Simple,
    WithNotification,
}

pub struct Response {
    response: jrpc::Response<jrpc::Value>,
    notification: Option<jrpc::Request<String, jrpc::Value>>,
}

impl Response {
    fn new_simple<T: Debug + Serialize>(
        method_name: impl Into<String>,
        request_id: jrpc::Id,
        method_result: Result<T>,
    ) -> Self {
        let the_method_name = method_name.into();

        let response = match method_result {
            Ok(res) => {
                let r_msg = format!("{:?}", res);
                match serde_json::to_value(res) {
                    Ok(v) => jrpc::Response::Ok(jrpc::Success::new(request_id, v)),
                    Err(e) => jrpc::Response::Err(jrpc::Error::new(
                        request_id,
                        jrpc::ErrorCode::ServerError(-32000),
                        format!("{}|{}|{:?}", &the_method_name, e, r_msg),
                        None,
                    )),
                }
            }
            Err(e) => jrpc::Response::Err(e.set_id(request_id).into()),
        };

        Response {
            response,
            notification: None,
        }
    }

    fn new_with_notification<T: Debug + Serialize>(
        method_name: impl Into<String>,
        request_id: jrpc::Id,
        request_args: Option<jrpc::Value>,
        method_result: Result<T>,
    ) -> Self {
        let the_method_name = method_name.into();

        let notification = match method_result.is_ok() {
            true => Some(jrpc::Request::with_params(
                jrpc::IdReq::Notification,
                the_method_name.to_owned(),
                request_args.unwrap_or(jrpc::Value::Null),
            )),
            false => None,
        };

        let response = match method_result {
            Ok(res) => {
                let r_msg = format!("{:?}", res);
                match serde_json::to_value(res) {
                    Ok(v) => jrpc::Response::Ok(jrpc::Success::new(request_id, v)),
                    Err(e) => jrpc::Response::Err(jrpc::Error::new(
                        request_id,
                        jrpc::ErrorCode::ServerError(-32000),
                        format!("{}|{}|{:?}", &the_method_name, e, r_msg),
                        None,
                    )),
                }
            }
            Err(e) => jrpc::Response::Err(e.set_id(request_id).into()),
        };

        Response {
            response,
            notification,
        }
    }

    pub(crate) fn with_error(method_name: impl Into<String>, error: Error) -> Self {
        error!("method {} error {}", method_name.into(), &error);

        let response = jrpc::Response::Err(error.into());

        Response {
            response,
            notification: None,
        }
    }
}

impl std::convert::From<Response> for Message {
    fn from(response: Response) -> Message {
        let res: String = response.response.to_string();
        let noti: Option<String> = response.notification.and_then(|n| Some(n.to_string()));

        match noti {
            None => Message::Response(res),
            Some(notify) => Message::ResponseNotification(res, notify),
        }
    }
}

pub trait Method {
    type Input: DeserializeOwned;
    type Output: Debug + Serialize;

    fn name(&self) -> &'static str;

    fn call(&self, params: Option<Self::Input>) -> Result<Self::Output>;

    fn response_type(&self) -> ResponseType {
        ResponseType::Simple
    }
}

pub fn execute<M: Method>(method: M, req: jrpc::Request<String, jrpc::Value>) -> Response {
    let id: jrpc::Id = match req.id.to_id() {
        Some(id) => id,
        None => {
            return Response::with_error(
                method.name(),
                Error::invalid_request(
                    jrpc::Id::Null,
                    &format!("{}|req without id|", method.name()),
                ),
            );
        }
    };

    let params: Option<M::Input> = match &req.params {
        Some(args) => match serde_json::from_value::<M::Input>(args.clone()) {
            Ok(p) => Some(p),
            Err(e) => {
                return Response::with_error(
                    method.name(),
                    Error::invalid_params(id, &format!("{}|req wrong params|{}", method.name(), e)),
                );
            }
        },
        None => None,
    };

    let method_result = method.call(params);

    match method.response_type() {
        ResponseType::Simple => Response::new_simple(method.name(), id, method_result),
        ResponseType::WithNotification => {
            Response::new_with_notification(method.name(), id, req.params, method_result)
        }
    }
}
