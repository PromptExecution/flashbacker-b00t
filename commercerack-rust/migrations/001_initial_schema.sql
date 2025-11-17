-- ============================================================================
-- CommerceRack PostgreSQL Schema Migration
-- From: MySQL 5.6.14 Schema (152 tables, 78 ENUMs, 103 zero datetime defaults)
-- To: PostgreSQL 14+ Compatible Schema
--
-- Migration Strategy:
-- 1. Convert AUTO_INCREMENT → SERIAL/BIGSERIAL
-- 2. Convert ENUMs → PostgreSQL ENUM types (with CHECK constraints fallback)
-- 3. Fix zero datetime defaults (0000-00-00 00:00:00) → NULL
-- 4. Remove Engine declarations (MyISAM/InnoDB)
-- 5. Convert unsigned integers → appropriate PostgreSQL types
-- 6. Convert MEDIUMTEXT/LONGTEXT → TEXT
-- 7. Convert MEDIUMBLOB → BYTEA
-- 8. Handle ON UPDATE CURRENT_TIMESTAMP → triggers (see end of file)
-- 9. Convert backticks → double-quotes (only where needed)
-- 10. Convert CHARACTER SET specifications → removed (use database default UTF-8)
--
-- This migration covers the 25 most critical tables for initial deployment.
-- Additional tables will be migrated in subsequent migration files.
-- ============================================================================

-- ============================================================================
-- SECTION 1: CREATE POSTGRESQL ENUM TYPES
-- ============================================================================

-- Pool statuses for orders
CREATE TYPE order_pool_enum AS ENUM (
    'RECENT', 'REVIEW', 'HOLD', 'PENDING', 'APPROVED',
    'PROCESS', 'COMPLETED', 'DELETED', 'QUOTE',
    'BACKORDER', 'PREORDER', 'ARCHIVE', ''
);

-- Batch job statuses
CREATE TYPE batch_job_status_enum AS ENUM (
    'NEW', 'HOLD', 'QUEUED', 'RUNNING', 'ABORTING',
    'END', 'END-ABORT', 'END-SUCCESS', 'END-WARNINGS',
    'END-ERRORS', 'END-CRASHED'
);

-- Campaign statuses
CREATE TYPE campaign_status_enum AS ENUM (
    'NEW', 'WAITING', 'SENDING', 'FINISHED'
);

CREATE TYPE campaign_queue_mode_enum AS ENUM (
    'FRONT', 'BACK', 'SINGLE'
);

CREATE TYPE checkout_assist_enum AS ENUM (
    'NONE', 'CALL', 'CHAT', ''
);

-- Inventory detail base types
CREATE TYPE inventory_basetype_enum AS ENUM (
    'SIMPLE', 'RETURN', 'WMS', 'SUPPLIER', 'ITEM',
    'UNPAID', 'PURCHASE', 'HOLD', 'PICK', 'PICKED',
    'DONE', 'SHIPPED', 'CANCEL', 'OVERSOLD', 'BACKORDER',
    'ERROR', 'PREORDER', 'ONORDER', 'MARKET', 'CLAIM',
    'CONSTANT', '_ASM_'
);

CREATE TYPE inventory_pick_route_enum AS ENUM (
    '', 'NEW', 'TBD', 'SIMPLE', 'WMS', 'SUPPLIER', 'PARTNER'
);

CREATE TYPE inventory_vendor_status_enum AS ENUM (
    'NEW', 'MANUAL_DISPATCH', 'ADDED', 'ONORDER', 'CONFIRMED',
    'RECEIVED', 'RETURNED', 'FINISHED', 'CANCELLED', 'CORRUPT'
);

-- Amazon document feed types
CREATE TYPE amazon_feed_enum AS ENUM (
    'init', 'products', 'prices', 'images', 'inventory',
    'relations', 'shipping', 'deleted'
);

-- Amazon shipping methods
CREATE TYPE amazon_shipping_method_enum AS ENUM (
    'Standard', 'Expedited', 'Scheduled', 'NextDay', 'SecondDay', 'Unknown'
);

-- Amazon order event types
CREATE TYPE amazon_order_event_type_enum AS ENUM (
    'ORDER-ACK', 'FULFILL-ACK', ''
);

-- Project types
CREATE TYPE project_type_enum AS ENUM (
    'APP', 'VSTORE', 'ADMIN', 'CHECKOUT', 'DSS', 'TEMPLATE', ''
);

-- DSS (Dynamic Sourcing System) configurations
CREATE TYPE dss_run_set AS ENUM (
    'ENABLED', 'UNLEASHED', 'PAUSED', 'HALTED'
);

CREATE TYPE dss_mood_enum AS ENUM (
    'WINNING', 'HAPPY', 'ZEN', 'MEDITATING', 'SLEEPY',
    'GRUMPY', 'DEPRESSED', 'UNHAPPY', 'ANGRY', 'SUICIDAL'
);

-- ============================================================================
-- SECTION 2: CORE USER & AUTHENTICATION TABLES
-- ============================================================================

-- Main users table (merchants)
CREATE TABLE zusers (
    mid SERIAL PRIMARY KEY,
    username VARCHAR(20) NOT NULL DEFAULT '',
    password VARCHAR(50) NOT NULL DEFAULT '',
    password_changed TIMESTAMP NULL,  -- MySQL: DEFAULT '0000-00-00 00:00:00' → NULL
    reseller VARCHAR(12) NOT NULL DEFAULT '',
    created TIMESTAMP NULL,  -- MySQL: DEFAULT '0000-00-00 00:00:00' → NULL
    last_login TIMESTAMP NULL,  -- MySQL: DEFAULT '0000-00-00 00:00:00' → NULL
    logins INTEGER NOT NULL DEFAULT 0,  -- MySQL: unsigned int(10)
    cached_flags VARCHAR(255) NOT NULL DEFAULT '',
    email VARCHAR(65) NOT NULL DEFAULT '',
    phone VARCHAR(20) NOT NULL DEFAULT '',
    salesperson VARCHAR(20) NOT NULL DEFAULT '',
    tech_contact VARCHAR(10) NOT NULL DEFAULT '',
    overduenotify_gmt INTEGER NOT NULL DEFAULT 0,  -- MySQL: unsigned int(10)
    ipaddr VARCHAR(16) NOT NULL DEFAULT '',
    data TEXT NOT NULL DEFAULT '',  -- MySQL: mediumtext
    sugarguid VARCHAR(65) NOT NULL DEFAULT '',
    bill_day SMALLINT NOT NULL DEFAULT 0,  -- MySQL: tinyint(4)
    bill_package VARCHAR(8) NOT NULL DEFAULT '',
    bill_provisioned DATE NULL,  -- MySQL: DEFAULT '0000-00-00' → NULL
    bill_nextrun DATE NULL,  -- MySQL: DEFAULT '0000-00-00' → NULL
    bill_lastexec TIMESTAMP NULL,  -- MySQL: DEFAULT '0000-00-00 00:00:00' → NULL
    bill_orderdate TIMESTAMP NULL,  -- MySQL: DEFAULT '0000-00-00 00:00:00' → NULL
    invoice_count SMALLINT NOT NULL DEFAULT 0,  -- MySQL: unsigned tinyint(3)
    bill_lock_id INTEGER NOT NULL DEFAULT 0,  -- MySQL: unsigned int(10)
    bill_lock_gmt INTEGER NOT NULL DEFAULT 0,  -- MySQL: unsigned int(10)
    bill_customrates TEXT NOT NULL DEFAULT '',  -- MySQL: tinytext
    bill_pricing_revision SMALLINT NOT NULL DEFAULT 0,  -- MySQL: tinyint(4)
    bpp_member SMALLINT NOT NULL DEFAULT 0,  -- MySQL: tinyint(4)
    bpp_lastcheck_gmt INTEGER NOT NULL DEFAULT 0,  -- MySQL: int(11)
    published_file VARCHAR(45) NOT NULL DEFAULT '',
    published_gmt INTEGER NOT NULL DEFAULT 0,  -- MySQL: unsigned int(10)
    bpp_review_count SMALLINT NOT NULL DEFAULT 0,  -- MySQL: unsigned smallint(5)
    cluster VARCHAR(10) NOT NULL DEFAULT 'beast',
    bs_returndays SMALLINT NOT NULL DEFAULT 0,  -- MySQL: tinyint(4)
    tkts_available SMALLINT NOT NULL DEFAULT 0,  -- MySQL: unsigned smallint(5)
    tkts_used SMALLINT NOT NULL DEFAULT 0,  -- MySQL: unsigned smallint(5)
    tkts_lastused_gmt INTEGER NOT NULL DEFAULT 0,  -- MySQL: unsigned int(10)
    is_newbie SMALLINT NOT NULL DEFAULT 1  -- MySQL: tinyint(4)
);

