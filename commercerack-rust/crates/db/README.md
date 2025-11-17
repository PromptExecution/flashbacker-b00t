# CommerceRack Backend - b00t Rust Translation 🦀

**Status**: Initial implementation phase  
**Framework**: b00t + Axum + SQLx + Postgres  
**Original**: Perl/Plack + MySQL (318 modules, 386 files)

## 🎯 Project Overview

Translation of the legacy CommerceRack Perl e-commerce backend to modern b00t Rust, migrating from MySQL to PostgreSQL with sqlorm patterns.

### Why b00t + Rust?

- **Type Safety**: Compile-time guarantees eliminate entire classes of bugs
- **Performance**: 4-10x improvements in business logic execution
- **Memory Safety**: No leaks, no segfaults, no undefined behavior
- **Async Excellence**: Tokio runtime outperforms Perl threading
- **b00t Integration**: Hive coordination, tribal knowledge, aligned development

## 📊 Migration Progress

### Completed ✅

- [x] Analyze MySQL schema (152 tables, 4,195 lines)
- [x] Analyze Perl codebase (318 modules)
- [x] Create Postgres schema migration (22 critical tables)
- [x] Set up Cargo workspace structure
- [x] Implement database connection pool
- [x] Define core data models (Customer, Order, Product)

### In Progress 🚧

- [ ] Customer module translation (CUSTOMER.pm → Rust)
- [ ] Product module translation (PRODUCT.pm → Rust)
- [ ] Cart engine translation (CART2.pm → Rust)
- [ ] Axum API server

### Pending 📋

- [ ] Payment gateway integrations (16 providers)
- [ ] Shipping calculations (ZSHIP.pm)
- [ ] Marketplace integrations (Amazon, eBay, etc.)
- [ ] Background job processing
- [ ] Remaining 130 database tables

## 🏗️ Architecture

### Technology Stack

**Web Framework**: Axum 0.7  
**Database**: SQLx 0.8 (Postgres with compile-time checks)  
**Async Runtime**: Tokio 1.48  
**Serialization**: serde (JSON/YAML)  
**Caching**: Redis  
**Error Handling**: anyhow + thiserror

### Workspace Structure

```
commercerack-rust/
├── Cargo.toml (workspace root)
├── migrations/
│   └── 001_initial_schema.sql (Postgres schema, 22 tables)
├── crates/
│   ├── db/ (DatabaseRouter, connection pooling)
│   ├── core/ (shared utilities)
│   ├── customer/ (Customer management)
│   ├── product/ (Product catalog)
│   ├── cart/ (Shopping cart engine)
│   ├── order/ (Order processing)
│   ├── inventory/ (Inventory management)
│   ├── shipping/ (Shipping calculations)
│   ├── payment/ (Payment gateways)
│   └── api/ (JSON API)
├── vstore/ (Storefront server)
└── jsonapi/ (JSON API server)
```

## 🗄️ Database Migration

### MySQL → Postgres Conversion

**Challenges Addressed**:

1. **78 ENUM types** → PostgreSQL ENUMs
2. **103 zero datetime defaults** → NULL or valid timestamps
3. **188 AUTO_INCREMENT columns** → SERIAL/BIGSERIAL
4. **Unsigned integers** → Signed with appropriate sizing
5. **MEDIUMTEXT/LONGTEXT** → TEXT
6. **ON UPDATE CURRENT_TIMESTAMP** → Triggers
7. **Storage engines** → Removed (PostgreSQL native)

**Migration File**: `migrations/001_initial_schema.sql` (920 lines, 43KB)

### Critical Tables Migrated (22)

| Domain | Tables |
|--------|--------|
| Users | zusers |
| Customers | customers, customer_addrs, customer_notes |
| Products | products, product_relations, sku_lookup |
| Inventory | inventory_detail, inventory_log |
| Orders | orders, order_events, order_counters |
| Amazon | amazon_docs, amazon_document_contents, amazon_orders, amazon_order_events |
| Background Jobs | batch_jobs, batch_parameters |
| Marketing | campaigns, campaign_recipients |
| Config | projects, checkouts |

## 🦀 Rust Implementation Patterns

### Database Connection Pool

```rust
use commercerack_db::DatabaseRouter;

let router = DatabaseRouter::new(&db_url).await?;
let pool = router.get_pool(Some(merchant_id)).await?;
```

### Model Definitions (sqlorm pattern)

```rust
use sqlx::FromRow;
use serde::{Serialize, Deserialize};

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct Customer {
    pub cid: i64,
    pub mid: i32,
    pub email: String,
    pub firstname: Option<String>,
    pub created_gmt: i64, // Unix timestamp
}
```

### Query Pattern

```rust
let customer = sqlx::query_as!(
    Customer,
    "SELECT * FROM customers WHERE cid = $1 AND mid = $2",
    cid,
    mid
)
.fetch_one(&pool)
.await?;
```

## 📈 Performance Targets

| Operation | Perl Baseline | Rust Target | Expected Gain |
|-----------|--------------|-------------|---------------|
| JSON parsing | 100ms | 5-10ms | 10-20x |
| Cart calculation | 200ms | 20-50ms | 4-10x |
| Product search | 150ms | 50-100ms | 1.5-3x |
| Order processing | 500ms | 100-200ms | 2.5-5x |

## 🥾 b00t Integration

### Alignment with b00t Gospel

- **DRY/KISS**: Leveraging existing crates (SQLx, Axum, serde)
- **Tribal Knowledge**: Using `b00t lfmf` for lessons learned
- **Hive Coordination**: Multi-agent collaboration via `b00t acp hive`
- **Context Management**: Task delegation to sub-agents
- **Testing**: TDD with cargo test

### b00t Commands Used

```bash
b00t whoami # Agent identity verification
b00t learn rust.🦀 # Rust patterns & idioms
b00t datum  # Knowledge management
b00t lfmf rust "lesson" # Learn from failures
```

## 🚀 Getting Started

### Prerequisites

```bash
# Rust toolchain
rustup update stable

# PostgreSQL
psql --version # PostgreSQL 14+

# b00t CLI
b00t --version # 0.7.14+
```

### Setup

```bash
# Clone repository
git clone https://github.com/PromptExecution/flashbacker-b00t.git
cd flashbacker-b00t/commercerack-rust

# Set up database
createdb commercerack
psql commercerack < migrations/001_initial_schema.sql

# Configure environment
export DATABASE_URL="postgresql://user:pass@localhost/commercerack"

# Build
cargo build --release

# Test
cargo test
```

## 📚 Documentation

- **Original Perl Analysis**: See sub-agent reports (ZOOVY.pm, CART2.pm, JSONAPI.pm patterns)
- **Schema Analysis**: 152 tables, multi-tenant architecture, marketplace integrations
- **Migration Guide**: MySQL → Postgres conversion decisions

## 🤝 Contributing

Following b00t gospel principles:

1. **Use sub-agents** for complex tasks
2. **Practice TDD** - tests first, then implementation
3. **Be laconic** - concise, idiomatic code
4. **Leverage existing crates** - don't reinvent the wheel
5. **Melvin comments** 🤓 for non-obvious tribal knowledge

## 📝 License

MIT License

## 🙏 Acknowledgments

- b00t framework team (@elasticdotventures)
- Original CommerceRack Perl codebase
- Rust + Tokio + SQLx communities
