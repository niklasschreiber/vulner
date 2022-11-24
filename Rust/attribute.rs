use crate::method::{Error, Method, ResponseType, Result};
use sint::ql::pg::models;
use sint::ql::pg::{attribute, pool::Con};

use serde_derive::{Deserialize, Serialize};
use std::convert::{From, Into};
use std::vec::Vec;

#[derive(Clone, Debug, Serialize, Deserialize, PartialEq)]
pub struct AttributeFilter {
    service_pattern: Option<String>,
    indicator_pattern: Option<String>,
    label_pattern: Option<String>,
    offset: Option<i64>,
    limit: Option<i64>,
}

#[derive(Clone, Debug, Serialize, Deserialize, PartialEq)]
pub struct Attribute {
    pub label: Option<String>,
    pub unit: Option<String>,
    pub service_uri: String,
    pub indicator_name: String,
}

impl From<models::Attribute> for Attribute {
    fn from(attribute: models::Attribute) -> Attribute {
        Attribute {
            label: attribute.label.to_owned(),
            unit: attribute.unit.to_owned(),
            service_uri: attribute.service_uri.to_owned(),
            indicator_name: attribute.indicator_name.to_owned(),
        }
    }
}

impl Into<models::Attribute> for Attribute {
    fn into(self) -> models::Attribute {
        models::Attribute {
            label: self.label.to_owned(),
            unit: self.unit.to_owned(),
            service_uri: self.service_uri.to_owned(),
            indicator_name: self.indicator_name.to_owned(),
        }
    }
}

#[derive(Clone, Debug, Serialize, Deserialize, PartialEq)]
pub struct AttributeList {
    pub total: i64,
    pub attributes: Vec<Attribute>,
}

pub type ListOut = AttributeList;

/// List lists all attribute that match a pattern.
pub struct List {
    con: Con,
}

impl List {
    pub fn new(con: Con) -> Self {
        List { con }
    }
}

impl Method for List {
    type Input = AttributeFilter;
    type Output = ListOut;

    fn name(&self) -> &'static str {
        "ListAttribute"
    }

    fn call(&self, params: Option<Self::Input>) -> Result<Self::Output> {
        let attribute_filter: AttributeFilter = params.ok_or(Error::InvalidParam {
            id: jrpc::Id::Null,
            cause: format!("ListAttribute missing param"),
        })?;

        let (service_pattern, indicator_pattern, offset, limit) = (
            attribute_filter.service_pattern.unwrap_or(format!("")),
            attribute_filter.indicator_pattern.unwrap_or(format!("")),
            attribute_filter.offset.unwrap_or(0),
            attribute_filter.limit.unwrap_or(100),
        );

        let list_result = match attribute_filter.label_pattern {
            Some(label_pattern) => attribute::list(
                &service_pattern,
                &indicator_pattern,
                &label_pattern,
                offset,
                limit,
                &self.con,
            ),
            None => attribute::list_null_label(
                &service_pattern,
                &indicator_pattern,
                offset,
                limit,
                &self.con,
            ),
        };

        list_result
            .map_err(|e| Error::query_error("ListAttribute", e))
            .and_then(|(total, attribute_list)| {
                let attributes_list: Vec<Attribute> = attribute_list
                    .into_iter()
                    .map(|attribute| attribute.into())
                    .collect();

                Ok(AttributeList {
                    total,
                    attributes: attributes_list,
                })
            })
    }
}

/// Create creates the attribute with the given values.
pub struct Create {
    con: Con,
}

impl Create {
    pub fn new(con: Con) -> Self {
        Create { con }
    }
}

impl Method for Create {
    type Input = Attribute;
    type Output = String;

    fn name(&self) -> &'static str {
        "CreateAttribute"
    }

    fn response_type(&self) -> ResponseType {
        ResponseType::WithNotification
    }

    fn call(&self, params: Option<Self::Input>) -> Result<Self::Output> {
        let attribute_to_create: models::Attribute = params
            .ok_or(Error::InvalidParam {
                id: jrpc::Id::Null,
                cause: format!("CreateAttribute missing param"),
            })
            .map(|attr| attr.into())?;

        attribute::create(attribute_to_create, &self.con)
            .map_err(|e| Error::query_error("CreateAttribute", e))
    }
}

/// Set sets the attribute with the given values.
pub struct Set {
    con: Con,
}

impl Set {
    pub fn new(con: Con) -> Self {
        Set { con }
    }
}

impl Method for Set {
    type Input = Attribute;
    type Output = String;

    fn name(&self) -> &'static str {
        "SetAttribute"
    }

    fn response_type(&self) -> ResponseType {
        ResponseType::WithNotification
    }

    fn call(&self, params: Option<Self::Input>) -> Result<Self::Output> {
        let attribute_to_set: models::Attribute = params
            .ok_or(Error::InvalidParam {
                id: jrpc::Id::Null,
                cause: format!("SetAttribute missing param"),
            })
            .map(|ind| ind.into())?;

        attribute::set(attribute_to_set, &self.con)
            .map_err(|e| Error::query_error("SetAttribute", e))
    }
}

#[derive(Clone, Debug, Serialize, Deserialize, PartialEq)]
pub struct ServiceIndicator {
    pub service_uri: String,
    pub indicator_name: String,
}

/// Remove removes the attribute with the given values.
pub struct Remove {
    con: Con,
}

impl Remove {
    pub fn new(con: Con) -> Self {
        Remove { con }
    }
}

impl Method for Remove {
    type Input = ServiceIndicator;
    type Output = String;

    fn name(&self) -> &'static str {
        "RemoveAttribute"
    }

    fn response_type(&self) -> ResponseType {
        ResponseType::WithNotification
    }

    fn call(&self, params: Option<Self::Input>) -> Result<Self::Output> {
        let attribute_to_remove: ServiceIndicator = params.ok_or(Error::InvalidParam {
            id: jrpc::Id::Null,
            cause: format!("RemoveAttribute missing param"),
        })?;

        attribute::remove(
            &attribute_to_remove.service_uri,
            &attribute_to_remove.indicator_name,
            &self.con,
        )
        .map_err(|e| Error::query_error("RemoveAttribute", e))
    }
}