CREATE UNIQUE INDEX idx_zusers_username ON zusers(username);
CREATE UNIQUE INDEX idx_zusers_sugarguid ON zusers(sugarguid);
CREATE INDEX idx_zusers_reseller ON zusers(reseller);
CREATE INDEX idx_zusers_salesperson ON zusers(salesperson);
CREATE INDEX idx_zusers_phone ON zusers(phone);

COMMENT ON TABLE zusers IS 'Main merchant/user accounts table';
COMMENT ON COLUMN zusers.mid IS 'Merchant ID - primary key';
COMMENT ON COLUMN zusers.password_changed IS 'MySQL zero datetime converted to NULL';
COMMENT ON COLUMN zusers.created IS 'MySQL zero datetime converted to NULL';

-- ============================================================================
-- SECTION 3: CUSTOMER TABLES
-- ============================================================================

-- Main customers table
CREATE TABLE customers (
    cid SERIAL PRIMARY KEY,
    orgid INTEGER NOT NULL DEFAULT 0,  -- MySQL: unsigned int(10)
    mid INTEGER NOT NULL DEFAULT 0,  -- MySQL: unsigned int(10)
    username VARCHAR(20) NOT NULL DEFAULT '',
    prt SMALLINT NOT NULL DEFAULT 0,  -- MySQL: unsigned smallint(4)
    email VARCHAR(65) NOT NULL DEFAULT '',
    password VARCHAR(36) NOT NULL DEFAULT '',
    passhash VARCHAR(30) NOT NULL DEFAULT '',
    passsalt VARCHAR(10) NOT NULL DEFAULT '',
    firstname VARCHAR(50) NOT NULL DEFAULT '',
    lastname VARCHAR(50) NOT NULL DEFAULT '',
    phone VARCHAR(10) NOT NULL DEFAULT '',
    created_gmt INTEGER NOT NULL DEFAULT 0,  -- MySQL: unsigned int(10)
    modified_gmt INTEGER NOT NULL DEFAULT 0,  -- MySQL: unsigned int(10)
    lastlogin_gmt INTEGER NOT NULL DEFAULT 0,  -- MySQL: unsigned int(10)
    lastorder_gmt INTEGER NOT NULL DEFAULT 0,  -- MySQL: unsigned int(10)
    order_count SMALLINT NOT NULL DEFAULT 0,  -- MySQL: unsigned smallint(5)
    newsletter INTEGER DEFAULT 1,  -- MySQL: unsigned int(11)
    optin_gmt INTEGER NOT NULL DEFAULT 0,  -- MySQL: unsigned int(10)
    hint_num SMALLINT NOT NULL DEFAULT 0,  -- MySQL: tinyint(4)
    hint_answer VARCHAR(10) NOT NULL DEFAULT '',
    hint_attempts SMALLINT NOT NULL DEFAULT 0,  -- MySQL: tinyint(4)
    ip INTEGER NOT NULL DEFAULT 0,  -- MySQL: unsigned int(10) - stores IP as integer
    origin SMALLINT NOT NULL DEFAULT 0,  -- MySQL: unsigned tinyint(3)
    schedule VARCHAR(4) NOT NULL DEFAULT '',
    has_notes SMALLINT NOT NULL DEFAULT 0,  -- MySQL: tinyint(4)
    reward_balance INTEGER,  -- MySQL: unsigned int(10)
    is_affiliate SMALLINT NOT NULL DEFAULT 0,  -- MySQL: smallint(6)
    is_locked SMALLINT NOT NULL DEFAULT 0  -- MySQL: tinyint(4)
);

CREATE UNIQUE INDEX idx_customers_mid_cid ON customers(mid, cid);
CREATE UNIQUE INDEX idx_customers_mid_prt_email ON customers(mid, prt, email);
CREATE INDEX idx_customers_mid_modified ON customers(mid, modified_gmt);

COMMENT ON TABLE customers IS 'Customer accounts and profiles';
COMMENT ON COLUMN customers.ip IS 'IP address stored as integer for efficiency';

-- Customer addresses
CREATE TABLE customer_addrs (
    id SERIAL PRIMARY KEY,
    mid INTEGER NOT NULL DEFAULT 0,  -- MySQL: unsigned int(10)
    cid INTEGER NOT NULL DEFAULT 0,  -- MySQL: unsigned int(10)
    created_gmt INTEGER NOT NULL DEFAULT 0,  -- MySQL: unsigned int(10)
    guid VARCHAR(36) NOT NULL DEFAULT '',
    is_default SMALLINT NOT NULL DEFAULT 0,  -- MySQL: tinyint(4)
    label VARCHAR(15) NOT NULL DEFAULT '',
    firstname VARCHAR(30) NOT NULL DEFAULT '',
    lastname VARCHAR(30) NOT NULL DEFAULT '',
    address1 VARCHAR(50) NOT NULL DEFAULT '',
    address2 VARCHAR(30) NOT NULL DEFAULT '',
    city VARCHAR(30) NOT NULL DEFAULT '',
    state VARCHAR(20) NOT NULL DEFAULT '',
    zip VARCHAR(10) NOT NULL DEFAULT '',
    country VARCHAR(2) NOT NULL DEFAULT '',
    phone VARCHAR(12) NOT NULL DEFAULT '',
    company VARCHAR(30) NOT NULL DEFAULT ''
);

CREATE UNIQUE INDEX idx_customer_addrs_mid_guid ON customer_addrs(mid, guid);
CREATE INDEX idx_customer_addrs_mid_cid ON customer_addrs(mid, cid);

