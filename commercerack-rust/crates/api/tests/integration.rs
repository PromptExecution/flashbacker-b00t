//! Integration tests for CommerceRack API
//! Tests the full e-commerce workflow: Customer → Product → Cart → Order

use axum::{
    body::Body,
    http::{Request, StatusCode},
};
use commercerack_api::app;
use rust_decimal::Decimal;
use serde_json::{json, Value};
use sqlx::PgPool;
use tower::ServiceExt;

/// Helper to make JSON requests
async fn make_request(
    app: axum::Router,
    method: &str,
    uri: &str,
    body: Option<Value>,
) -> (StatusCode, Value) {
    let mut req = Request::builder().method(method).uri(uri);

    let body = if let Some(json_body) = body {
        req = req.header("content-type", "application/json");
        Body::from(serde_json::to_string(&json_body).unwrap())
    } else {
        Body::empty()
    };

    let response = app.oneshot(req.body(body).unwrap()).await.unwrap();

    let status = response.status();
    let body_bytes = axum::body::to_bytes(response.into_body(), usize::MAX)
        .await
        .unwrap();

    let json: Value = if body_bytes.is_empty() {
        json!(null)
    } else {
        serde_json::from_slice(&body_bytes).unwrap_or(json!(null))
    };

    (status, json)
}

#[tokio::test]
async fn test_full_ecommerce_workflow() {
    // Skip if DATABASE_URL not set
    if std::env::var("DATABASE_URL").is_err() {
        println!("Skipping integration test: DATABASE_URL not set");
        return;
    }

    let database_url = std::env::var("DATABASE_URL").unwrap();
    let pool = PgPool::connect(&database_url).await.unwrap();
    let app = app(pool.clone());

    let mid = 1; // Test merchant ID

    // Step 1: Create a customer
    println!("Creating customer...");
    let (status, customer) = make_request(
        app.clone(),
        "POST",
        "/api/customers",
        Some(json!({
            "mid": mid,
            "email": "integration_test@example.com",
            "password": "SecurePass123!"
        })),
    )
    .await;

    assert_eq!(status, StatusCode::OK, "Customer creation failed");
    let customer_id = customer["cid"].as_i64().unwrap();
    println!("Created customer with ID: {}", customer_id);

    // Step 2: Create products
    println!("Creating products...");
    let (status, product1) = make_request(
        app.clone(),
        "POST",
        "/api/products",
        Some(json!({
            "mid": mid,
            "product_code": "WIDGET-001",
            "product_name": "Test Widget"
        })),
    )
    .await;

    assert_eq!(status, StatusCode::OK, "Product 1 creation failed");
    let product1_id = product1["id"].as_i64().unwrap();
    println!("Created product 1 with ID: {}", product1_id);

    let (status, product2) = make_request(
        app.clone(),
        "POST",
        "/api/products",
        Some(json!({
            "mid": mid,
            "product_code": "GADGET-001",
            "product_name": "Test Gadget"
        })),
    )
    .await;

    assert_eq!(status, StatusCode::OK, "Product 2 creation failed");
    let product2_id = product2["id"].as_i64().unwrap();
    println!("Created product 2 with ID: {}", product2_id);

    // Step 3: Create a cart
    println!("Creating cart...");
    let (status, cart) = make_request(
        app.clone(),
        "POST",
        "/api/carts",
        None,
    )
    .await;

    assert_eq!(status, StatusCode::OK, "Cart creation failed");
    let cart_id = cart["cart_id"].as_str().unwrap();
    assert_eq!(cart["items"].as_array().unwrap().len(), 0);
    assert_eq!(cart["item_count"].as_i64().unwrap(), 0);
    println!("Created cart with ID: {}", cart_id);

    // Step 4: Add items to cart
    println!("Adding items to cart...");
    let (status, cart) = make_request(
        app.clone(),
        "POST",
        &format!("/api/carts/{}/items", cart_id),
        Some(json!({
            "sku": "WIDGET-001",
            "product_name": "Test Widget",
            "quantity": 2,
            "unit_price": "19.99"
        })),
    )
    .await;

    assert_eq!(status, StatusCode::OK, "Adding item 1 failed");
    assert_eq!(cart["items"].as_array().unwrap().len(), 1);
    assert_eq!(cart["item_count"].as_i64().unwrap(), 2);
    println!("Added Widget to cart (qty: 2)");

    let (status, cart) = make_request(
        app.clone(),
        "POST",
        &format!("/api/carts/{}/items", cart_id),
        Some(json!({
            "sku": "GADGET-001",
            "product_name": "Test Gadget",
            "quantity": 1,
            "unit_price": "29.99"
        })),
    )
    .await;

    assert_eq!(status, StatusCode::OK, "Adding item 2 failed");
    assert_eq!(cart["items"].as_array().unwrap().len(), 2);
    assert_eq!(cart["item_count"].as_i64().unwrap(), 3);

    // Verify subtotal: (2 * 19.99) + (1 * 29.99) = 69.97
    let subtotal = cart["subtotal"].as_str().unwrap();
    let expected = Decimal::new(6997, 2);
    assert_eq!(subtotal.parse::<Decimal>().unwrap(), expected);
    println!("Cart subtotal: ${}", subtotal);

    // Step 5: Update cart item quantity
    println!("Updating cart item quantity...");
    let (status, cart) = make_request(
        app.clone(),
        "PUT",
        &format!("/api/carts/{}/items/WIDGET-001", cart_id),
        Some(json!({
            "quantity": 5
        })),
    )
    .await;

    assert_eq!(status, StatusCode::OK, "Updating quantity failed");
    assert_eq!(cart["item_count"].as_i64().unwrap(), 6); // 5 + 1

    // New subtotal: (5 * 19.99) + (1 * 29.99) = 129.94
    let subtotal = cart["subtotal"].as_str().unwrap();
    let expected = Decimal::new(12994, 2);
    assert_eq!(subtotal.parse::<Decimal>().unwrap(), expected);
    println!("Updated cart subtotal: ${}", subtotal);

    // Step 6: Remove an item
    println!("Removing item from cart...");
    let (status, cart) = make_request(
        app.clone(),
        "DELETE",
        &format!("/api/carts/{}/items/GADGET-001", cart_id),
        None,
    )
    .await;

    assert_eq!(status, StatusCode::OK, "Removing item failed");
    assert_eq!(cart["items"].as_array().unwrap().len(), 1);
    assert_eq!(cart["item_count"].as_i64().unwrap(), 5);

    // Subtotal now: 5 * 19.99 = 99.95
    let subtotal = cart["subtotal"].as_str().unwrap();
    let expected = Decimal::new(9995, 2);
    assert_eq!(subtotal.parse::<Decimal>().unwrap(), expected);
    println!("Cart after removal subtotal: ${}", subtotal);

    // Step 7: Create an order
    println!("Creating order...");
    let order_total = subtotal.parse::<Decimal>().unwrap();
    let (status, order) = make_request(
        app.clone(),
        "POST",
        "/api/orders",
        Some(json!({
            "mid": mid,
            "orderid": "TEST-ORDER-001",
            "customer": customer_id,
            "order_total": order_total.to_string()
        })),
    )
    .await;

    assert_eq!(status, StatusCode::OK, "Order creation failed");
    let order_id = order["id"].as_i64().unwrap();
    assert_eq!(order["orderid"].as_str().unwrap(), "TEST-ORDER-001");
    println!("Created order with ID: {}", order_id);

    // Step 8: Verify order can be retrieved
    println!("Retrieving order...");
    let (status, retrieved_order) = make_request(
        app.clone(),
        "GET",
        &format!("/api/orders/{}/{}", mid, order_id),
        None,
    )
    .await;

    assert_eq!(status, StatusCode::OK, "Order retrieval failed");
    assert_eq!(retrieved_order["id"].as_i64().unwrap(), order_id);
    assert_eq!(retrieved_order["customer"].as_i64().unwrap(), customer_id);
    println!("Order retrieved successfully");

    // Step 9: Clear cart
    println!("Clearing cart...");
    let (status, cart) = make_request(
        app.clone(),
        "POST",
        &format!("/api/carts/{}/clear", cart_id),
        None,
    )
    .await;

    assert_eq!(status, StatusCode::OK, "Clearing cart failed");
    assert_eq!(cart["items"].as_array().unwrap().len(), 0);
    assert_eq!(cart["item_count"].as_i64().unwrap(), 0);
    println!("Cart cleared successfully");

    // Step 10: Delete cart
    println!("Deleting cart...");
    let (status, _) = make_request(
        app.clone(),
        "DELETE",
        &format!("/api/carts/{}", cart_id),
        None,
    )
    .await;

    assert_eq!(status, StatusCode::NO_CONTENT, "Cart deletion failed");
    println!("Cart deleted successfully");

    println!("\n✓ Full e-commerce workflow test completed successfully!");
}

