//! 🗄️ CommerceRack Database Layer (Postgres with sqlorm pattern)
//! Replaces Perl DBINFO.pm module

use anyhow::Result;
use sqlx::{PgPool, postgres::PgPoolOptions};
use std::collections::HashMap;
use std::sync::Arc;
use tokio::sync::RwLock;
use tracing::{info, warn};

pub mod errors;
pub mod models;

use errors::DbError;

/// 🏢 Multi-tenant database router
pub struct DatabaseRouter {
    pools: Arc<RwLock<HashMap<String, PgPool>>>,
    default_pool: PgPool,
}

impl DatabaseRouter {
    pub async fn new(database_url: &str) -> Result<Self> {
        let default_pool = PgPoolOptions::new()
            .max_connections(50)
            .connect(database_url)
            .await?;
        
        info!("✅ Database pool initialized");
        
        Ok(Self {
            pools: Arc::new(RwLock::new(HashMap::new())),
            default_pool,
        })
    }
    
    /// Get pool for specific merchant (multi-tenant isolation)
    pub async fn get_pool(&self, mid: Option<i32>) -> Result<PgPool, DbError> {
        match mid {
            None => Ok(self.default_pool.clone()),
            Some(mid_val) => {
                let pools = self.pools.read().await;
                if let Some(pool) = pools.get(&mid_val.to_string()) {
                    Ok(pool.clone())
                } else {
                    // 🤓 Default pool for now, add routing logic later
                    warn!("Using default pool for MID {}", mid_val);
                    Ok(self.default_pool.clone())
                }
            }
        }
    }
    
    pub async fn close_all(&self) {
        self.default_pool.close().await;
    }
}
