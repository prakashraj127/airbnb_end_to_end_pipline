
#  Airbnb End-to-End Project

## 📋 **Project Overview**

This project is an end-to-end **dbt + Snowflake data transformation pipeline** for booking, host, and listing data.

The project demonstrates a layered data transformation approach:

- **Bronze** – incremental ingestion from raw Snowflake tables
- **Silver** – cleaning, business transformations, and derived columns
- **Gold** – integrated analytics-ready datasets
- **Snapshots** – historical tracking of bookings, hosts, and listings
- **Macros** – reusable SQL/Jinja transformations
- **Ephemeral models** – reusable intermediate logic that is compiled into downstream SQL

The project is designed to demonstrate practical **Analytics Engineering / Data Engineering** skills using dbt and Snowflake.

---

## 🏗️ **Architecture**

```text
                         ┌──────────────────────┐
                         │   Raw Source Data    │
                         │   Snowflake STAGING  │
                         └──────────┬───────────┘
                                    │
                                    ▼
                         ┌──────────────────────┐
                         │       dbt Source     │
                         │ raw.hosts            │
                         │ raw.bookings         │
                         │ raw.listings         │
                         └──────────┬───────────┘
                                    │
                                    ▼
                    ┌──────────────────────────────┐
                    │          BRONZE              │
                    │ Incremental models           │
                    │ bronze_hosts                 │
                    │ bronze_bookings              │
                    │ bronze_listings              │
                    └──────────────┬───────────────┘
                                   │
                                   ▼
                    ┌──────────────────────────────┐
                    │           SILVER             │
                    │ Incremental + transformations │
                    │ silver_hosts                  │
                    │ silver_bookings              │
                    │ silver_listings              │
                    └──────────────┬───────────────┘
                                   │
                                   ▼
                    ┌──────────────────────────────┐
                    │            GOLD              │
                    │ OBT + Fact + Dimensions      │
                    │                              │
                    │ OBT                          │
                    │ Fact                         │
                    │ Dim Hosts                    │
                    │ Dim Listings                 │
                    │ Dim Bookings                 │
                    └──────────────┬───────────────┘
                                   │
                                   ▼
                         ┌──────────────────────┐
                         │ Analytics / BI Layer │
                         └──────────────────────┘
```

---

## 🛠️ **Technology Stack**

| Technology | Purpose |
|---|---|
| **Snowflake** | Cloud data warehouse |
| **dbt** | Data transformation and modeling |
| **SQL** | Data transformation logic |
| **Jinja** | Dynamic SQL and reusable dbt logic |
| **Git** | Version control |

---

## 📁 **Project Structure**

```text
ecommerce_dbt/
│
├── analyses/
│   └── work1.sql
│
├── macros/
│   ├── generate_schema_name.sql
│   ├── mutiply.sql
│   ├── tag.sql
│   └── trimmer.sql
│
├── models/
│   ├── source/
│   │   └── source.yml
│   │
│   ├── bronze/
│   │   ├── bronze_bookings.sql
│   │   ├── bronze_hosts.sql
│   │   └── bronze_listings.sql
│   │
│   ├── silver/
│   │   ├── silver_bookings.sql
│   │   ├── silver_hosts.sql
│   │   └── silver_listings.sql
│   │
│   └── gold/
│       ├── ephemeral/
│       │   ├── bookings.sql
│       │   ├── hosts.sql
│       │   └── listings.sql
│       ├── fact.sql
│       └── obt.sql
│
├── snapshots/
│   ├── dim_bookings.yml
│   ├── dim_hosts.yml
│   └── dim_listings.yml
│
├── seeds/
├── tests/
├── dbt_project.yml
├── .gitignore
└── README.md
```

> `target/`, `dbt_packages/`, and `logs/` are generated/runtime directories and are excluded through `.gitignore`.

---

# 🔄 Data Pipeline

## 1. Source Layer

The dbt source configuration defines three raw Snowflake tables:

```text
SNOW.STAGING.HOSTS
SNOW.STAGING.BOOKINGS
SNOW.STAGING.LISTINGS
```

Configured in:

```text
models/source/source.yml
```

The source is referenced in dbt using:

```sql
{{ source("raw", "bookings") }}
{{ source("raw", "hosts") }}
{{ source("raw", "listings") }}
```

---

## 2. Bronze Layer

The Bronze layer reads data from the raw source tables.

Models:

```text
bronze_bookings
bronze_hosts
bronze_listings
```

These models use **incremental materialization**.

Example logic:

```sql
{{ config(materialized="incremental") }}
```

For incremental runs, records are filtered using `created_at`:

```sql
where created_at > (
    select coalesce(max(created_at), '1900-01-01')
    from {{ this }}
)
```

This avoids processing all historical records on every run.

---

## 3. Silver Layer

The Silver layer applies business transformations and data cleaning.

### `silver_bookings`

Transforms booking data and calculates:

```text
total_amount = nights_booked × booking_amount
```

using the reusable `multiply` macro.

### `silver_hosts`

Transforms host data and creates a response-rate quality classification:

```text
VERY GOOD
GOOD
FAIR
POOR
```

