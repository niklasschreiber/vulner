use crate::method::{Error, Method, ResponseType, Result};
use sint::ql::pg::models;
use sint::ql::pg::{instance, pool::Con};

use serde_derive::{Deserialize, Serialize};
use std::convert::From;
use std::vec::Vec;

#[derive(Clone, Debug, Serialize, Deserialize, PartialEq)]
pub struct TagIn {
    pub service: String,
    pub instances: Vec<String>,
    pub tag: Option<String>,
}

#[derive(Clone, Debug, Serialize, Deserialize, PartialEq)]
pub struct InstanceFilter {
    service: Option<String>,
    mo_pattern: Option<String>,
    tag_pattern: Option<String>,
    offset: Option<i64>,
    limit: Option<i64>,
}

#[derive(Clone, Debug, Serialize, Deserialize, PartialEq)]
pub struct Instance {
    pub name: String,
    pub mo: String,
    pub service_class: String,
    pub tag: Option<String>,
    pub enabled: bool,
    pub r#type: String,
}

impl From<models::Instance> for Instance {
    fn from(i: models::Instance) -> Self {
        Instance {
            name: i.name,
            mo: i.mo,
            service_class: i.service_class,
            tag: i.tag,
            enabled: i.enabled,
            r#type: i.type_,
        }
    }
}

#[derive(Clone, Debug, Serialize, Deserialize, PartialEq)]
pub struct InstanceList {
    pub total: i64,
    pub instances: Vec<Instance>,
}

pub type ListOut = InstanceList;

/// List lists all instance that match a pattern.
pub struct List {
    con: Con,
}

impl List {
    pub fn new(con: Con) -> Self {
        List { con }
    }
}

impl Method for List {
    type Input = InstanceFilter;
    type Output = ListOut;

    fn name(&self) -> &'static str {
        "ListServiceInstance"
    }

    fn call(&self, params: Option<Self::Input>) -> Result<Self::Output> {
        let instance_filter: InstanceFilter = params.ok_or(Error::InvalidParam {
            id: jrpc::Id::Null,
            cause: format!("ListServiceInstance missing param"),
        })?;

        let (service, mo_pattern, offset, limit) = (
            instance_filter.service.unwrap_or(format!("")),
            instance_filter.mo_pattern.unwrap_or(format!("")),
            instance_filter.offset.unwrap_or(0),
            instance_filter.limit.unwrap_or(100),
        );

        let list_result = match instance_filter.tag_pattern {
            Some(tag_pattern) => instance::list(
                &service,
                &mo_pattern,
                &tag_pattern,
                offset,
                limit,
                &self.con,
            ),
            None => instance::list_null_tag(&service, &mo_pattern, offset, limit, &self.con),
        };

        list_result
            .map_err(|e| Error::query_error("ListServiceInstance", e))
            .and_then(|(total, instance_list)| {
                let instance_list: Vec<Instance> = instance_list
                    .into_iter()
                    .map(|the_instance| Instance::from(the_instance))
                    .collect();

                Ok(InstanceList {
                    total,
                    instances: instance_list,
                })
            })
    }
}

/// Tag sets the tag record in the instance table with given value for matching
/// instances.
pub struct Tag {
    con: Con,
}

impl Tag {
    pub fn new(con: Con) -> Self {
        Tag { con }
    }
}

impl Method for Tag {
    type Input = TagIn;
    type Output = String;

    fn name(&self) -> &'static str {
        "TagServiceInstance"
    }

    fn response_type(&self) -> ResponseType {
        ResponseType::WithNotification
    }

    fn call(&self, params: Option<Self::Input>) -> Result<Self::Output> {
        let tag_in: TagIn = params.ok_or(Error::InvalidParam {
            id: jrpc::Id::Null,
            cause: format!("TagServiceInstance missing param"),
        })?;

        instance::tag(&tag_in.service, tag_in.instances, tag_in.tag, &self.con)
            .map_err(|e| Error::query_error("TagServiceInstance", e))
    }
}
