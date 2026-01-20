# Demo 1 Dataset: Our World in Data CO2 Emissions

## Dataset Overview

| Property | Value |
|----------|-------|
| **Name** | Our World in Data CO2 and Greenhouse Gas Emissions |
| **Source** | Our World in Data (GitHub) |
| **Direct Download URL** | https://owid-public.owid.io/data/co2/owid-co2-data.csv |
| **License** | Creative Commons BY 4.0 |
| **Format** | CSV |
| **Rows** | ~50,000 |
| **Countries** | 255 (including regions and aggregates) |
| **Year Range** | 1750-2024 |
| **Last Updated** | December 2025 |

---

## Why This Dataset for Demo

1. **Different from Demo 2**: Demo 2 uses IMF temperature data. This uses CO2 emissions - complementary but distinct climate metrics.

2. **Rich Analysis Potential**: 79 columns covering emissions by sector (coal, oil, gas, cement), per capita metrics, cumulative totals, and global shares.

3. **Reputable Source**: Our World in Data is widely respected for data quality and research methodology.

4. **Current Data**: Includes 2024 data, making analysis timely and relevant.

5. **Clean Structure**: One row per country-year, easy to load and query.

6. **Interesting Stories**: Can show US vs China emissions, top emitters, historical trends, per capita comparisons.

---

## Key Columns for Demo

| Column | Description | Demo Use |
|--------|-------------|----------|
| `country` | Country/region name | Grouping and filtering |
| `year` | Year of observation | Time series analysis |
| `iso_code` | ISO 3166-1 alpha-3 | Joining with other data |
| `co2` | Annual CO2 emissions (million tonnes) | Primary analysis metric |
| `co2_per_capita` | CO2 per person (tonnes) | Per capita comparison |
| `coal_co2` | CO2 from coal | Sector breakdown |
| `oil_co2` | CO2 from oil | Sector breakdown |
| `gas_co2` | CO2 from natural gas | Sector breakdown |
| `share_global_co2` | % of global emissions | Relative comparison |
| `cumulative_co2` | Total historical emissions | Long-term impact |
| `population` | Country population | Context for per capita |
| `gdp` | GDP (real) | Economic context |

---

## Sample Analysis Queries

### Top 10 Emitters (2024)
```sql
SELECT
    country,
    iso_code,
    co2 as annual_co2_mt,
    co2_per_capita,
    share_global_co2
FROM co2_emissions
WHERE year = 2024
  AND iso_code IS NOT NULL
  AND LENGTH(iso_code) = 3
ORDER BY co2 DESC
LIMIT 10;
```

### US Emissions Trend (2000-2024)
```sql
SELECT
    year,
    co2 as annual_co2_mt,
    co2_per_capita,
    coal_co2,
    oil_co2,
    gas_co2
FROM co2_emissions
WHERE country = 'United States'
  AND year >= 2000
ORDER BY year;
```

### Top Per Capita Emitters (2024)
```sql
SELECT
    country,
    co2_per_capita,
    population,
    co2 as total_emissions
FROM co2_emissions
WHERE year = 2024
  AND population > 1000000
  AND co2_per_capita IS NOT NULL
ORDER BY co2_per_capita DESC
LIMIT 10;
```

---

## S3 Upload Target

```
s3://kclabs-athena-demo-2026/co2-emissions/owid-co2-data.csv
```

---

## Snowflake Table Schema

```sql
CREATE OR REPLACE TABLE DEMO_DATA.PUBLIC.CO2_EMISSIONS (
    country VARCHAR,
    year INTEGER,
    iso_code VARCHAR(10),
    population FLOAT,
    gdp FLOAT,
    cement_co2 FLOAT,
    cement_co2_per_capita FLOAT,
    co2 FLOAT,
    co2_growth_abs FLOAT,
    co2_growth_prct FLOAT,
    co2_including_luc FLOAT,
    co2_including_luc_growth_abs FLOAT,
    co2_including_luc_growth_prct FLOAT,
    co2_including_luc_per_capita FLOAT,
    co2_including_luc_per_gdp FLOAT,
    co2_including_luc_per_unit_energy FLOAT,
    co2_per_capita FLOAT,
    co2_per_gdp FLOAT,
    co2_per_unit_energy FLOAT,
    coal_co2 FLOAT,
    coal_co2_per_capita FLOAT,
    consumption_co2 FLOAT,
    consumption_co2_per_capita FLOAT,
    consumption_co2_per_gdp FLOAT,
    cumulative_cement_co2 FLOAT,
    cumulative_co2 FLOAT,
    cumulative_co2_including_luc FLOAT,
    cumulative_coal_co2 FLOAT,
    cumulative_flaring_co2 FLOAT,
    cumulative_gas_co2 FLOAT,
    cumulative_luc_co2 FLOAT,
    cumulative_oil_co2 FLOAT,
    cumulative_other_co2 FLOAT,
    energy_per_capita FLOAT,
    energy_per_gdp FLOAT,
    flaring_co2 FLOAT,
    flaring_co2_per_capita FLOAT,
    gas_co2 FLOAT,
    gas_co2_per_capita FLOAT,
    ghg_excluding_lucf_per_capita FLOAT,
    ghg_per_capita FLOAT,
    land_use_change_co2 FLOAT,
    land_use_change_co2_per_capita FLOAT,
    methane FLOAT,
    methane_per_capita FLOAT,
    nitrous_oxide FLOAT,
    nitrous_oxide_per_capita FLOAT,
    oil_co2 FLOAT,
    oil_co2_per_capita FLOAT,
    other_co2_per_capita FLOAT,
    other_industry_co2 FLOAT,
    primary_energy_consumption FLOAT,
    share_global_cement_co2 FLOAT,
    share_global_co2 FLOAT,
    share_global_co2_including_luc FLOAT,
    share_global_coal_co2 FLOAT,
    share_global_cumulative_cement_co2 FLOAT,
    share_global_cumulative_co2 FLOAT,
    share_global_cumulative_co2_including_luc FLOAT,
    share_global_cumulative_coal_co2 FLOAT,
    share_global_cumulative_flaring_co2 FLOAT,
    share_global_cumulative_gas_co2 FLOAT,
    share_global_cumulative_luc_co2 FLOAT,
    share_global_cumulative_oil_co2 FLOAT,
    share_global_cumulative_other_co2 FLOAT,
    share_global_flaring_co2 FLOAT,
    share_global_gas_co2 FLOAT,
    share_global_luc_co2 FLOAT,
    share_global_oil_co2 FLOAT,
    share_global_other_co2 FLOAT,
    share_of_temperature_change_from_ghg FLOAT,
    temperature_change_from_ch4 FLOAT,
    temperature_change_from_co2 FLOAT,
    temperature_change_from_ghg FLOAT,
    temperature_change_from_n2o FLOAT,
    total_ghg FLOAT,
    total_ghg_excluding_lucf FLOAT,
    trade_co2 FLOAT,
    trade_co2_share FLOAT
);
```

---

## Attribution

When using this data, credit: "Our World in Data, CO2 and Greenhouse Gas Emissions dataset, licensed under CC BY 4.0"

GitHub Repository: https://github.com/owid/co2-data
