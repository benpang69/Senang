# Senang Database Design

## 1. Overview

Senang is a local-first Point of Sale (POS) application designed for small businesses that may operate one or more booths.

The database stores business information locally on the user's device using SQLite through Drift.

The database is designed to support:

* Multiple booths under one account
* Products and categories
* Custom product fields
* Inventory management
* Sales and sale items
* Stock movement history
* Business expenses
* End-of-day closing reports

Money values are stored as integers in the smallest currency unit (sen).

Example:

```text
RM 3.50 = 350
RM 10.00 = 1000
```

This avoids floating-point rounding problems when handling money.

---

# 2. Database Architecture

Senang uses the following database architecture:

```text
Flutter Application
        ↓
Application Services
        ↓
Repositories
        ↓
Drift
        ↓
SQLite
```

Drift is used as the database access layer, while SQLite provides the local database.

---

# 3. Database Tables

The first version of the database contains the following tables:

```text
accounts
users
booths
categories
products
custom_fields
product_custom_values
sales
sale_items
stock_movements
expenses
daily_closings
```

---

# 4. Entity Relationships

The main relationships between the tables are:

```text
                    ACCOUNTS
                       │
              ┌────────┴────────┐
              ↓                 ↓
            USERS             BOOTHS
                                │
             ┌──────────────────┼──────────────────┐
             ↓                  ↓                  ↓
        CATEGORIES          PRODUCTS            SALES
                                │                  │
                                ↓                  ↓
                         CUSTOM FIELDS        SALE ITEMS
                               
        PRODUCTS
           │
           ↓
    STOCK MOVEMENTS

                    BOOTHS
                       │
             ┌─────────┴─────────┐
             ↓                   ↓
         EXPENSES          DAILY CLOSINGS
```

---

# 5. Table Definitions

## 5.1 Accounts

The `accounts` table represents a business account.

An account can have multiple users and multiple booths.

### Columns

| Column     | Type     | Constraints | Description           |
| ---------- | -------- | ----------- | --------------------- |
| id         | INTEGER  | PRIMARY KEY | Unique account ID     |
| name       | TEXT     | NOT NULL    | Business/account name |
| created_at | DATETIME | NOT NULL    | Account creation time |
| updated_at | DATETIME | NOT NULL    | Last update time      |

### Relationships

```text
accounts
    ├── users
    └── booths
```

---

## 5.2 Users

The `users` table stores people who can access an account.

Users may have different roles such as owner or staff.

### Columns

| Column     | Type     | Constraints | Description                      |
| ---------- | -------- | ----------- | -------------------------------- |
| id         | INTEGER  | PRIMARY KEY | Unique user ID                   |
| account_id | INTEGER  | FOREIGN KEY | Account the user belongs to      |
| name       | TEXT     | NOT NULL    | User name                        |
| email      | TEXT     | NULL        | User email                       |
| role       | TEXT     | NOT NULL    | User role such as owner or staff |
| is_active  | BOOLEAN  | NOT NULL    | Whether the user is active       |
| created_at | DATETIME | NOT NULL    | Creation time                    |
| updated_at | DATETIME | NOT NULL    | Last update time                 |

### Foreign Key

```text
users.account_id → accounts.id
```

---

## 5.3 Booths

The `booths` table stores the different business locations or booths belonging to an account.

Each booth can have its own products, sales, inventory and expenses.

### Columns

| Column      | Type     | Constraints | Description                 |
| ----------- | -------- | ----------- | --------------------------- |
| id          | INTEGER  | PRIMARY KEY | Unique booth ID             |
| account_id  | INTEGER  | FOREIGN KEY | Account that owns the booth |
| name        | TEXT     | NOT NULL    | Booth name                  |
| description | TEXT     | NULL        | Optional booth description  |
| is_active   | BOOLEAN  | NOT NULL    | Whether the booth is active |
| created_at  | DATETIME | NOT NULL    | Creation time               |
| updated_at  | DATETIME | NOT NULL    | Last update time            |

### Foreign Key

```text
booths.account_id → accounts.id
```

---

# 6. Categories

The `categories` table stores product categories.

Examples:

```text
Food
Drinks
Clothing
Accessories
Electronics
```

Categories belong to a specific booth.