It also standardizes the host name by replacing spaces with underscores.

### `silver_listings`

Transforms listing data and creates a price category using the `tag` macro:

```text
low
medium
high
```

---

# 🥇 Gold Layer

The Gold layer contains analytics-ready models.

## OBT

`obt.sql` creates an **One Big Table (OBT)** by joining:

```text
Silver Bookings
       │
       ├── Silver Listings
       │
       └── Silver Hosts
```

It combines booking, listing, and host information into a single analytical dataset.

---

## Fact Model

`fact.sql` builds a fact-oriented dataset using the Gold OBT and dimension tables.

It includes measures and keys such as:

- Booking ID
- Listing ID
- Host ID
- Total Amount
- Service Fee
- Cleaning Fee
- Accommodates
- Bedrooms
- Bathrooms
- Price Per Night
- Response Rate

---

## Ephemeral Models

The Gold layer also contains:

```text
gold/ephemeral/bookings.sql
gold/ephemeral/hosts.sql
gold/ephemeral/listings.sql
```

These models use:

```sql
materialized="ephemeral"
```

Ephemeral models do not create permanent Snowflake tables. Their SQL is incorporated into downstream models during compilation.

---

# 📸 Snapshots

The project uses dbt snapshots to track historical changes.

Snapshots:

```text
dim_bookings
dim_hosts
dim_listings
```

The snapshots use:

```text
Strategy: timestamp
Unique keys:
    BOOKING_ID
    HOST_ID
    LISTING_ID
```

The `created_at` / timestamp fields are used to determine when records change.

This allows historical versions of records to be maintained rather than only storing the latest state.

---

# 🧩 Reusable dbt Macros

The project contains reusable macros.

### `multiply`

Calculates a rounded multiplication:

```sql
{{ multiply("NIGHTS_BOOKED", "BOOKING_AMOUNT", 2) }}
```

### `tag`

Creates a price classification:

```sql
{{ tag("CAST(PRICE_PER_NIGHT AS INT)") }}
```

### `generate_schema_name`

Customizes how dbt generates schemas.

### `trimmer`

Contains reusable trimming logic intended for SQL/Jinja transformations.

---

# 🧪 Testing

The project contains a custom data test:

```text
tests/source_test.sql
```

The test is configured with:

```text
severity = warn
```

The test checks booking amounts against a threshold.

### Recommended dbt commands

Run tests:

```bash
dbt test
```

Build models and run tests:

```bash
dbt build
```

---

# 🚀 How to Run the Project

## 1. Install dbt

Install the Snowflake adapter:

```bash
pip install dbt-snowflake
```

Verify:

```bash
dbt --version
```

---

## 2. Configure Snowflake

Configure the dbt profile in:

```text
~/.dbt/profiles.yml
```

The project expects the profile:

```yaml
profile: ecommerce_dbt
```

**Do not commit Snowflake passwords, private keys, access tokens, or other credentials to GitHub.**

---

## 3. Test the Connection

```bash
dbt debug
```

---

## 4. Install Dependencies

If the project contains dbt packages:

```bash
dbt deps
```

---

## 5. Run the Models

```bash
dbt run
```

---

## 6. Run Tests

```bash
dbt test
```

---

## 7. Build the Complete Project

Recommended command:

```bash
dbt build
```

`dbt build` runs the required selected resources and their tests according to the project's dependency graph.

---

## 8. Generate Documentation

```bash
dbt docs generate
```

Start the documentation website:

```bash
dbt docs serve
```

---

# 📊 Materializations

The project demonstrates multiple dbt materializations:

| Layer | Materialization |
|---|---|
| Bronze | Incremental |
| Silver | Incremental |
| Gold | Table |
| Gold Ephemeral | Ephemeral |
| Snapshots | Snapshot |

This demonstrates practical use of dbt materialization strategies based on the purpose of each layer.

---

# 🎯 Skills Demonstrated

This project demonstrates hands-on experience with:

- Snowflake
- dbt Core
- SQL
- Jinja templating
- Incremental models
- dbt sources
- dbt snapshots
- Ephemeral models
- Fact modeling
- One Big Table (OBT)
- Reusable dbt macros
- Data transformation
- Layered data architecture
- Data quality testing
- Git / GitHub
- dbt documentation

---

# 🔐 Security

Never commit:

```text
.env
Snowflake passwords
AWS access keys
Private keys
API tokens
Service account credentials
```

The project `.gitignore` excludes:

```text
target/
dbt_packages/
logs/
.env
```
🐛 Troubleshooting
Common Issues
Connection Error

Verify Snowflake credentials in profiles.yml
Check network connectivity
Ensure warehouse is running
Compilation Error

Run dbt debug to check configuration
Verify model dependencies
Check Jinja syntax
Incremental Load Issues

Run dbt run --full-refresh to rebuild from scratch
Verify source data timestamps

# 👤 Author

**Prakash**

### Project Focus

**Snowflake + dbt Data Engineering / Analytics Engineering**

This project was built to demonstrate an end-to-end transformation workflow from raw source data to analytics-ready Gold models using dbt and Snowflake.