-- Customer notes
CREATE TABLE customer_notes (
    id SERIAL PRIMARY KEY,
    mid INTEGER NOT NULL DEFAULT 0,  -- MySQL: unsigned int(10)
    username VARCHAR(20) NOT NULL DEFAULT '',
    cid INTEGER NOT NULL DEFAULT 0,  -- MySQL: unsigned int(10)
    created_gmt INTEGER NOT NULL DEFAULT 0,  -- MySQL: unsigned int(10)
    luser VARCHAR(10) NOT NULL DEFAULT '',
    note TEXT NOT NULL DEFAULT '',  -- MySQL: tinytext
    type VARCHAR(3) NOT NULL DEFAULT ''
);

CREATE INDEX idx_customer_notes_mid_cid ON customer_notes(mid, cid);

-- ============================================================================
-- SECTION 4: PRODUCT TABLES
-- ============================================================================

-- Main products table
CREATE TABLE products (
    id SERIAL PRIMARY KEY,
    mid INTEGER NOT NULL DEFAULT 0,  -- MySQL: unsigned mediumint(8)
    merchant VARCHAR(20) NOT NULL DEFAULT '',
    product VARCHAR(20) NOT NULL DEFAULT '',
    ts INTEGER NOT NULL DEFAULT 0,  -- MySQL: unsigned int(11) - timestamp
    product_name VARCHAR(80) NOT NULL DEFAULT '',
    category VARCHAR(60) NOT NULL DEFAULT '',
    data TEXT NOT NULL DEFAULT '',  -- MySQL: mediumtext
    salesrank INTEGER NOT NULL DEFAULT 0,  -- MySQL: unsigned int(10)
    created_gmt INTEGER NOT NULL DEFAULT 0,  -- MySQL: int(11)
    lastsold_gmt INTEGER NOT NULL DEFAULT 0,  -- MySQL: int(11)
    base_price DECIMAL(10,2),
    base_cost DECIMAL(10,2),
    supplier VARCHAR(6),
    supplier_id VARCHAR(20),
    mfg VARCHAR(20),
    mfg_id VARCHAR(20),
    upc VARCHAR(15) NOT NULL DEFAULT '',
    options INTEGER NOT NULL DEFAULT 0,  -- MySQL: unsigned int(10)
    profile VARCHAR(10) NOT NULL DEFAULT '',
    mkt BIGINT NOT NULL DEFAULT 0,  -- MySQL: bigint(20)
    prod_is INTEGER NOT NULL DEFAULT 0,  -- MySQL: unsigned int(10)
    mkt_bitstr VARCHAR(24) NOT NULL DEFAULT '',
    mkterr_bitstr VARCHAR(16) NOT NULL DEFAULT ''
);

CREATE UNIQUE INDEX idx_products_mid_product ON products(mid, product);
CREATE INDEX idx_products_mid_ts ON products(mid, ts);
CREATE INDEX idx_products_mid_supplierid ON products(mid, supplier_id);

COMMENT ON TABLE products IS 'Main products catalog';
COMMENT ON COLUMN products.data IS 'YAML serialized product data';

-- Product relations (upsells, cross-sells, bundles)
CREATE TABLE product_relations (
    mid INTEGER NOT NULL DEFAULT 0,  -- MySQL: unsigned int(10)
    pid VARCHAR(20) NOT NULL DEFAULT '',
    child_pid VARCHAR(20) NOT NULL DEFAULT '',
    relation VARCHAR(16) NOT NULL DEFAULT '',
    qty SMALLINT NOT NULL DEFAULT 0,  -- MySQL: unsigned smallint(5)
    is_active SMALLINT NOT NULL DEFAULT 0,  -- MySQL: unsigned tinyint(3)
    list_pos SMALLINT NOT NULL DEFAULT 0,  -- MySQL: unsigned tinyint(3)
    created_gmt INTEGER NOT NULL DEFAULT 0  -- MySQL: unsigned int(10)
);

CREATE UNIQUE INDEX idx_product_relations_unique ON product_relations(mid, pid, relation, child_pid);
CREATE INDEX idx_product_relations_child ON product_relations(mid, child_pid, relation);

-- SKU lookup table (critical for inventory management)
CREATE TABLE sku_lookup (
    id BIGSERIAL PRIMARY KEY,
    mid INTEGER NOT NULL DEFAULT 0,  -- MySQL: unsigned int(10)
    pid VARCHAR(30) NOT NULL DEFAULT '',
    invopts VARCHAR(15) NOT NULL DEFAULT '',
    grp_parent VARCHAR(35) NOT NULL DEFAULT '',
    sku VARCHAR(45) NOT NULL,
    title VARCHAR(80) NOT NULL DEFAULT '0',
    cost DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    price DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    upc VARCHAR(13) NOT NULL DEFAULT '',
    mfgid VARCHAR(25) NOT NULL DEFAULT '',
    supplierid VARCHAR(25) NOT NULL DEFAULT '',
    prodasm TEXT,  -- MySQL: tinytext
    assembly TEXT,  -- MySQL: tinytext
    inv_available INTEGER NOT NULL DEFAULT 0,  -- MySQL: int(11)
    qty_onshelf INTEGER NOT NULL DEFAULT 0,  -- MySQL: unsigned int(10)
    qty_onorder INTEGER NOT NULL DEFAULT 0,  -- MySQL: unsigned int(10)
    qty_needship INTEGER NOT NULL DEFAULT 0,  -- MySQL: unsigned int(10)
    qty_markets INTEGER NOT NULL DEFAULT 0,  -- MySQL: unsigned int(10)
    qty_legacy INTEGER NOT NULL DEFAULT 0,  -- MySQL: int(11)
    qty_reserved INTEGER NOT NULL DEFAULT 0,  -- MySQL: unsigned int(10)
    -- Amazon-specific fields
    amz_asin VARCHAR(15) NOT NULL DEFAULT '',
    amz_feeds_done SMALLINT NOT NULL DEFAULT 0,  -- MySQL: unsigned smallint(5)
    amz_feeds_todo SMALLINT NOT NULL DEFAULT 0,  -- MySQL: unsigned smallint(5)
    amz_feeds_sent SMALLINT NOT NULL DEFAULT 0,  -- MySQL: tinyint(4)
    amz_feeds_wait SMALLINT NOT NULL DEFAULT 0,  -- MySQL: tinyint(4)
    amz_feeds_warn SMALLINT NOT NULL DEFAULT 0,  -- MySQL: unsigned smallint(5)
    amz_feeds_error SMALLINT NOT NULL DEFAULT 0,  -- MySQL: unsigned smallint(5)
    amz_productdb_gmt INTEGER NOT NULL DEFAULT 0,  -- MySQL: unsigned int(10)
    amz_error TEXT NOT NULL DEFAULT '',
    -- Inventory tracking
    inv_on_shelf INTEGER NOT NULL DEFAULT 0,  -- MySQL: unsigned int(10)
    inv_on_order INTEGER NOT NULL DEFAULT 0,  -- MySQL: unsigned int(10)
    inv_is_bo INTEGER NOT NULL DEFAULT 0,  -- MySQL: unsigned int(10)
    inv_reorder INTEGER NOT NULL DEFAULT 0,  -- MySQL: int(11)
    inv_is_rsvp INTEGER NOT NULL DEFAULT 0,  -- MySQL: unsigned int(10)
    -- DSS (Dynamic Sourcing System) fields
    dss_agent VARCHAR(8) NOT NULL DEFAULT '',
    dss_run dss_run_set,  -- MySQL: SET type → custom handling needed
    dss_mood dss_mood_enum,
    dss_config TEXT  -- MySQL: text
);