### Columns

| Column      | Type     | Constraints | Description                   |
| ----------- | -------- | ----------- | ----------------------------- |
| id          | INTEGER  | PRIMARY KEY | Unique category ID            |
| booth_id    | INTEGER  | FOREIGN KEY | Booth the category belongs to |
| name        | TEXT     | NOT NULL    | Category name                 |
| description | TEXT     | NULL        | Optional description          |
| created_at  | DATETIME | NOT NULL    | Creation time                 |
| updated_at  | DATETIME | NOT NULL    | Last update time              |

### Foreign Key

```text
categories.booth_id → booths.id
```

---

# 7. Products

The `products` table stores products sold by a booth.

Products contain the standard information required by the POS system.

### Columns

| Column              | Type     | Constraints | Description                  |
| ------------------- | -------- | ----------- | ---------------------------- |
| id                  | INTEGER  | PRIMARY KEY | Unique product ID            |
| booth_id            | INTEGER  | FOREIGN KEY | Booth the product belongs to |
| category_id         | INTEGER  | FOREIGN KEY | Product category             |
| name                | TEXT     | NOT NULL    | Product name                 |
| sku                 | TEXT     | NULL        | Optional stock keeping unit  |
| description         | TEXT     | NULL        | Product description          |
| price               | INTEGER  | NOT NULL    | Selling price in sen         |
| cost_price          | INTEGER  | NULL        | Product cost in sen          |
| stock_quantity      | INTEGER  | NOT NULL    | Current stock quantity       |
| low_stock_threshold | INTEGER  | NOT NULL    | Minimum stock warning level  |
| is_active           | BOOLEAN  | NOT NULL    | Whether product is active    |
| created_at          | DATETIME | NOT NULL    | Creation time                |
| updated_at          | DATETIME | NOT NULL    | Last update time             |

### Foreign Keys

```text
products.booth_id → booths.id
products.category_id → categories.id
```

### Example

```text
Product: Chicken Burger
Price: RM 8.50
Database price: 850
Stock: 20
```

---

# 8. Custom Fields

Different businesses may require different product information.

For example:

```text
Clothing:
- Size
- Colour
- Material

Electronics:
- Brand
- Model
- Warranty

Food:
- Spicy Level
- Portion Size
```

The `custom_fields` table allows businesses to create their own product fields.

### Columns

| Column      | Type     | Constraints | Description                |
| ----------- | -------- | ----------- | -------------------------- |
| id          | INTEGER  | PRIMARY KEY | Unique custom field ID     |
| booth_id    | INTEGER  | FOREIGN KEY | Booth the field belongs to |
| name        | TEXT     | NOT NULL    | Field name                 |
| field_type  | TEXT     | NOT NULL    | Type of field              |
| is_required | BOOLEAN  | NOT NULL    | Whether field is required  |
| sort_order  | INTEGER  | NOT NULL    | Display order              |
| created_at  | DATETIME | NOT NULL    | Creation time              |
| updated_at  | DATETIME | NOT NULL    | Last update time           |

### Supported Field Types

```text
text
number
boolean
date
select
```

### Foreign Key

```text
custom_fields.booth_id → booths.id
```

---

# 9. Product Custom Values

The `product_custom_values` table stores the value of each custom field for a product.

### Columns

| Column          | Type    | Constraints | Description        |
| --------------- | ------- | ----------- | ------------------ |
| id              | INTEGER | PRIMARY KEY | Unique value ID    |
| product_id      | INTEGER | FOREIGN KEY | Product            |
| custom_field_id | INTEGER | FOREIGN KEY | Custom field       |
| value           | TEXT    | NOT NULL    | Stored field value |

### Foreign Keys

```text
product_custom_values.product_id → products.id
product_custom_values.custom_field_id → custom_fields.id
```

A product can have multiple custom field values.

Example:

```text
Product: Nike Shirt

Size → XL
Colour → Black
Material → Cotton
```

---

# 10. Sales

The `sales` table stores each completed POS transaction.

A sale belongs to a booth and may be associated with the user who processed it.

### Columns

