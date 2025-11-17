//! 📦 Database models (Postgres structs with sqlx)

use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use sqlx::FromRow;

/// Customer model (CUSTOMERS table)
#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct Customer {
    pub cid: i64,
    pub mid: i32,
    pub email: String,
    pub firstname: Option<String>,
    pub lastname: Option<String>,
    pub created_gmt: i64, // Unix timestamp
    pub modified_gmt: i64,
    pub passhash: Option<String>,
    pub passsalt: Option<String>,
}

/// Order model (ORDERS table)
#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct Order {
    pub orderid: String,
    pub mid: i32,
    pub pool: String, // order_pool_enum
    pub customer: i64, // CID
    pub created_gmt: i64,
    pub modified_gmt: i64,
    pub order_total: i32, // cents
}

/// Product model (PRODUCTS table)
#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct Product {
    pub pid: String,
    pub mid: i32,
    pub created_ts: Option<DateTime<Utc>>,
    pub modified_ts: Option<DateTime<Utc>>,
    pub data: Option<String>, // YAML/JSON serialized
}
