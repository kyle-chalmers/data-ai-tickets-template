-- =============================================================================
-- AWS Athena Infrastructure Setup for Climate Data Analysis
-- Source: IMF Global Surface Temperature Dataset
-- =============================================================================

-- Step 1: Create Database
CREATE DATABASE IF NOT EXISTS climate_demo;

-- Step 2: Create External Table
-- Points to S3 location: s3://kclabs-athena-demo-2026/climate-data/
-- Data: Annual mean surface temperature change (degrees Celsius) vs 1951-1980 baseline
CREATE EXTERNAL TABLE IF NOT EXISTS climate_demo.global_temperature (
    ObjectId INT,
    Country STRING,
    ISO2 STRING,
    ISO3 STRING,
    Indicator STRING,
    Unit STRING,
    Source STRING,
    CTS_Code STRING,
    CTS_Name STRING,
    CTS_Full_Descriptor STRING,
    Y1961 DOUBLE, Y1962 DOUBLE, Y1963 DOUBLE, Y1964 DOUBLE, Y1965 DOUBLE,
    Y1966 DOUBLE, Y1967 DOUBLE, Y1968 DOUBLE, Y1969 DOUBLE, Y1970 DOUBLE,
    Y1971 DOUBLE, Y1972 DOUBLE, Y1973 DOUBLE, Y1974 DOUBLE, Y1975 DOUBLE,
    Y1976 DOUBLE, Y1977 DOUBLE, Y1978 DOUBLE, Y1979 DOUBLE, Y1980 DOUBLE,
    Y1981 DOUBLE, Y1982 DOUBLE, Y1983 DOUBLE, Y1984 DOUBLE, Y1985 DOUBLE,
    Y1986 DOUBLE, Y1987 DOUBLE, Y1988 DOUBLE, Y1989 DOUBLE, Y1990 DOUBLE,
    Y1991 DOUBLE, Y1992 DOUBLE, Y1993 DOUBLE, Y1994 DOUBLE, Y1995 DOUBLE,
    Y1996 DOUBLE, Y1997 DOUBLE, Y1998 DOUBLE, Y1999 DOUBLE, Y2000 DOUBLE,
    Y2001 DOUBLE, Y2002 DOUBLE, Y2003 DOUBLE, Y2004 DOUBLE, Y2005 DOUBLE,
    Y2006 DOUBLE, Y2007 DOUBLE, Y2008 DOUBLE, Y2009 DOUBLE, Y2010 DOUBLE,
    Y2011 DOUBLE, Y2012 DOUBLE, Y2013 DOUBLE, Y2014 DOUBLE, Y2015 DOUBLE,
    Y2016 DOUBLE, Y2017 DOUBLE, Y2018 DOUBLE, Y2019 DOUBLE, Y2020 DOUBLE,
    Y2021 DOUBLE, Y2022 DOUBLE, Y2023 DOUBLE, Y2024 DOUBLE
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE
LOCATION 's3://kclabs-athena-demo-2026/climate-data/'
TBLPROPERTIES ('skip.header.line.count'='1');

-- Verification Query
SELECT COUNT(*) as row_count FROM climate_demo.global_temperature;
-- Expected: 231 rows (countries/regions)
