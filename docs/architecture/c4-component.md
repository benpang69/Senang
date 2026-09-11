
### `c4-component.md`

```markdown
# Senang - C4 Component Diagram

```mermaid
C4Component

title Senang - Application Services Components

Container_Boundary(app, "Application Services") {

    Component(booth, "Booth Service", "Dart",
        "Manages booths and booth-specific data")

    Component(product, "Product Service", "Dart",
        "Manages products, categories and customizable product fields")

    Component(inventory, "Inventory Service", "Dart",
        "Manages stock quantities and stock movements")

    Component(pos, "POS Service", "Dart",
        "Handles cart operations, checkout and payments")

    Component(sales, "Sales Service", "Dart",
        "Manages completed sales and sales history")

    Component(expense, "Expense Service", "Dart",
        "Manages business expenses")

    Component(closing, "Daily Closing Service", "Dart",
        "Calculates and records end-of-day totals")

    Component(report, "Report Service", "Dart",
        "Generates PDF and Excel reports")
}

Container(ui, "Flutter UI", "Flutter / Dart",
    "Mobile user interface")

Container(repo, "Repositories", "Dart",
    "Database repository layer")

ContainerDb(db, "SQLite Database", "SQLite",
    "Local application database")

System_Ext(share, "Email / Share Service", "Mobile sharing applications")

Rel(ui, booth, "Uses")
Rel(ui, product, "Uses")
Rel(ui, inventory, "Uses")
Rel(ui, pos, "Uses")
Rel(ui, sales, "Uses")
Rel(ui, expense, "Uses")
Rel(ui, closing, "Uses")
Rel(ui, report, "Uses")

Rel(pos, product, "Gets product information")
Rel(pos, inventory, "Updates stock")
Rel(pos, sales, "Creates sale records")

Rel(closing, sales, "Gets daily sales")
Rel(closing, expense, "Gets daily expenses")

Rel(report, sales, "Gets sales data")
Rel(report, expense, "Gets expense data")
Rel(report, closing, "Gets closing data")

Rel(booth, repo, "Uses")
Rel(product, repo, "Uses")
Rel(inventory, repo, "Uses")
Rel(pos, repo, "Uses")
Rel(sales, repo, "Uses")
Rel(expense, repo, "Uses")
Rel(closing, repo, "Uses")
Rel(report, repo, "Uses")

Rel(repo, db, "Reads and writes")

Rel(report, share, "Shares generated reports")