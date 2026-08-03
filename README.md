# Dark Pattern UX Analysis — HealthFit Fitness App

**Did a pricing page redesign quietly turn into a dark pattern?**
A product analytics case study using SQL, Python, and Power BI to investigate a conversion drop, prove it was a dark pattern (not bad luck), and quantify the business impact.

## Problem Statement

HealthFit (a fictional fitness subscription app) redesigned its pricing page on **March 15, 2024**.
This project simulates realistic product analytics data (users, sessions, subscriptions, and an A/B test) to investigate what happened next — and whether the new design crossed the line from "bad UX" into "dark pattern."

## Data

Self-generated, realistic dataset — 4 relational tables, Jan–Jun 2024:

| Table | Rows (approx.) | Description |
|---|---|---|
| `users` | 3,000 | Signup date, device, acquisition channel, city tier, age group |
| `sessions` | 15,000 | Funnel events: Home → Pricing → Plan Selection → Payment → Confirmation |
| `subscriptions` | 1,800 | Plan type, start/end date, cancellation reason, churn flag |
| `ab_test` | 2,000 | Old pricing page (Variant A) vs redesigned page (Variant B) |

## Tech Stack

- **SQL** — schema design, stored procedures for data generation, 11 business-question queries (CTEs, window functions, joins)
- **Python** (Pandas, Matplotlib, SciPy) — data cleaning, EDA, and statistical significance testing (Welch's t-test, chi-square)
- **Power BI** — 5-page interactive dashboard (Overview, Funnel, A/B Test, Churn, Revenue)

## Key Findings

1. **Conversion dropped after the redesign**, and the drop is concentrated at the Pricing Page — the single leakiest point in the journey.
2. **Post-update users spend more time on the Pricing Page but convert less** — a statistically significant signal that the new design confuses the users.
3. **"Hard to Cancel" complaints jumped from ~14% to ~48% of all cancellation reasons** post-update — the strongest single piece of evidence that this is a dark pattern, not just a weaker design.
4. **Variant B (new page) converts roughly half as well as Variant A**, confirming the funnel-level finding at the A/B test level.
5. **Total billed revenue rose despite higher churn** — a sign the company may be extracting value from friction (users billed before completing cancellation) rather than genuinely improving the product.

Full reasoning, SQL, and statistical tests are in [`sql/02_business_questions.sql`](sql/02_business_questions.sql) and [`notebooks/HealthFit_Analysis_EDA.ipynb`](notebooks/HealthFit_Analysis_EDA.ipynb).

## Recommendations

1. Roll back or redesign the Pricing Page — the CTA and plan comparison need to be clearer, not just different.
2. Fix the cancellation flow immediately — this is a legal/ethical exposure, not only a UX metric.
3. Shift acquisition spend toward channels with higher retention (YouTube) and away from high-churn channels (Instagram).
4. Any future page change should ship behind a proper A/B test, sized adequately, before full rollout.

## Project Structure

```
Dark_Pattern_UX/
├── data/
│   ├── raw/            # raw CSVs
│   └── cleaned/        # Cleaned CSVs (After data-cleaning notebook)
├── notebooks/
│   └── HealthFit_Analysis_EDA.ipynb   # Cleaning + EDA + stats tests
├── sql/
│   ├── 01_schema.sql               # Schema + data generation
│   └── 02_business_questions.sql   # 11 business questions answered
├── dashboard/
│   └── HealthFit_Analysis_Dashboard.pbix    # 5-page Power BI dashboard
├── requirements.txt
└── README.md
```

## About

Built by **Bhushan Rajguru** as part of a data analytics portfolio.
[GitHub](https://github.com/RajguruBhushan) 