| Column         | Type     | Constraints | Description               |
| -------------- | -------- | ----------- | ------------------------- |
| id             | INTEGER  | PRIMARY KEY | Unique sale ID            |
| booth_id       | INTEGER  | FOREIGN KEY | Booth where sale occurred |
| user_id        | INTEGER  | FOREIGN KEY | User who processed sale   |
| subtotal       | INTEGER  | NOT NULL    | Subtotal in sen           |
| discount       | INTEGER  | NOT NULL    | Discount in sen           |
| total          | INTEGER  | NOT NULL    | Final total in sen        |
| payment_method | TEXT     | NOT NULL    | Payment method            |
| status         | TEXT     | NOT NULL    | Sale status               |
| notes          | TEXT     | NULL        | Optional notes            |
| created_at     | DATETIME | NOT NULL    | Sale time                 |

### Example Payment Methods

```text
cash
card
qr
bank_transfer
other
```

### Example Statuses

```text
completed
cancelled
refunded
```

### Foreign Keys

```text
sales.booth_id → booths.id
sales.user_id → users.id
```

---

# 11. Sale Items

The `sale_items` table stores the individual products included in a sale.

One sale can contain multiple sale items.

### Columns

| Column       | Type    | Constraints | Description                  |
| ------------ | ------- | ----------- | ---------------------------- |
| id           | INTEGER | PRIMARY KEY | Unique sale item ID          |
| sale_id      | INTEGER | FOREIGN KEY | Sale containing the item     |
| product_id   | INTEGER | FOREIGN KEY | Original product             |
| product_name | TEXT    | NOT NULL    | Product name at time of sale |
| quantity     | INTEGER | NOT NULL    | Quantity sold                |
| unit_price   | INTEGER | NOT NULL    | Price per item in sen        |
| cost_price   | INTEGER | NULL        | Cost per item in sen         |
| subtotal     | INTEGER | NOT NULL    | Item subtotal in sen         |

### Foreign Keys

```text
sale_items.sale_id → sales.id
sale_items.product_id → products.id
```

`product_name`, `unit_price` and `cost_price` are stored as snapshots.

This means old sales remain correct even if the product name or price changes later.

Example:

```text
Product price today:
RM 10.00

Old sale:
RM 8.00

The old sale should still show RM 8.00.
```

---

# 12. Stock Movements

The `stock_movements` table records changes to product inventory.

Examples:

```text
Restock
Sale
Return
Manual adjustment
Damaged stock
```

### Columns

| Column         | Type     | Constraints | Description            |
| -------------- | -------- | ----------- | ---------------------- |
| id             | INTEGER  | PRIMARY KEY | Unique movement ID     |
| booth_id       | INTEGER  | FOREIGN KEY | Booth                  |
| product_id     | INTEGER  | FOREIGN KEY | Product                |
| movement_type  | TEXT     | NOT NULL    | Type of stock movement |
| quantity       | INTEGER  | NOT NULL    | Quantity change        |
| reference_type | TEXT     | NULL        | Related record type    |
| reference_id   | INTEGER  | NULL        | Related record ID      |
| note           | TEXT     | NULL        | Optional note          |
| created_at     | DATETIME | NOT NULL    | Movement time          |

Positive quantities increase stock.

Negative quantities decrease stock.

Example:

```text
Restock:
+20

Sale:
-2

Damaged:
-1
```

### Foreign Keys

```text
stock_movements.booth_id → booths.id
stock_movements.product_id → products.id
```

---

# 13. Expenses

The `expenses` table records business expenses.

Examples:

```text
Rent
Transport
Supplies
Packaging
Utilities
Other
```

### Columns

| Column      | Type     | Constraints | Description               |
| ----------- | -------- | ----------- | ------------------------- |
| id          | INTEGER  | PRIMARY KEY | Unique expense ID         |
| booth_id    | INTEGER  | FOREIGN KEY | Booth                     |
| user_id     | INTEGER  | FOREIGN KEY | User who recorded expense |
| category    | TEXT     | NOT NULL    | Expense category          |
| description | TEXT     | NOT NULL    | Expense description       |
| amount      | INTEGER  | NOT NULL    | Expense amount in sen     |
| created_at  | DATETIME | NOT NULL    | Expense time              |

### Foreign Keys

```text
expenses.booth_id → booths.id
expenses.user_id → users.id
```

---

