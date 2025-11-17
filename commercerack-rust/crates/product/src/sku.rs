//! SKU (Stock Keeping Unit) management

use anyhow::Result;
use serde::{Deserialize, Serialize};
use sqlx::PgPool;

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct SKU {
    pub id: i64,
    pub mid: i32,
    pub pid: String,
    pub invopts: String,
    pub grp_parent: String,
    pub sku: String,
    pub title: String,
    pub cost: rust_decimal::Decimal,
    pub price: rust_decimal::Decimal,
    pub upc: String,
    pub mfgid: String,
    pub supplierid: String,
    pub prodasm: Option<String>,
    pub assembly: Option<String>,
    pub inv_available: i32,
    pub qty_onshelf: i32,
    pub qty_onorder: i32,
    pub qty_needship: i32,
    pub qty_markets: i32,
    pub qty_legacy: i32,
    pub qty_reserved: i32,
    pub amz_asin: String,
    pub amz_feeds_done: i16,
    pub amz_feeds_todo: i16,
    pub amz_feeds_sent: i16,
    pub amz_feeds_wait: i16,
    pub amz_feeds_warn: i16,
    pub amz_feeds_error: i16,
    pub amz_productdb_gmt: i32,
    pub amz_error: String,
    pub inv_on_shelf: i32,
    pub inv_on_order: i32,
    pub inv_is_bo: i32,
    pub inv_reorder: i32,
    pub inv_is_rsvp: i32,
    pub dss_agent: String,
    pub dss_run: Option<String>,
    pub dss_mood: Option<String>,
    pub dss_config: Option<String>,
}

impl SKU {
    /// Create new SKU
    pub async fn create(
        pool: &PgPool,
        mid: i32,
        pid: &str,
        sku: &str,
        title: &str,
        price: rust_decimal::Decimal,
    ) -> Result<Self> {
        let created = sqlx::query_as!(
            SKU,
            r#"
            INSERT INTO sku_lookup (mid, pid, sku, title, price)
            VALUES ($1, $2, $3, $4, $5)
            RETURNING id, mid, pid, invopts, grp_parent, sku, title,
                      cost as "cost: rust_decimal::Decimal",
                      price as "price: rust_decimal::Decimal",
                      upc, mfgid, supplierid, prodasm, assembly,
                      inv_available, qty_onshelf, qty_onorder, qty_needship,
                      qty_markets, qty_legacy, qty_reserved, amz_asin,
                      amz_feeds_done, amz_feeds_todo, amz_feeds_sent,
                      amz_feeds_wait, amz_feeds_warn, amz_feeds_error,
                      amz_productdb_gmt, amz_error, inv_on_shelf, inv_on_order,
                      inv_is_bo, inv_reorder, inv_is_rsvp, dss_agent,
                      dss_run as "dss_run: String", dss_mood as "dss_mood: String",
                      dss_config
            "#,
            mid, pid, sku, title, price
        )
        .fetch_one(pool)
        .await?;

        Ok(created)
    }

    /// Get SKU by ID
    pub async fn get(pool: &PgPool, mid: i32, id: i64) -> Result<Option<Self>> {
        let sku = sqlx::query_as!(
            SKU,
            r#"SELECT id, mid, pid, invopts, grp_parent, sku, title,
                      cost as "cost: rust_decimal::Decimal",
                      price as "price: rust_decimal::Decimal",
                      upc, mfgid, supplierid, prodasm, assembly,
                      inv_available, qty_onshelf, qty_onorder, qty_needship,
                      qty_markets, qty_legacy, qty_reserved, amz_asin,
                      amz_feeds_done, amz_feeds_todo, amz_feeds_sent,
                      amz_feeds_wait, amz_feeds_warn, amz_feeds_error,
                      amz_productdb_gmt, amz_error, inv_on_shelf, inv_on_order,
                      inv_is_bo, inv_reorder, inv_is_rsvp, dss_agent,
                      dss_run as "dss_run: String", dss_mood as "dss_mood: String",
                      dss_config
               FROM sku_lookup WHERE mid = $1 AND id = $2"#,
            mid, id
        )
        .fetch_optional(pool)
        .await?;

        Ok(sku)
    }

