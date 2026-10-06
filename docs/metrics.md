# Metric definitions

- **net_revenue** (`fct_order_items`): `sale_price`, forced to 0 when item status is Cancelled or Returned.
- **gross_margin**: `net_revenue - product cost`.
- **order_month**: month of order creation.
- **AOV** (`fct_monthly_revenue`): net revenue / distinct orders in the month.
- **return_rate**: returned items / items sold (monthly, and lifetime in `dim_customers`).
- **new vs returning customers**: new = customer's first order month equals the month.
- **health_segment** (`dim_customers`), by `days_since_last_order` relative to `as_of_date`:
  `never_purchased` (no orders); `active` (<= `health_active_days`, default 90);
  `cooling` (<= `health_cooling_days`, 180); `at_risk` (<= `health_at_risk_days`, 365); else `churned`.
- **cohort retention** (`fct_cohort_retention`): share of a first-order-month cohort that orders again
  `months_since_first` months later. Grain: cohort_month x months_since_first.
