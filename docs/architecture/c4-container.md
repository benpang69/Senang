
### `c4-container.md`

```markdown
# Senang - C4 Container Diagram

```mermaid
C4Container

title Senang - Container Diagram

Person(user, "POS User", "Business owner or staff member")

System_Boundary(senang, "Senang Mobile Application") {

    Container(ui, "Flutter UI", "Flutter / Dart",
        "Mobile interface for POS, inventory, booths, sales, expenses and reports")

    Container(app, "Application Services", "Dart",
        "Contains business logic for checkout, inventory, expenses, closing and reporting")

    Container(repo, "Repositories", "Dart",
        "Provides an abstraction between business logic and database access")

    Container(drift, "Drift Database Layer", "Drift / Dart",
        "Provides type-safe database access and queries")

    ContainerDb(sqlite, "SQLite Database", "SQLite",
        "Stores accounts, booths, products, sales, expenses and other business data")

    Container(report, "Report Service", "Dart",
        "Generates PDF and Excel reports")
}

System_Ext(share, "Email / Share Service", "Mobile email and sharing applications")

Rel(user, ui, "Uses")

Rel(ui, app, "Calls")

Rel(app, repo, "Uses")

Rel(repo, drift, "Queries")

Rel(drift, sqlite, "Reads and writes")

Rel(app, report, "Requests reports")

Rel(report, share, "Shares reports through")