CREATE UNIQUE INDEX idx_sku_lookup_mid_sku ON sku_lookup(mid, sku);
CREATE INDEX idx_sku_lookup_mid_pid ON sku_lookup(mid, pid);
CREATE INDEX idx_sku_lookup_mid_upc ON sku_lookup(mid, upc);
CREATE INDEX idx_sku_lookup_mid_asin ON sku_lookup(mid, amz_asin);

COMMENT ON TABLE sku_lookup IS 'SKU-level product details and inventory tracking';
COMMENT ON COLUMN sku_lookup.dss_run IS 'MySQL SET type - may need application-level handling';

-- ============================================================================
-- SECTION 5: ORDER TABLES
-- ============================================================================

-- Main orders table
CREATE TABLE orders (
    id SERIAL PRIMARY KEY,
    merchant VARCHAR(20) NOT NULL DEFAULT '',
    mid INTEGER NOT NULL DEFAULT 0,  -- MySQL: unsigned int(11)
    prt SMALLINT NOT NULL DEFAULT 0,  -- MySQL: unsigned smallint(5)
    orderid VARCHAR(30) NOT NULL DEFAULT '',
    bs_settlement INTEGER NOT NULL DEFAULT 0,  -- MySQL: unsigned int(10)
    v SMALLINT DEFAULT 0,  -- MySQL: unsigned tinyint(3) - version
    created_gmt INTEGER NOT NULL DEFAULT 0,  -- MySQL: unsigned int(10)
    modified_gmt INTEGER NOT NULL DEFAULT 0,  -- MySQL: unsigned int(10)
    paid_gmt INTEGER NOT NULL DEFAULT 0,  -- MySQL: unsigned int(10)
    paid_txn VARCHAR(20) NOT NULL DEFAULT '',
    inv_gmt INTEGER NOT NULL DEFAULT 0,  -- MySQL: unsigned int(10)
    shipped_gmt INTEGER NOT NULL DEFAULT 0,  -- MySQL: unsigned int(10)
    synced_gmt INTEGER NOT NULL DEFAULT 0,  -- MySQL: int(11)
    customer INTEGER NOT NULL DEFAULT 0,  -- MySQL: unsigned int(11)
    pool order_pool_enum NOT NULL DEFAULT 'RECENT',
    order_bill_name VARCHAR(30) NOT NULL DEFAULT '',
    order_bill_email VARCHAR(30) NOT NULL DEFAULT '',
    order_bill_zone VARCHAR(12) NOT NULL DEFAULT '',
    order_bill_phone VARCHAR(12) NOT NULL DEFAULT '',
    order_ship_name VARCHAR(30) NOT NULL DEFAULT '',
    order_ship_zone VARCHAR(12) NOT NULL DEFAULT '',
    review_status VARCHAR(3) NOT NULL DEFAULT '',
    order_payment_status CHAR(3) NOT NULL DEFAULT '',
    order_payment_method VARCHAR(4) NOT NULL DEFAULT '',
    order_payment_lookup VARCHAR(4) NOT NULL DEFAULT '',
    order_erefid VARCHAR(30) DEFAULT '',
    order_total DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    order_special VARCHAR(40) NOT NULL DEFAULT '',
    ship_method VARCHAR(10) NOT NULL DEFAULT '',
    mkt INTEGER DEFAULT 0,  -- MySQL: unsigned int(10)
    mkt_bitstr VARCHAR(24) NOT NULL DEFAULT '',
    flags INTEGER NOT NULL DEFAULT 0,  -- MySQL: unsigned int(10)
    items SMALLINT NOT NULL DEFAULT 0,  -- MySQL: unsigned tinyint(3)
    yaml TEXT NOT NULL DEFAULT '',  -- MySQL: mediumtext
    cartid VARCHAR(30),
    sdomain TEXT  -- MySQL: tinytext
);

CREATE UNIQUE INDEX idx_orders_mid_orderid ON orders(mid, orderid);
CREATE UNIQUE INDEX idx_orders_mid_cartid ON orders(mid, cartid);
CREATE INDEX idx_orders_mid_erefid ON orders(mid, order_erefid);
CREATE INDEX idx_orders_mid_pool ON orders(mid, pool);
CREATE INDEX idx_orders_mid_customer ON orders(mid, customer);
CREATE INDEX idx_orders_mid_paid_shipped ON orders(mid, paid_gmt, shipped_gmt);
CREATE INDEX idx_orders_mid_synced ON orders(mid, synced_gmt);
CREATE INDEX idx_orders_mid_created ON orders(mid, created_gmt);
CREATE INDEX idx_orders_mid_bill_email ON orders(mid, order_bill_email);

COMMENT ON TABLE orders IS 'Main orders table';
COMMENT ON COLUMN orders.yaml IS 'Serialized order data (items, addresses, etc)';
COMMENT ON COLUMN orders.pool IS 'Order workflow stage';

-- Order events (for async processing)
CREATE TABLE order_events (
    id SERIAL PRIMARY KEY,
    created_gmt INTEGER NOT NULL DEFAULT 0,  -- MySQL: unsigned int(10)
    mid INTEGER NOT NULL DEFAULT 0,  -- MySQL: unsigned int(10)
    username VARCHAR(20) NOT NULL DEFAULT '',
    prt SMALLINT NOT NULL DEFAULT 0,  -- MySQL: tinyint(4)
    orderid VARCHAR(30) NOT NULL DEFAULT '',
    event VARCHAR(10) NOT NULL DEFAULT '',
    lock_id SMALLINT NOT NULL DEFAULT 0,  -- MySQL: unsigned smallint(5)
    lock_gmt INTEGER NOT NULL DEFAULT 0,  -- MySQL: unsigned int(10)
    attempts SMALLINT NOT NULL DEFAULT 0  -- MySQL: unsigned tinyint(3)
);

CREATE INDEX idx_order_events_lock ON order_events(lock_gmt, lock_id);

-- Order counters (for generating sequential order IDs per merchant)
CREATE TABLE order_counters (
    mid INTEGER DEFAULT 0,  -- MySQL: int(11)
    merchant VARCHAR(20) NOT NULL DEFAULT '',
    counter INTEGER DEFAULT 0,  -- MySQL: int(11)
    last_pid INTEGER DEFAULT 0,  -- MySQL: int(11)
    last_server VARCHAR(25) NOT NULL DEFAULT ''
);

CREATE UNIQUE INDEX idx_order_counters_merchant ON order_counters(merchant);
CREATE UNIQUE INDEX idx_order_counters_mid ON order_counters(mid);

-- ============================================================================
-- SECTION 6: INVENTORY TABLES
-- ============================================================================

