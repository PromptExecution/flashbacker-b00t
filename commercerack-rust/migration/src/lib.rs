pub use sea_orm_migration::prelude::*;

mod m20251117_000001_create_zusers;
mod m20251117_000002_create_customers;
mod m20251117_000003_create_customer_addrs;
mod m20251117_000004_create_customer_notes;
mod m20251117_000005_create_products;
mod m20251117_000006_create_product_relations;
mod m20251117_000007_create_sku_lookup;
mod m20251117_000008_create_orders;
mod m20251117_000009_create_order_events;
mod m20251117_000010_create_order_counters;
mod m20251117_000011_create_inventory_detail;
mod m20251117_000012_create_inventory_log;
mod m20251117_000013_create_amazon_docs;
mod m20251117_000014_create_amazon_document_contents;
mod m20251117_000015_create_amazon_orders;
mod m20251117_000016_create_amazon_order_events;
mod m20251117_000017_create_batch_jobs;
mod m20251117_000018_create_batch_parameters;
mod m20251117_000019_create_campaigns;
mod m20251117_000020_create_campaign_recipients;
mod m20251117_000021_create_projects;
mod m20251117_000022_create_checkouts;

pub struct Migrator;

#[async_trait::async_trait]
impl MigratorTrait for Migrator {
    fn migrations() -> Vec<Box<dyn MigrationTrait>> {
        vec![
            Box::new(m20251117_000001_create_zusers::Migration),
            Box::new(m20251117_000002_create_customers::Migration),
            Box::new(m20251117_000003_create_customer_addrs::Migration),
            Box::new(m20251117_000004_create_customer_notes::Migration),
            Box::new(m20251117_000005_create_products::Migration),
            Box::new(m20251117_000006_create_product_relations::Migration),
            Box::new(m20251117_000007_create_sku_lookup::Migration),
            Box::new(m20251117_000008_create_orders::Migration),
            Box::new(m20251117_000009_create_order_events::Migration),
            Box::new(m20251117_000010_create_order_counters::Migration),
            Box::new(m20251117_000011_create_inventory_detail::Migration),
            Box::new(m20251117_000012_create_inventory_log::Migration),
            Box::new(m20251117_000013_create_amazon_docs::Migration),
            Box::new(m20251117_000014_create_amazon_document_contents::Migration),
            Box::new(m20251117_000015_create_amazon_orders::Migration),
            Box::new(m20251117_000016_create_amazon_order_events::Migration),
            Box::new(m20251117_000017_create_batch_jobs::Migration),
            Box::new(m20251117_000018_create_batch_parameters::Migration),
            Box::new(m20251117_000019_create_campaigns::Migration),
            Box::new(m20251117_000020_create_campaign_recipients::Migration),
            Box::new(m20251117_000021_create_projects::Migration),
            Box::new(m20251117_000022_create_checkouts::Migration),
        ]
    }
}