    /// Get SKU by SKU code
    pub async fn get_by_sku(pool: &PgPool, mid: i32, sku_code: &str) -> Result<Option<Self>> {
        let sku = sqlx::query_as!(
            SKU,
            r#"SELECT id, mid, pid, invopts, grp_parent, sku, title,
                      cost as "cost: rust_decimal::Decimal",
                      price as "price: rust_decimal::Decimal",
                      upc, mfgid, supplierid, prodasm, assembly,
                      inv_available, qty_onshelf, qty_onorder, qty_needship,
                      qty_markets, qty_legacy, qty_reserved, amz_asin,
                      amz_feeds_done, amz_feeds_todo, amz_feeds_sent,
                      amz_feeds_wait, amz_feeds_warn, amz_feeds_error,
                      amz_productdb_gmt, amz_error, inv_on_shelf, inv_on_order,
                      inv_is_bo, inv_reorder, inv_is_rsvp, dss_agent,
                      dss_run as "dss_run: String", dss_mood as "dss_mood: String",
                      dss_config
               FROM sku_lookup WHERE mid = $1 AND sku = $2"#,
            mid, sku_code
        )
        .fetch_optional(pool)
        .await?;

        Ok(sku)
    }

    /// Get SKUs by product ID
    pub async fn get_by_product(pool: &PgPool, mid: i32, pid: &str) -> Result<Vec<Self>> {
        let skus = sqlx::query_as!(
            SKU,
            r#"SELECT id, mid, pid, invopts, grp_parent, sku, title,
                      cost as "cost: rust_decimal::Decimal",
                      price as "price: rust_decimal::Decimal",
                      upc, mfgid, supplierid, prodasm, assembly,
                      inv_available, qty_onshelf, qty_onorder, qty_needship,
                      qty_markets, qty_legacy, qty_reserved, amz_asin,
                      amz_feeds_done, amz_feeds_todo, amz_feeds_sent,
                      amz_feeds_wait, amz_feeds_warn, amz_feeds_error,
                      amz_productdb_gmt, amz_error, inv_on_shelf, inv_on_order,
                      inv_is_bo, inv_reorder, inv_is_rsvp, dss_agent,
                      dss_run as "dss_run: String", dss_mood as "dss_mood: String",
                      dss_config
               FROM sku_lookup WHERE mid = $1 AND pid = $2"#,
            mid, pid
        )
        .fetch_all(pool)
        .await?;

        Ok(skus)
    }

    /// Update SKU
    pub async fn update(&mut self, pool: &PgPool) -> Result<()> {
        sqlx::query!(
            r#"UPDATE sku_lookup
               SET title = $1, price = $2, cost = $3, upc = $4,
                   inv_available = $5, qty_onshelf = $6
               WHERE mid = $7 AND id = $8"#,
            self.title, self.price, self.cost, self.upc,
            self.inv_available, self.qty_onshelf, self.mid, self.id
        )
        .execute(pool)
        .await?;

        Ok(())
    }

    /// Delete SKU
    pub async fn delete(pool: &PgPool, mid: i32, id: i64) -> Result<()> {
        sqlx::query!("DELETE FROM sku_lookup WHERE mid = $1 AND id = $2", mid, id)
            .execute(pool)
            .await?;
        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    async fn test_sku_operations() {
        if std::env::var("DATABASE_URL").is_err() {
            return;
        }

        let pool = PgPool::connect(&std::env::var("DATABASE_URL").unwrap())
            .await
            .unwrap();

        let mid = 1;
        let pid = "TEST-PROD-001";
        let sku_code = "TEST-SKU-001";
        let title = "Test SKU";
        let price = rust_decimal::Decimal::new(2999, 2); // $29.99

        // Create
        let mut sku = SKU::create(&pool, mid, pid, sku_code, title, price)
            .await
            .unwrap();
        assert_eq!(sku.sku, sku_code);
        assert_eq!(sku.price, price);
        assert!(sku.id > 0);

        // Get by ID
        let fetched = SKU::get(&pool, mid, sku.id)
            .await
            .unwrap()
            .unwrap();
        assert_eq!(fetched.id, sku.id);

        // Get by SKU code
        let by_code = SKU::get_by_sku(&pool, mid, sku_code)
            .await
            .unwrap()
            .unwrap();
        assert_eq!(by_code.id, sku.id);

        // Get by product
        let by_product = SKU::get_by_product(&pool, mid, pid).await.unwrap();
        assert!(!by_product.is_empty());

        // Update
        sku.price = rust_decimal::Decimal::new(3999, 2); // $39.99
        sku.inv_available = 100;
        sku.update(&pool).await.unwrap();

        let updated = SKU::get(&pool, mid, sku.id)
            .await
            .unwrap()
            .unwrap();
        assert_eq!(updated.price, rust_decimal::Decimal::new(3999, 2));
        assert_eq!(updated.inv_available, 100);

        // Delete
        SKU::delete(&pool, mid, sku.id).await.unwrap();
        let deleted = SKU::get(&pool, mid, sku.id).await.unwrap();
        assert!(deleted.is_none());
    }
}
