<objective>
Replace the current renewable energy catalog dataset with the IMF Global Surface Temperature dataset throughout the AWS S3/Athena video materials.

This involves:
1. Copying the new dataset to sample_data
2. Updating all documentation to reference the new dataset
3. Rewriting SQL examples and Athena table definitions
4. Cleaning up references to the old dataset
</objective>

<context>
**New Dataset:**
- Source: `/Users/kylechalmers/Downloads/Indicator_3_1_Climate_Indicators_Annual_Mean_Global_Surface_Temperature_577579683071085080.csv`
- Rename to: `global_surface_temperature.csv`
- Content: Temperature change (°C) vs 1951-1980 baseline, by country, 1961-2024
- Structure: Wide format (Country, ISO2, ISO3, Indicator, Unit, Source, then year columns 1961-2024)

**Target folder:** `/Users/kylechalmers/Development/data-ai-tickets-template/videos/integrating_aws_s3_athena/`

**Files to update:**
- `README.md`
- `CLAUDE.md`
- `final_deliverables/script_outline.md`
- `example_workflow/README.md`
- `sample_data/` (add new file, remove old)
</context>

<requirements>
1. **Copy and rename dataset:**
   - Copy CSV to `sample_data/global_surface_temperature.csv`
   - Remove old files: `era-ren-collection.csv`, `zarr_metadata/` folder

2. **Update CLAUDE.md:**
   - Change database name to `climate_demo`
   - Change table name to `global_temperature`
   - Update sample query to analyze temperature by country/region
   - Update "Sample Data Source" section with IMF attribution

3. **Update README.md:**
   - Rewrite dataset description section
   - Update S3 paths and table names
   - Rewrite SQL examples for temperature analysis
   - Update Claude Code integration prompts

4. **Update script_outline.md:**
   - Update Section 7 (Practical Workflow Demo) with new table schema
   - Rewrite CREATE EXTERNAL TABLE statement for wide CSV format
   - Update analysis queries for temperature data

5. **Update example_workflow/README.md:**
   - Rewrite all examples for temperature analysis
   - Update SQL queries, prompts, and descriptions

6. **New table schema should be:**
```sql
CREATE EXTERNAL TABLE climate_demo.global_temperature (
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
LOCATION 's3://kclabs-athena-demo-2025/climate-data/'
TBLPROPERTIES ('skip.header.line.count'='1');
```

7. **Example analysis queries:**
```sql
-- Top 10 countries with highest 2024 temperature change
SELECT Country, ISO3, Y2024 as temp_change_2024
FROM climate_demo.global_temperature
WHERE Y2024 IS NOT NULL AND ISO3 IS NOT NULL
ORDER BY Y2024 DESC
LIMIT 10;

-- Temperature trend for USA over decades
SELECT Country, Y1970, Y1980, Y1990, Y2000, Y2010, Y2020, Y2024
FROM climate_demo.global_temperature
WHERE ISO3 = 'USA';

-- Regional averages (continents)
SELECT Country, Y2020, Y2021, Y2022, Y2023, Y2024
FROM climate_demo.global_temperature
WHERE ISO3 LIKE '%TMP'  -- Continental aggregates
ORDER BY Y2024 DESC;
```
</requirements>

<implementation>
1. First copy the new dataset and clean up old files
2. Update CLAUDE.md (the AWS CLI reference file)
3. Update README.md (main video documentation)
4. Update script_outline.md (video script)
5. Update example_workflow/README.md

Ensure consistent naming throughout:
- Database: `climate_demo`
- Table: `global_temperature`
- S3 path: `s3://kclabs-athena-demo-2025/climate-data/`
</implementation>

<verification>
After all updates:
1. Verify no references to "renewable", "energy", "era-ren", "wildfire" remain:
   ```bash
   grep -ri "renewable\|era-ren\|wildfire\|energy_catalog" /Users/kylechalmers/Development/data-ai-tickets-template/videos/integrating_aws_s3_athena/
   ```

2. Verify new dataset exists:
   ```bash
   ls -la /Users/kylechalmers/Development/data-ai-tickets-template/videos/integrating_aws_s3_athena/sample_data/
   ```

3. Verify consistent naming (climate_demo, global_temperature) across all files
</verification>

<success_criteria>
- New dataset `global_surface_temperature.csv` in sample_data/
- Old dataset files removed
- All documentation references the IMF temperature dataset
- SQL examples query temperature data meaningfully
- Consistent database/table naming across all files
- No references to old renewable energy dataset
</success_criteria>