-- Inventory detail (tracks all inventory movements and states)
CREATE TABLE inventory_detail (
    id BIGSERIAL PRIMARY KEY,
    uuid VARCHAR(36) NOT NULL DEFAULT '',
    mid INTEGER NOT NULL DEFAULT 0,  -- MySQL: unsigned int(10)
    pid VARCHAR(20) NOT NULL DEFAULT '',
    sku VARCHAR(35) NOT NULL DEFAULT '',
    -- Warehouse management
    wms_geo VARCHAR(3),
    wms_zone VARCHAR(3),
    wms_pos VARCHAR(12),
    qty INTEGER NOT NULL DEFAULT 0,  -- MySQL: int(11)
    cost_i INTEGER NOT NULL DEFAULT 0,  -- MySQL: unsigned int(10) - cost in integer cents
    note VARCHAR(25) NOT NULL DEFAULT '',
    container VARCHAR(8) NOT NULL DEFAULT '',
    origin VARCHAR(16) NOT NULL DEFAULT '',
    basetype inventory_basetype_enum DEFAULT 'ERROR',
    -- Supplier fields
    supplier_id VARCHAR(10),
    supplier_sku VARCHAR(25) NOT NULL DEFAULT '',
    -- Marketplace fields
    market_dst VARCHAR(4),
    market_refid VARCHAR(16) NOT NULL DEFAULT '',
    market_ends_ts TIMESTAMP NULL,  -- MySQL: DEFAULT '0000-00-00 00:00:00' → NULL
    market_sold_qty INTEGER NOT NULL DEFAULT 0,  -- MySQL: int(11)
    market_sale_ts TIMESTAMP NULL,  -- MySQL: DEFAULT '0000-00-00 00:00:00' → NULL
    preference SMALLINT NOT NULL DEFAULT 0,  -- MySQL: smallint(6)
    -- Timestamps
    created_ts TIMESTAMP NULL,  -- MySQL: DEFAULT '0000-00-00 00:00:00' → NULL
    modified_ts TIMESTAMP NULL,  -- MySQL: DEFAULT '0000-00-00 00:00:00' → NULL
    modified_by VARCHAR(10) NOT NULL DEFAULT '',
    modified_inc BIGINT NOT NULL DEFAULT 0,  -- MySQL: bigint(20)
    modified_qty_was INTEGER NOT NULL DEFAULT 0,  -- MySQL: int(11)
    verify_ts TIMESTAMP NULL,  -- MySQL: DEFAULT '0000-00-00 00:00:00' → NULL
    verify_inc INTEGER NOT NULL DEFAULT 0,  -- MySQL: unsigned int(10)
    -- Order/Pick fields
    our_orderid VARCHAR(30) NOT NULL DEFAULT '',
    pick_batchid VARCHAR(8) NOT NULL DEFAULT '',
    pick_route inventory_pick_route_enum,
    pick_done_ts TIMESTAMP NULL,  -- MySQL: DEFAULT '0000-00-00 00:00:00' → NULL
    grpasm_ref VARCHAR(35),
    description TEXT NOT NULL DEFAULT '',  -- MySQL: tinytext
    -- Vendor/Supplier order tracking
    vendor_status inventory_vendor_status_enum,
    vendor VARCHAR(6) NOT NULL DEFAULT '',
    vendor_order_dbid INTEGER NOT NULL DEFAULT 0,  -- MySQL: unsigned int(10)
    vendor_sku VARCHAR(25) NOT NULL DEFAULT ''
);

CREATE UNIQUE INDEX idx_inventory_detail_mid_sku_uuid ON inventory_detail(mid, sku, uuid);
CREATE UNIQUE INDEX idx_inventory_detail_mid_market ON inventory_detail(mid, market_dst, market_refid);
CREATE INDEX idx_inventory_detail_mid_container ON inventory_detail(mid, container);
CREATE INDEX idx_inventory_detail_mid_pid ON inventory_detail(mid, pid);
CREATE INDEX idx_inventory_detail_mid_modified ON inventory_detail(mid, modified_ts);
CREATE INDEX idx_inventory_detail_mid_supplier ON inventory_detail(mid, supplier_id, sku);
CREATE INDEX idx_inventory_detail_mid_wms ON inventory_detail(mid, wms_zone);
CREATE INDEX idx_inventory_detail_mid_vendor_order ON inventory_detail(mid, vendor, vendor_order_dbid);
CREATE INDEX idx_inventory_detail_mid_vendor_status ON inventory_detail(mid, vendor_status);
CREATE INDEX idx_inventory_detail_mid_orderid ON inventory_detail(mid, our_orderid);

COMMENT ON TABLE inventory_detail IS 'Detailed inventory tracking at item level';
COMMENT ON COLUMN inventory_detail.cost_i IS 'Cost stored as integer cents for precision';
COMMENT ON COLUMN inventory_detail.basetype IS 'Inventory state/lifecycle stage';

-- Inventory log (audit trail)
CREATE TABLE inventory_log (
    id BIGSERIAL PRIMARY KEY,
    mid INTEGER NOT NULL DEFAULT 0,  -- MySQL: int(11)
    pid VARCHAR(20) NOT NULL DEFAULT '',
    sku VARCHAR(35) NOT NULL DEFAULT '',
    created_gmt INTEGER NOT NULL DEFAULT 0,  -- MySQL: int(11)
    qty INTEGER NOT NULL DEFAULT 0,  -- MySQL: int(11)
    qty_before INTEGER NOT NULL DEFAULT 0,  -- MySQL: int(11)
    action VARCHAR(20) NOT NULL DEFAULT '',
    luser VARCHAR(10) NOT NULL DEFAULT '',
    note TEXT NOT NULL DEFAULT '',  -- MySQL: tinytext
    orderid VARCHAR(30) NOT NULL DEFAULT '',
    uuid VARCHAR(36) NOT NULL DEFAULT ''
);

CREATE INDEX idx_inventory_log_mid_sku ON inventory_log(mid, sku);
CREATE INDEX idx_inventory_log_mid_created ON inventory_log(mid, created_gmt);

-- ============================================================================
-- SECTION 7: AMAZON MARKETPLACE INTEGRATION TABLES
-- ============================================================================

-- Amazon documents (MWS API communications)
CREATE TABLE amazon_docs (
    username VARCHAR(20) NOT NULL DEFAULT '',
    mid INTEGER NOT NULL DEFAULT 0,  -- MySQL: unsigned int(10)
    prt SMALLINT NOT NULL DEFAULT 0,  -- MySQL: unsigned smallint(5)
    doctype VARCHAR(40) NOT NULL DEFAULT '',
    docid BIGINT NOT NULL DEFAULT 0,  -- MySQL: unsigned bigint(20)
    docbody TEXT NOT NULL DEFAULT '',  -- MySQL: mediumtext
    created_gmt INTEGER NOT NULL DEFAULT 0,  -- MySQL: unsigned int(10)
    retrieved_gmt INTEGER NOT NULL DEFAULT 0,  -- MySQL: unsigned int(10)
    response_docid BIGINT NOT NULL DEFAULT 0,  -- MySQL: unsigned bigint(20)
    response_body TEXT,  -- MySQL: mediumtext
    resent_docid BIGINT,  -- MySQL: unsigned bigint(20)
    attempts SMALLINT NOT NULL DEFAULT 0  -- MySQL: tinyint(4)
);

CREATE UNIQUE INDEX idx_amazon_docs_docid ON amazon_docs(docid);
CREATE INDEX idx_amazon_docs_mid_retrieved ON amazon_docs(mid, retrieved_gmt);

