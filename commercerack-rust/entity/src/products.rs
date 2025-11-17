//! Product entity definition

use sea_orm::entity::prelude::*;
use serde::{Deserialize, Serialize};

#[derive(Clone, Debug, PartialEq, DeriveEntityModel, Serialize, Deserialize)]
#[sea_orm(table_name = "products")]
pub struct Model {
    #[sea_orm(primary_key)]
    pub id: i32,
    pub mid: i32,
    pub merchant: String,
    pub product: String,
    pub ts: i32,
    pub product_name: String,
    pub category: String,
    pub base_price: Decimal,
    pub base_cost: Decimal,
    pub supplier: String,
    pub supplier_id: String,
    pub upc: String,
    pub created_gmt: i32,
    pub lastsold_gmt: Option<i32>,
}

#[derive(Copy, Clone, Debug, EnumIter, DeriveRelation)]
pub enum Relation {}

impl ActiveModelBehavior for ActiveModel {}
