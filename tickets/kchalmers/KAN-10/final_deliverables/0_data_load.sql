-- Data Load Script for CO2 Emissions Analysis
-- Source: Our World in Data - https://owid-public.owid.io/data/co2/owid-co2-data.csv
-- Target: ANALYTICS.DEVELOPMENT.CO2_EMISSIONS

-- Step 1: Create table
CREATE OR REPLACE TABLE ANALYTICS.DEVELOPMENT.CO2_EMISSIONS (
    COUNTRY VARCHAR,
    YEAR INTEGER,
    ISO_CODE VARCHAR,
    POPULATION FLOAT,
    GDP FLOAT,
    CO2 FLOAT,
    CO2_PER_CAPITA FLOAT,
    CO2_GROWTH_PRCT FLOAT,
    CUMULATIVE_CO2 FLOAT,
    SHARE_GLOBAL_CO2 FLOAT
);

-- Step 2: Create internal stage
CREATE OR REPLACE STAGE ANALYTICS.DEVELOPMENT.CO2_INTERNAL_STAGE
  FILE_FORMAT = (TYPE = CSV FIELD_OPTIONALLY_ENCLOSED_BY = '"' SKIP_HEADER = 1 NULL_IF = (''));

-- Step 3: Upload file to stage (run from CLI)
-- snow stage copy /tmp/owid-co2-data.csv @ANALYTICS.DEVELOPMENT.CO2_INTERNAL_STAGE --role ACCOUNTADMIN

-- Step 4: Load data from stage
-- Column mapping from source CSV:
--   $1 = country, $2 = year, $3 = iso_code, $4 = population, $5 = gdp
--   $8 = co2, $17 = co2_per_capita, $10 = co2_growth_prct
--   $26 = cumulative_co2, $53 = share_global_co2
COPY INTO ANALYTICS.DEVELOPMENT.CO2_EMISSIONS
    (COUNTRY, YEAR, ISO_CODE, POPULATION, GDP, CO2, CO2_PER_CAPITA, CO2_GROWTH_PRCT, CUMULATIVE_CO2, SHARE_GLOBAL_CO2)
FROM (
    SELECT $1, $2, $3, $4, $5, $8, $17, $10, $26, $53
    FROM @ANALYTICS.DEVELOPMENT.CO2_INTERNAL_STAGE/owid-co2-data.csv
)
FILE_FORMAT = (TYPE = CSV FIELD_OPTIONALLY_ENCLOSED_BY = '"' SKIP_HEADER = 1 NULL_IF = (''))
ON_ERROR = 'CONTINUE';

-- Verification
SELECT COUNT(*) AS ROW_COUNT FROM ANALYTICS.DEVELOPMENT.CO2_EMISSIONS;
-- Expected: 50,411 rows