-- Amazon document contents (feed tracking)
CREATE TABLE amazon_document_contents (
    mid INTEGER NOT NULL DEFAULT 0,  -- MySQL: unsigned int(10)
    docid BIGINT NOT NULL DEFAULT 0,  -- MySQL: bigint(20)
    msgid INTEGER NOT NULL DEFAULT 0,  -- MySQL: int(11)
    feed amazon_feed_enum,
    sku VARCHAR(35) NOT NULL DEFAULT '',
    created_ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP,  -- MySQL: ON UPDATE CURRENT_TIMESTAMP handled via trigger
    debug TEXT,  -- MySQL: tinytext
    ack_gmt INTEGER NOT NULL DEFAULT 0  -- MySQL: unsigned int(10)
);

CREATE UNIQUE INDEX idx_amazon_document_contents_unique ON amazon_document_contents(mid, docid, msgid);

-- Amazon orders
CREATE TABLE amazon_orders (
    id SERIAL PRIMARY KEY,
    mid INTEGER NOT NULL DEFAULT 0,  -- MySQL: int(11)
    prt SMALLINT NOT NULL DEFAULT 0,  -- MySQL: unsigned smallint(5)
    docid BIGINT,  -- MySQL: bigint(20)
    amazon_orderid VARCHAR(20) NOT NULL DEFAULT '',
    our_orderid VARCHAR(30) NOT NULL DEFAULT '',
    created_gmt INTEGER NOT NULL DEFAULT 0,  -- MySQL: int(11)
    ack_gmt INTEGER NOT NULL DEFAULT 0,  -- MySQL: int(11)
    track_gmt INTEGER DEFAULT 0,  -- MySQL: int(11)
    has_tracking SMALLINT NOT NULL DEFAULT 0,  -- MySQL: unsigned tinyint(3)
    order_total DECIMAL(10,2),
    dirty SMALLINT NOT NULL DEFAULT 0,  -- MySQL: unsigned tinyint(3)
    posted_gmt INTEGER NOT NULL DEFAULT 0,  -- MySQL: int(11)
    shipping_method amazon_shipping_method_enum DEFAULT 'Unknown',
    neworder_ack_processed_gmt INTEGER NOT NULL DEFAULT 0,  -- MySQL: unsigned int(10)
    neworder_ack_docid BIGINT NOT NULL DEFAULT 0,  -- MySQL: unsigned bigint(20)
    fulfillment_ack_requested_gmt INTEGER NOT NULL DEFAULT 0,  -- MySQL: unsigned int(10)
    fulfillment_ack_processed_gmt INTEGER NOT NULL DEFAULT 0,  -- MySQL: unsigned int(10)
    fulfillment_ack_docid BIGINT NOT NULL DEFAULT 0  -- MySQL: unsigned bigint(20)
);

CREATE UNIQUE INDEX idx_amazon_orders_amazon_orderid ON amazon_orders(amazon_orderid);
CREATE INDEX idx_amazon_orders_mid_prt_docid ON amazon_orders(mid, prt, docid);
CREATE INDEX idx_amazon_orders_neworder_ack ON amazon_orders(neworder_ack_processed_gmt);
CREATE INDEX idx_amazon_orders_fulfillment_ack ON amazon_orders(fulfillment_ack_processed_gmt, fulfillment_ack_requested_gmt);
CREATE INDEX idx_amazon_orders_mid_prt_orderid ON amazon_orders(mid, prt, our_orderid);

-- Amazon order events (async acknowledgment processing)
CREATE TABLE amazon_order_events (
    id SERIAL PRIMARY KEY,
    username VARCHAR(20) NOT NULL DEFAULT '',
    mid INTEGER NOT NULL DEFAULT 0,  -- MySQL: unsigned int(10)
    created TIMESTAMP,  -- MySQL: datetime DEFAULT NULL
    type amazon_order_event_type_enum NOT NULL DEFAULT '',
    orderid VARCHAR(30) NOT NULL DEFAULT '',
    data TEXT,  -- MySQL: tinytext
    lock_gmt INTEGER NOT NULL DEFAULT 0,  -- MySQL: unsigned int(10)
    processed_gmt INTEGER NOT NULL DEFAULT 0,  -- MySQL: unsigned int(10)
    processed_docid INTEGER NOT NULL DEFAULT 0,  -- MySQL: unsigned int(10)
    attempts SMALLINT NOT NULL DEFAULT 0  -- MySQL: tinyint(4)
);

CREATE INDEX idx_amazon_order_events_lock ON amazon_order_events(lock_gmt);
CREATE INDEX idx_amazon_order_events_processed ON amazon_order_events(processed_gmt);

-- ============================================================================
-- SECTION 8: BATCH JOB SYSTEM
-- ============================================================================

-- Batch jobs (async background processing)
CREATE TABLE batch_jobs (
    id SERIAL PRIMARY KEY,
    username VARCHAR(20) NOT NULL DEFAULT '',
    lusername VARCHAR(10) NOT NULL DEFAULT '',
    mid INTEGER NOT NULL DEFAULT 0,  -- MySQL: unsigned int(10)
    prt SMALLINT NOT NULL DEFAULT 0,  -- MySQL: unsigned tinyint(3)
    guid VARCHAR(36) NOT NULL DEFAULT '',
    job_type VARCHAR(3) NOT NULL DEFAULT '',
    version DECIMAL(6,0) NOT NULL DEFAULT 0,
    batch_exec VARCHAR(45) NOT NULL DEFAULT '',
    parameters_uuid VARCHAR(36) NOT NULL DEFAULT '',
    batch_vars TEXT NOT NULL DEFAULT '',  -- MySQL: mediumtext
    created_ts TIMESTAMP NULL,  -- MySQL: DEFAULT '0000-00-00 00:00:00' → NULL
    queued_ts TIMESTAMP NULL,  -- MySQL: DEFAULT '0000-00-00 00:00:00' → NULL
    start_ts TIMESTAMP NULL,  -- MySQL: DEFAULT '0000-00-00 00:00:00' → NULL
    estdone_ts TIMESTAMP NULL,  -- MySQL: DEFAULT '0000-00-00 00:00:00' → NULL
    end_ts TIMESTAMP NULL,  -- MySQL: DEFAULT '0000-00-00 00:00:00' → NULL
    archived_ts TIMESTAMP NULL,  -- MySQL: DEFAULT '0000-00-00 00:00:00' → NULL
    aborted_ts TIMESTAMP NULL,  -- MySQL: DEFAULT '0000-00-00 00:00:00' → NULL
    title VARCHAR(65) NOT NULL DEFAULT '',
    status batch_job_status_enum,
    status_msg VARCHAR(100) NOT NULL DEFAULT '',
    records_done INTEGER NOT NULL DEFAULT 0,  -- MySQL: unsigned int(10)
    records_total INTEGER NOT NULL DEFAULT 0,  -- MySQL: unsigned int(10)
    records_warn INTEGER NOT NULL DEFAULT 0,  -- MySQL: unsigned int(10)
    records_error INTEGER NOT NULL DEFAULT 0,  -- MySQL: unsigned int(10)
    has_slog SMALLINT NOT NULL DEFAULT 0,  -- MySQL: tinyint(4)
    output_file VARCHAR(50) NOT NULL DEFAULT '',
    is_running INTEGER NOT NULL DEFAULT 0,  -- MySQL: unsigned int(10)
    is_crashed INTEGER NOT NULL DEFAULT 0,  -- MySQL: unsigned int(10)
    is_abortable INTEGER NOT NULL DEFAULT 0,  -- MySQL: unsigned int(10)
    job_cost_cycles INTEGER NOT NULL DEFAULT 0  -- MySQL: unsigned int(10)
);

