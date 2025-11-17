//! Customer entity definition

use sea_orm::entity::prelude::*;
use serde::{Deserialize, Serialize};

#[derive(Clone, Debug, PartialEq, DeriveEntityModel, Eq, Serialize, Deserialize)]
#[sea_orm(table_name = "customers")]
pub struct Model {
    #[sea_orm(primary_key)]
    pub cid: i32,
    pub mid: i32,
    pub email: String,
    pub firstname: String,
    pub lastname: String,
    pub created_gmt: i32,
    pub modified_gmt: i32,
    pub passhash: String,
    pub passsalt: String,
}

#[derive(Copy, Clone, Debug, EnumIter, DeriveRelation)]
pub enum Relation {}

impl ActiveModelBehavior for ActiveModel {}
