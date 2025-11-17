//! Order entity definition

use sea_orm::entity::prelude::*;
use serde::{Deserialize, Serialize};

#[derive(Clone, Debug, PartialEq, DeriveEntityModel, Serialize, Deserialize)]
#[sea_orm(table_name = "orders")]
pub struct Model {
    #[sea_orm(primary_key)]
    pub id: i32,
    pub mid: i32,
    pub orderid: String,
    pub cartid: String,
    pub customer: i32,
    pub pool: String,
    pub total: Decimal,
    pub created_gmt: i32,
    pub paid_gmt: Option<i32>,
    pub shipped_gmt: Option<i32>,
}

#[derive(Copy, Clone, Debug, EnumIter, DeriveRelation)]
pub enum Relation {}

impl ActiveModelBehavior for ActiveModel {}
