# Demo Datasets

Datasets for the workshop demo and exercise archetypes.

## Public Datasets (download manually)

These datasets require free accounts to download. Place the CSV files in this folder.

### Coffee Shop Sales (Archetype 1: Automate a Report)

- **Source:** [Maven Analytics Data Playground](https://mavenanalytics.io/data-playground/coffee-shop-sales)
- **Size:** 149,116 rows, 11 columns
- **License:** Free
- **Description:** Transaction records for a fictitious 3-location NYC coffee shop chain. Includes date/time, store location, product category, product name, unit price, and quantity.
- **Download:** Sign up for a free Maven Analytics account, navigate to the dataset, and download as CSV.
- **Save as:** `coffee_shop_sales.csv`

### Customer Support Tickets (Archetype 2: Triage Requests)

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

Useful LinkedIn files for the workshop archetypes:

| File | Rows (Kyle's) | Use Case |
|:-----|:--------------|:---------|
| Connections.csv | 3,723 | Network analysis, growth trends, industry clusters |
| messages.csv | Large | Inbox triage and categorization |
| Endorsement_Received_Info.csv | 324 | Skills analysis |
| Learning.csv | 221 | Learning summary and recommendations |
| Company Follows.csv | 221 | Industry interest analysis |
| Invitations.csv | 205 | Networking activity patterns |
| Rich_Media.csv | 57 | Posting pattern analysis |