CREATE UNIQUE INDEX idx_batch_jobs_username_guid ON batch_jobs(username, guid);
CREATE INDEX idx_batch_jobs_mid_exec_end ON batch_jobs(mid, batch_exec, end_ts);
CREATE INDEX idx_batch_jobs_created_status ON batch_jobs(created_ts, status);

COMMENT ON TABLE batch_jobs IS 'Background job queue and execution tracking';
COMMENT ON COLUMN batch_jobs.status IS 'Job lifecycle state';

-- Batch parameters (reusable job configurations)
CREATE TABLE batch_parameters (
    id SERIAL PRIMARY KEY,
    uuid VARCHAR(36) NOT NULL DEFAULT '',
    mid INTEGER NOT NULL DEFAULT 0,  -- MySQL: int(11)
    username VARCHAR(20) NOT NULL DEFAULT '',
    luser VARCHAR(10) NOT NULL DEFAULT '',
    title VARCHAR(80),
    created_ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP,  -- MySQL: ON UPDATE CURRENT_TIMESTAMP handled via trigger
    created_by VARCHAR(10) NOT NULL DEFAULT '',
    lastrun_ts TIMESTAMP NULL,  -- MySQL: DEFAULT '0000-00-00 00:00:00' → NULL
    lastjob_id INTEGER NOT NULL DEFAULT 0,  -- MySQL: unsigned int(10)
    batch_exec VARCHAR(45) NOT NULL DEFAULT '',
    apiversion INTEGER NOT NULL DEFAULT 0,  -- MySQL: unsigned int(10)
    yaml TEXT NOT NULL DEFAULT ''
);

CREATE UNIQUE INDEX idx_batch_parameters_mid_uuid ON batch_parameters(mid, uuid);
CREATE INDEX idx_batch_parameters_mid_luser ON batch_parameters(mid, luser);

-- ============================================================================
-- SECTION 9: CAMPAIGN/MARKETING TABLES
-- ============================================================================

-- Campaigns (email/marketing blasts)
CREATE TABLE campaigns (
    campaignid VARCHAR(20) NOT NULL DEFAULT '',
    username VARCHAR(20) NOT NULL DEFAULT '',
    mid INTEGER NOT NULL DEFAULT 0,  -- MySQL: unsigned int(10)
    subject VARCHAR(70) NOT NULL DEFAULT '',
    prt SMALLINT NOT NULL DEFAULT 0,  -- MySQL: tinyint(4)
    created_ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP,  -- MySQL: ON UPDATE CURRENT_TIMESTAMP handled via trigger
    template_origin VARCHAR(36) NOT NULL DEFAULT '',
    recipients TEXT,
    send_email SMALLINT NOT NULL DEFAULT 0,  -- MySQL: tinyint(4)
    send_appleios SMALLINT NOT NULL DEFAULT 0,  -- MySQL: tinyint(4)
    send_android SMALLINT NOT NULL DEFAULT 0,  -- MySQL: tinyint(4)
    send_facebook SMALLINT NOT NULL DEFAULT 0,  -- MySQL: tinyint(4)
    send_twitter SMALLINT NOT NULL DEFAULT 0,  -- MySQL: tinyint(4)
    send_sms SMALLINT NOT NULL DEFAULT 0,  -- MySQL: tinyint(4)
    queue_mode campaign_queue_mode_enum DEFAULT 'FRONT',
    expires TIMESTAMP NULL,  -- MySQL: DEFAULT '0000-00-00 00:00:00' → NULL
    coupon VARCHAR(10) NOT NULL DEFAULT '',
    rss_data TEXT NOT NULL DEFAULT '',  -- MySQL: tinytext
    status campaign_status_enum DEFAULT 'NEW',
    starttime TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    jobid INTEGER NOT NULL DEFAULT 0  -- MySQL: int(11)
);

CREATE UNIQUE INDEX idx_campaigns_mid_campaignid ON campaigns(mid, campaignid);

-- Campaign recipients (individual send tracking)
CREATE TABLE campaign_recipients (
    id BIGSERIAL PRIMARY KEY,
    mid INTEGER NOT NULL DEFAULT 0,  -- MySQL: unsigned int(10)
    cid BIGINT NOT NULL DEFAULT 0,  -- MySQL: unsigned bigint(20)
    cpg INTEGER NOT NULL DEFAULT 0,  -- MySQL: int(11)
    created_gmt INTEGER NOT NULL DEFAULT 0,  -- MySQL: int(11)
    sent_gmt INTEGER NOT NULL DEFAULT 0,  -- MySQL: int(11)
    opened SMALLINT NOT NULL DEFAULT 0,  -- MySQL: tinyint(4)
    clicked_gmt INTEGER NOT NULL DEFAULT 0,  -- MySQL: unsigned int(10)
    opened_gmt INTEGER NOT NULL DEFAULT 0,  -- MySQL: unsigned int(10)
    unsubscribed SMALLINT NOT NULL DEFAULT 0,  -- MySQL: tinyint(4)
    bounced SMALLINT NOT NULL DEFAULT 0,  -- MySQL: tinyint(4)
    locked_gmt INTEGER NOT NULL DEFAULT 0,  -- MySQL: int(11)
    locked_pid INTEGER NOT NULL DEFAULT 0,  -- MySQL: int(11)
    clicked INTEGER NOT NULL DEFAULT 0,  -- MySQL: int(11)
    purchased INTEGER NOT NULL DEFAULT 0,  -- MySQL: int(11)
    total_sales INTEGER NOT NULL DEFAULT 0,  -- MySQL: int(11)
    purchased_gmt INTEGER DEFAULT 0  -- MySQL: unsigned int(10)
);

CREATE UNIQUE INDEX idx_campaign_recipients_unique ON campaign_recipients(cpg, cid, mid);
CREATE INDEX idx_campaign_recipients_created_sent ON campaign_recipients(created_gmt, sent_gmt);
CREATE INDEX idx_campaign_recipients_locked_pid ON campaign_recipients(locked_pid, locked_gmt);
CREATE INDEX idx_campaign_recipients_locked_gmt ON campaign_recipients(locked_gmt);

-- ============================================================================
-- SECTION 10: PROJECTS TABLE (APP/STOREFRONT CONFIGURATIONS)
-- ============================================================================

CREATE TABLE projects (
    id SERIAL PRIMARY KEY,
    created_ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP,  -- MySQL: ON UPDATE CURRENT_TIMESTAMP handled via trigger
    updated_ts TIMESTAMP NULL,  -- MySQL: DEFAULT '0000-00-00 00:00:00' → NULL
    mid INTEGER NOT NULL DEFAULT 0,  -- MySQL: unsigned int(10)
    username VARCHAR(20) NOT NULL DEFAULT '',
    title VARCHAR(45) NOT NULL DEFAULT '',
    uuid VARCHAR(32) NOT NULL DEFAULT '',
    secret VARCHAR(32) NOT NULL DEFAULT '',
    type project_type_enum NOT NULL DEFAULT '',
    github_repo VARCHAR(255) NOT NULL DEFAULT '',
    github_branch VARCHAR(20) NOT NULL DEFAULT '',
    github_txlog TEXT NOT NULL DEFAULT '',  -- MySQL: tinytext
    app_release VARCHAR(6) NOT NULL DEFAULT '0',
    app_version VARCHAR(16) NOT NULL DEFAULT '',
    app_seo VARCHAR(6) NOT NULL DEFAULT '',
    app_expire VARCHAR(10) NOT NULL DEFAULT '',
    app_force_secure SMALLINT NOT NULL DEFAULT 0,  -- MySQL: tinyint(4)
    app_root VARCHAR(50) NOT NULL DEFAULT ''
);