#[tokio::test]
async fn test_cart_item_merging() {
    // Test that adding the same SKU twice merges quantities
    if std::env::var("DATABASE_URL").is_err() {
        return;
    }

    let database_url = std::env::var("DATABASE_URL").unwrap();
    let pool = PgPool::connect(&database_url).await.unwrap();
    let app = app(pool);

    // Create cart
    let (status, cart) = make_request(app.clone(), "POST", "/api/carts", None).await;
    assert_eq!(status, StatusCode::OK);
    let cart_id = cart["cart_id"].as_str().unwrap();

    // Add item first time
    let (status, cart) = make_request(
        app.clone(),
        "POST",
        &format!("/api/carts/{}/items", cart_id),
        Some(json!({
            "sku": "MERGE-TEST",
            "product_name": "Merge Test",
            "quantity": 3,
            "unit_price": "10.00"
        })),
    )
    .await;

    assert_eq!(status, StatusCode::OK);
    assert_eq!(cart["item_count"].as_i64().unwrap(), 3);

    // Add same item again
    let (status, cart) = make_request(
        app.clone(),
        "POST",
        &format!("/api/carts/{}/items", cart_id),
        Some(json!({
            "sku": "MERGE-TEST",
            "product_name": "Merge Test",
            "quantity": 2,
            "unit_price": "10.00"
        })),
    )
    .await;

    assert_eq!(status, StatusCode::OK);
    assert_eq!(cart["items"].as_array().unwrap().len(), 1); // Still 1 unique item
    assert_eq!(cart["item_count"].as_i64().unwrap(), 5); // 3 + 2 = 5

    println!("✓ Cart item merging test passed");
}
