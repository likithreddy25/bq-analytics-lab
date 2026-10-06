# bq-analytics-lab

A dbt + BigQuery analytics-engineering project: staging -> intermediate -> marts over Google's public
`bigquery-public-data.thelook_ecommerce` dataset.

> **Data disclosure:** the source data is a *synthetic* public e-commerce dataset published by Google.
> Nothing here is real business data.

**Live dashboard (synthetic data):** [https://datastudio.google.com/reporting/187db68f-c14f-4415-a87c-e16c36b2b6fe](https://datastudio.google.com/reporting/187db68f-c14f-4415-a87c-e16c36b2b6fe)

## Layout

| Layer | Models | Materialization |
|---|---|---|
| staging | `stg_users`, `stg_orders`, `stg_order_items`, `stg_products`, `stg_events` | view |
| intermediate | `int_sessions` | view |
| marts | `fct_order_items`, `dim_customers`, `fct_monthly_revenue`, `fct_cohort_retention` | table |

Metric definitions: [docs/metrics.md](docs/metrics.md).

Testing: generic tests (unique, not_null, relationships, accepted_values, custom `non_negative`) plus
singular tests that reconcile monthly revenue and customer revenue against the fact table and validate
cohort retention (including composite-grain uniqueness).

`as_of_date` var makes `days_since_last_order` / `health_segment` reproducible
(`dbt build --vars '{as_of_date: "2025-01-01"}'`).

## Offline checks (no GCP needed)

```bash
pip install "dbt-bigquery~=1.9.0" sqlglot pytest
pytest tests_py -q          # renders every model's Jinja and parses it as BigQuery SQL
dbt parse --profiles-dir .  # needs a profile file; see .github/workflows/dbt-parse.yml
```

## Run against BigQuery

```bash
gcloud auth application-default login
gcloud config set project <your-project-id>
python -m venv .venv && source .venv/bin/activate
pip install "dbt-bigquery~=1.9.0"
mkdir -p ~/.dbt && cp profiles.yml.example ~/.dbt/profiles.yml   # edit project id if needed
dbt build
```

Credentials stay on your machine (application-default credentials); nothing is stored in this repo.

## Results

Real `dbt build` against BigQuery (project `bq-analytics-lab`, US, oauth/ADC), run locally on 2026-10-06
with dbt-core 1.12.5 + dbt-bigquery 1.9.2:

- **PASS=40, WARN=0, ERROR=0, SKIP=0, NO-OP=1** (the exposure), 41 nodes, 22.4 s wall time
- 10 models (6 views, 4 tables), 30 data tests (generic + singular), 1 exposure
- `fct_order_items` 180.8k rows (11.3 MiB processed), `dim_customers` 100.0k rows (127.4 MiB),
  `fct_monthly_revenue` 94 rows, `fct_cohort_retention` 3.8k rows
- Known warning: `MissingArgumentsPropertyInGenericTestDeprecation` (test args not yet nested under `arguments`)