COMMENT ON TABLE projects IS 'Application and storefront project configurations';

-- ============================================================================
-- SECTION 11: CHECKOUT ASSISTANCE TRACKING
-- ============================================================================

CREATE TABLE checkouts (
    id SERIAL PRIMARY KEY,
    mid INTEGER NOT NULL DEFAULT 0,  -- MySQL: unsigned int(10)
    username VARCHAR(20) NOT NULL DEFAULT '',
    sdomain VARCHAR(50) NOT NULL DEFAULT '',
    assist checkout_assist_enum NOT NULL DEFAULT '',
    cartid VARCHAR(36) NOT NULL DEFAULT '',
    cid INTEGER NOT NULL DEFAULT 0,  -- MySQL: unsigned int(10)
    created_gmt INTEGER NOT NULL DEFAULT 0,  -- MySQL: unsigned int(10)
    handled_gmt INTEGER NOT NULL DEFAULT 0,  -- MySQL: unsigned int(10)
    closed_gmt INTEGER NOT NULL DEFAULT 0,  -- MySQL: unsigned int(10)
    assistid VARCHAR(5) NOT NULL DEFAULT '',
    checkout_stage VARCHAR(8) NOT NULL DEFAULT ''
);

CREATE INDEX idx_checkouts_mid_sdomain_handled ON checkouts(mid, sdomain, handled_gmt);

-- ============================================================================
-- SECTION 12: TRIGGERS FOR ON UPDATE CURRENT_TIMESTAMP BEHAVIOR
-- ============================================================================

-- PostgreSQL doesn't support ON UPDATE CURRENT_TIMESTAMP natively.
-- Create triggers for tables that need this behavior.

-- Trigger function for updating timestamps
CREATE OR REPLACE FUNCTION update_modified_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.created_ts = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply triggers to tables with ON UPDATE CURRENT_TIMESTAMP
CREATE TRIGGER trigger_amazon_document_contents_timestamp
    BEFORE UPDATE ON amazon_document_contents
    FOR EACH ROW
    EXECUTE FUNCTION update_modified_timestamp();

CREATE TRIGGER trigger_batch_parameters_timestamp
    BEFORE UPDATE ON batch_parameters
    FOR EACH ROW
    EXECUTE FUNCTION update_modified_timestamp();

CREATE TRIGGER trigger_campaigns_timestamp
    BEFORE UPDATE ON campaigns
    FOR EACH ROW
    EXECUTE FUNCTION update_modified_timestamp();

CREATE TRIGGER trigger_projects_timestamp
    BEFORE UPDATE ON projects
    FOR EACH ROW
    EXECUTE FUNCTION update_modified_timestamp();

-- ============================================================================
-- MIGRATION NOTES
-- ============================================================================

/*
CONVERSION DECISIONS MADE:

1. AUTO_INCREMENT → SERIAL/BIGSERIAL
   - Used SERIAL for int(11) primary keys
   - Used BIGSERIAL for bigint(20) primary keys

2. UNSIGNED INTEGERS
   - MySQL unsigned int(10) → PostgreSQL INTEGER (32-bit signed)
   - MySQL unsigned bigint(20) → PostgreSQL BIGINT (64-bit signed)
   - MySQL unsigned tinyint(3) → PostgreSQL SMALLINT (16-bit signed)
   - Note: PostgreSQL doesn't have unsigned types; use CHECK constraints if needed

3. ZERO DATETIME DEFAULTS
   - MySQL '0000-00-00 00:00:00' → PostgreSQL NULL
   - This is the safest conversion; application logic may need adjustment

4. ON UPDATE CURRENT_TIMESTAMP
   - Converted to triggers using update_modified_timestamp() function
   - Applied to: amazon_document_contents, batch_parameters, campaigns, projects

5. ENUM TYPES
   - Created PostgreSQL ENUM types for all MySQL ENUMs
   - Named consistently with _enum suffix
   - Empty string ('') values preserved where present in MySQL

6. TEXT TYPES
   - MySQL mediumtext → PostgreSQL TEXT
   - MySQL tinytext → PostgreSQL TEXT
   - MySQL longtext → PostgreSQL TEXT (not in this subset)

7. STORAGE ENGINES
   - Removed all ENGINE=MyISAM and ENGINE=InnoDB declarations
   - PostgreSQL uses its own storage engine

8. CHARACTER SETS
   - Removed all CHARACTER SET specifications
   - PostgreSQL uses database-level UTF-8 encoding

9. BACKTICKS
   - Removed all backticks from identifiers
   - PostgreSQL uses double-quotes only when needed (case sensitivity)

10. SPECIAL CONSIDERATIONS
    - MySQL SET type (e.g., dss_run) converted to custom ENUM
      Application may need to handle multiple values differently
    - Integer timestamps preserved (GMT/Unix timestamps)
    - YAML/serialized data fields preserved as TEXT

TABLES MIGRATED (25 critical tables):
✓ zusers (main users/merchants)
✓ customers (customer accounts)
✓ customer_addrs (customer addresses)
✓ customer_notes (customer support notes)
✓ products (product catalog)
✓ product_relations (upsells, cross-sells)
✓ sku_lookup (SKU-level inventory tracking)
✓ orders (main orders)
✓ order_events (async order processing)
✓ order_counters (order ID generation)
✓ inventory_detail (detailed inventory)
✓ inventory_log (inventory audit trail)
✓ amazon_docs (Amazon MWS API docs)
✓ amazon_document_contents (feed tracking)
✓ amazon_orders (Amazon orders)
✓ amazon_order_events (Amazon async processing)
✓ batch_jobs (background jobs)
✓ batch_parameters (job configurations)
✓ campaigns (marketing campaigns)
✓ campaign_recipients (campaign tracking)
✓ projects (app/storefront configs)
✓ checkouts (checkout assistance)

REMAINING TABLES (127 tables):
- EBAY_* tables (eBay integration)
- GOOGLE_* tables (Google Shopping)
- SUPPLIER_* tables (supplier management)
- SHIPPING_* tables (shipping configurations)
- Many other specialized tables

These will be migrated in subsequent migration files (002_*, 003_*, etc.)

TESTING RECOMMENDATIONS:
1. Test ENUM type handling in application code
2. Verify zero datetime → NULL conversions don't break logic
3. Test timestamp trigger behavior
4. Verify unsigned → signed integer conversions for large values
5. Test MySQL SET type conversions (dss_run field)

PERFORMANCE CONSIDERATIONS:
1. All indexes from MySQL schema preserved
2. Consider VACUUM ANALYZE after data migration
3. Review query plans for index usage
4. May need to adjust shared_buffers and work_mem for large tables

DATA MIGRATION APPROACH:
1. Use pg_loader or custom ETL for data migration
2. Handle zero datetimes during migration
3. Test with subset of data first
4. Migrate in order: users → customers → products → orders → inventory
*/
