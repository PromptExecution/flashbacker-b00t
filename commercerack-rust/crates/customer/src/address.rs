//! Customer address management

use anyhow::Result;
use serde::{Deserialize, Serialize};
use sqlx::PgPool;

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct CustomerAddress {
    pub id: i32,
    pub cid: i32,
    pub mid: i32,
    pub label: String, // Address label
    pub firstname: String,
    pub lastname: String,
    pub company: String,
    pub address1: String,
    pub address2: String,
    pub city: String,
    pub state: String,
    pub zip: String,
    pub country: String,
    pub phone: String,
}

impl CustomerAddress {
    pub async fn create(pool: &PgPool, addr: CustomerAddress) -> Result<Self> {
        let created = sqlx::query_as!(
            CustomerAddress,
            r#"
            INSERT INTO customer_addrs
            (cid, mid, label, firstname, lastname, company, address1, address2,
             city, state, zip, country, phone, created_gmt)
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14)
            RETURNING id, cid, mid, label, firstname, lastname, company,
                      address1, address2, city, state, zip, country, phone
            "#,
            addr.cid, addr.mid, addr.label, addr.firstname, addr.lastname,
            addr.company, addr.address1, addr.address2, addr.city, addr.state,
            addr.zip, addr.country, addr.phone,
            chrono::Utc::now().timestamp() as i32
        )
        .fetch_one(pool)
        .await?;

        Ok(created)
    }

    pub async fn get_by_customer(pool: &PgPool, mid: i32, cid: i32) -> Result<Vec<Self>> {
        let addrs = sqlx::query_as!(
            CustomerAddress,
            "SELECT id, cid, mid, label, firstname, lastname, company,
                    address1, address2, city, state, zip, country, phone
             FROM customer_addrs WHERE mid = $1 AND cid = $2",
            mid, cid
        )
        .fetch_all(pool)
        .await?;

        Ok(addrs)
    }

    pub async fn delete(pool: &PgPool, mid: i32, id: i32) -> Result<()> {
        sqlx::query!("DELETE FROM customer_addrs WHERE mid = $1 AND id = $2", mid, id)
            .execute(pool)
            .await?;
        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    async fn test_address_operations() {
        if std::env::var("DATABASE_URL").is_err() {
            return;
        }

        let pool = PgPool::connect(&std::env::var("DATABASE_URL").unwrap())
            .await
            .unwrap();

        let addr = CustomerAddress {
            id: 0,
            cid: 1,
            mid: 1,
            label: "SHIP".to_string(),
            firstname: "Jane".to_string(),
            lastname: "Doe".to_string(),
            company: String::new(),
            address1: "123 Main St".to_string(),
            address2: String::new(),
            city: "Portland".to_string(),
            state: "OR".to_string(),
            zip: "97201".to_string(),
            country: "US".to_string(),
            phone: "555-1234".to_string(),
        };

        let created = CustomerAddress::create(&pool, addr.clone()).await.unwrap();
        assert!(created.id > 0);

        let addrs = CustomerAddress::get_by_customer(&pool, 1, 1).await.unwrap();
        assert!(!addrs.is_empty());

        CustomerAddress::delete(&pool, 1, created.id).await.unwrap();
    }
}
