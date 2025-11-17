//! ❌ Database error types

use thiserror::Error;

#[derive(Error, Debug)]
pub enum DbError {
    #[error("Database error: {0}")]
    Sqlx(#[from] sqlx::Error),
    
    #[error("Connection pool error")]
    PoolError,
    
    #[error("Multi-tenant routing error")]
    RoutingError,
}
