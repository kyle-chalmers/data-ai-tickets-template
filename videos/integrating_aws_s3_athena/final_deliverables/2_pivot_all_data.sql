-- =============================================================================
-- Pivot Query: Transform Wide Format to Long Format
-- Uses CROSS JOIN UNNEST with parallel arrays (efficient single-scan approach)
-- Output: Country, ISO3, Year, temperature_change
-- =============================================================================

SELECT
    Country,
    ISO3,
    year AS Year,
    temp AS temperature_change
FROM climate_demo.global_temperature
CROSS JOIN UNNEST(
    ARRAY[1961,1962,1963,1964,1965,1966,1967,1968,1969,1970,
          1971,1972,1973,1974,1975,1976,1977,1978,1979,1980,
          1981,1982,1983,1984,1985,1986,1987,1988,1989,1990,
          1991,1992,1993,1994,1995,1996,1997,1998,1999,2000,
          2001,2002,2003,2004,2005,2006,2007,2008,2009,2010,
          2011,2012,2013,2014,2015,2016,2017,2018,2019,2020,
          2021,2022,2023,2024],
    ARRAY[Y1961,Y1962,Y1963,Y1964,Y1965,Y1966,Y1967,Y1968,Y1969,Y1970,
          Y1971,Y1972,Y1973,Y1974,Y1975,Y1976,Y1977,Y1978,Y1979,Y1980,
          Y1981,Y1982,Y1983,Y1984,Y1985,Y1986,Y1987,Y1988,Y1989,Y1990,
          Y1991,Y1992,Y1993,Y1994,Y1995,Y1996,Y1997,Y1998,Y1999,Y2000,
          Y2001,Y2002,Y2003,Y2004,Y2005,Y2006,Y2007,Y2008,Y2009,Y2010,
          Y2011,Y2012,Y2013,Y2014,Y2015,Y2016,Y2017,Y2018,Y2019,Y2020,
          Y2021,Y2022,Y2023,Y2024]
) AS t(year, temp)
WHERE temp IS NOT NULL
ORDER BY temperature_change DESC;

-- =============================================================================
-- Performance Comparison vs UNION ALL approach:
--
-- | Metric         | UNION ALL  | UNNEST   | Improvement |
-- |----------------|------------|----------|-------------|
-- | Data Scanned   | 12.3 MB    | 192 KB   | 64x less    |
-- | Engine Time    | 1,468ms    | 864ms    | 41% faster  |
-- | Planning Time  | 804ms      | 113ms    | 7x faster   |
--
-- The UNNEST approach scans the table ONCE instead of 64 times.
-- =============================================================================

-- Output: 11,898 rows (231 countries × ~64 years, minus nulls)
-- Columns: Country, ISO3, Year, temperature_change
