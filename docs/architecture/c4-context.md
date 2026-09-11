# Senang - C4 Context Diagram

```mermaid
C4Context

title Senang - System Context

Person(user, "POS User", "Business owner or staff member")

System(senang, "Senang", "Local-first POS application for managing booths, inventory, sales, expenses and daily closing")

System_Ext(share, "Email / Share Service", "Mobile email and sharing applications")

Rel(user, senang, "Uses")
Rel(senang, share, "Shares reports through")