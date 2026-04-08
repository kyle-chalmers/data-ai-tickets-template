# Demo Datasets

Datasets for the workshop demo and exercise example scenarios.

## Public Datasets (download manually)

These datasets require free accounts to download. Place the CSV files in this folder.

### Coffee Shop Sales (Example Scenario 1: Automate a Report)

- **Source:** [Maven Analytics Data Playground](https://mavenanalytics.io/data-playground/coffee-shop-sales)
- **Size:** 149,116 rows, 11 columns
- **License:** Free
- **Description:** Transaction records for a fictitious 3-location NYC coffee shop chain. Includes date/time, store location, product category, product name, unit price, and quantity.
- **Download:** Sign up for a free Maven Analytics account, navigate to the dataset, and download as CSV.
- **Save as:** `coffee_shop_sales.csv`

### Customer Support Tickets (Example Scenario 2: Triage Requests)

- **Source:** [Kaggle](https://www.kaggle.com/datasets/suraj520/customer-support-ticket-dataset)
- **Size:** ~8,500 rows, 17 columns
- **License:** CC0 (public domain)
- **Description:** Tech support tickets with Ticket ID, Customer info, Product, Ticket Type, Subject, Description (free text), Status, Priority, Channel, First Response Time, and Satisfaction Rating.
- **Download:** Sign up for a free Kaggle account, navigate to the dataset, and download as CSV.
- **Save as:** `support_tickets.csv`

## Personal LinkedIn Data (gitignored)

Kyle's LinkedIn export is stored in `../linkedin_data/` and is **not committed to the repo** — it contains personal data (names, messages, connections).

To use your own LinkedIn data:
1. Go to [linkedin.com/mypreferences/d/download-my-data](https://www.linkedin.com/mypreferences/d/download-my-data)
2. Request your data export (takes ~24 hours)
3. Unzip and place relevant CSV files in `../linkedin_data/`

Useful LinkedIn files for the workshop example scenarios:

| File | Rows (Kyle's) | Use Case |
|:-----|:--------------|:---------|
| Connections.csv | 3,729 | Network analysis, growth trends, industry clusters |
| SearchQueries.csv | 3,456 | Search behavior and interest analysis |
| Reactions.csv | 932 | Content engagement patterns |
| Shares.csv | 434 | Posting activity and content strategy |
| Endorsement_Received_Info.csv | 323 | Skills analysis |
| Company Follows.csv | 223 | Industry interest analysis |
| Learning.csv | 221 | Learning summary and recommendations |
| Comments.csv | 162 | Engagement and discussion patterns |
| Skills.csv | 30 | Listed skills inventory |
| Rich_Media.csv | 25 | Media sharing patterns |
| Positions.csv | 17 | Career history analysis |
