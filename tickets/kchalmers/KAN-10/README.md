# KAN-10: Global CO2 Emissions Analysis

**Jira Ticket:** [KAN-10](https://kclabs.atlassian.net/browse/KAN-10)
**Status:** Done
**Date:** 2026-01-21

## Objective

Analyze global CO2 emissions data to identify top emitting countries and track US emissions trends over time.

## Data Source

- **Source:** Our World in Data (OWID)
- **URL:** https://owid-public.owid.io/data/co2/owid-co2-data.csv
- **Records:** 50,411 rows (1750-2024)
- **S3 Location:** s3://kclabs-athena-demo-2026/co2-emissions/owid-co2-data.csv
- **Snowflake Table:** `ANALYTICS.DEVELOPMENT.CO2_EMISSIONS`

## Key Findings

### Top 10 CO2 Emitting Countries (2024)

| Rank | Country | CO2 (Million Tonnes) | Per Capita | Global Share |
|------|---------|---------------------|------------|--------------|
| 1 | China | 12,289 | 8.66 | 41.9% |
| 2 | United States | 4,904 | 14.20 | 2.5% |
| 3 | India | 3,193 | 2.20 | 12.6% |
| 4 | Russia | 1,781 | 12.29 | 1.7% |
| 5 | Japan | 962 | 7.77 | 1.4% |
| 6 | Indonesia | 812 | 2.87 | 2.0% |
| 7 | Iran | 793 | 8.66 | 2.5% |
| 8 | Saudi Arabia | 692 | 20.38 | 2.0% |
| 9 | South Korea | 584 | 11.29 | 1.4% |
| 10 | Germany | 572 | 6.77 | 0.7% |

### US Emissions Trend (2000-2024)

- **2000:** 6,023 MT (21.4 per capita)
- **2024:** 4,904 MT (14.2 per capita)
- **Total Reduction:** 18.6% absolute, 33.6% per capita
- **Largest Drop:** 2020 (-10.4% due to COVID)
- **Global Share:** Declined from 5.8% to 2.5%

## Deliverables

| File | Description |
|------|-------------|
| `0_data_load.sql` | Table creation and data load script |
| `1_top_10_emitters_2024.sql` | Query for top 10 emitters |
| `1_top_10_emitters_2024.csv` | Results (10 rows) |
| `2_us_emissions_trend_2000_2024.sql` | Query for US trend analysis |
| `2_us_emissions_trend_2000_2024.csv` | Results (25 rows) |

## Assumptions

1. **Country filtering:** Excluded aggregate entities (OWID_WRL, OWID_INT) from country rankings
2. **CO2 metric:** Used fossil fuel CO2 emissions (column `co2`), not land-use change inclusive
3. **Year selection:** 2024 is the most recent complete year in the dataset
4. **US identification:** Used country name "United States" for filtering

## Technical Notes

- Data loaded via Snowflake internal stage due to S3 integration bucket restrictions
- Table contains subset of OWID columns relevant to this analysis (10 of 79 columns)
- Role used: ACCOUNTADMIN