# 14. Daily Closings

The `daily_closings` table stores the end-of-day closing information for each booth.

This allows the business owner to review daily performance.

### Columns

| Column            | Type     | Constraints | Description                |
| ----------------- | -------- | ----------- | -------------------------- |
| id                | INTEGER  | PRIMARY KEY | Unique closing ID          |
| booth_id          | INTEGER  | FOREIGN KEY | Booth                      |
| closed_by_user_id | INTEGER  | FOREIGN KEY | User performing closing    |
| closing_date      | DATE     | NOT NULL    | Business date              |
| opening_cash      | INTEGER  | NOT NULL    | Starting cash in sen       |
| cash_sales        | INTEGER  | NOT NULL    | Cash sales in sen          |
| cash_expenses     | INTEGER  | NOT NULL    | Cash expenses in sen       |
| total_sales       | INTEGER  | NOT NULL    | Total sales in sen         |
| total_expenses    | INTEGER  | NOT NULL    | Total expenses in sen      |
| expected_cash     | INTEGER  | NOT NULL    | Expected cash in sen       |
| actual_cash       | INTEGER  | NOT NULL    | Actual cash counted in sen |
| cash_difference   | INTEGER  | NOT NULL    | Difference in sen          |
| notes             | TEXT     | NULL        | Optional closing notes     |
| closed_at         | DATETIME | NOT NULL    | Closing timestamp          |

### Foreign Keys

```text
daily_closings.booth_id → booths.id
daily_closings.closed_by_user_id → users.id
```

A booth should normally have only one daily closing for a specific date.

```text
Unique:
(booth_id, closing_date)
```

---

# 15. Important Database Rules

## 15.1 Money

All monetary values are stored as integers in sen.

```text
RM 1.00 → 100
RM 5.50 → 550
RM 99.99 → 9999
```

Never store money using floating-point values.

---

## 15.2 Foreign Keys

Foreign key constraints should be enabled in SQLite.

This prevents invalid relationships such as:

```text
Sale → non-existent booth
Product → non-existent category
Sale item → non-existent sale
```

---

## 15.3 Stock Updates

Stock changes should happen inside a database transaction.

For example, when a customer buys 2 burgers:

```text
1. Create sale
2. Create sale item
3. Reduce product stock by 2
4. Create stock movement of -2
5. Commit transaction
```

If one operation fails, the transaction should roll back.

This prevents situations where the sale is recorded but the stock is not updated.

---

## 15.4 Sale History

Sale items store snapshots of product information.

The following values should not depend on the current product record:

```text
product_name
unit_price
cost_price
```

This ensures historical sales remain accurate.

---

# 16. Initial Database Scope

The first version of the Senang database focuses on local POS functionality.

Included:

```text
✓ Accounts
✓ Users
✓ Multiple booths
✓ Categories
✓ Products
✓ Custom product fields
✓ Inventory
✓ Sales
✓ Sale items
✓ Stock movements
✓ Expenses
✓ Daily closing
```

Not included yet:

```text
✗ Cloud database
✗ Online synchronization
✗ Google login
✗ Apple login
✗ Facebook login
✗ Remote API
✗ Multi-device synchronization
```

These features can be added later without changing the core purpose of the local POS database.

---

# 17. Planned Database Technology

Senang will use:

```text
Database: SQLite
Database Layer: Drift
Application: Flutter
Platform: iOS + Android
```

The SQLite database will be stored locally on the user's device.

---

# 18. Planned Implementation

After this database design is finalized, the database will be implemented using Drift.

Planned structure:

```text
lib/
└── database/
    ├── database.dart
    ├── tables/
    │   ├── accounts.dart
    │   ├── users.dart
    │   ├── booths.dart
    │   ├── categories.dart
    │   ├── products.dart
    │   ├── custom_fields.dart
    │   ├── sales.dart
    │   ├── sale_items.dart
    │   ├── stock_movements.dart
    │   ├── expenses.dart
    │   └── daily_closings.dart
    │
    └── daos/
```

The Drift generated files will be committed to the repository.

---

# 19. Database Design Status

```text
Database design: Planned
Database technology: SQLite
Database access layer: Drift
Cloud synchronization: Future feature
Implementation: Not started
```
