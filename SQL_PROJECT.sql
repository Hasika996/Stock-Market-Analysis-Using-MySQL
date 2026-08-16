CREATE DATABASE stock_market;
USE stock_market;
CREATE TABLE stock_data (
    Date DATE,
    Close DECIMAL(12,6),
    High DECIMAL(12,6),
    Low DECIMAL(12,6),
    Open DECIMAL(12,6),
    Volume BIGINT,
    Symbol VARCHAR(10)
);
SELECT COUNT(*) FROM stock_data;

SELECT *
FROM stock_data
LIMIT 10;
SELECT DISTINCT Symbol
FROM stock_data;
SELECT 
    Symbol,
    COUNT(*) AS total_records
FROM stock_data
GROUP BY Symbol
ORDER BY total_records DESC;
SELECT
    Symbol,
    MIN(Date) AS first_date,
    MAX(Date) AS last_date
FROM stock_data
GROUP BY Symbol
ORDER BY Symbol;
SELECT
    Symbol,
    MAX(Close) AS highest_close
FROM stock_data
GROUP BY Symbol
ORDER BY highest_close DESC;
SELECT
    Symbol,
    ROUND(AVG(Close), 2) AS average_close
FROM stock_data
GROUP BY Symbol
ORDER BY average_close DESC;
SELECT
    Symbol,
    MAX(Close) AS highest_close,
    MIN(Close) AS lowest_close
FROM stock_data
GROUP BY Symbol
ORDER BY Symbol;
SELECT
    Symbol,
    MAX(Volume) AS highest_volume
FROM stock_data
GROUP BY Symbol
ORDER BY highest_volume DESC;
SELECT
    Date,
    Symbol,
    Volume
FROM stock_data
ORDER BY Volume DESC
LIMIT 20;
WITH prices AS (
    SELECT
        Date,
        Symbol,
        Close,
        LAG(Close) OVER (
            PARTITION BY Symbol
            ORDER BY Date
        ) AS previous_close
    FROM stock_data
)
SELECT *
FROM prices
WHERE previous_close IS NOT NULL
ORDER BY Date
LIMIT 20;
WITH ranked_prices AS (
    SELECT
        Symbol,
        Date,
        Close,
        ROW_NUMBER() OVER (
            PARTITION BY Symbol
            ORDER BY Date
        ) AS first_row,
        ROW_NUMBER() OVER (
            PARTITION BY Symbol
            ORDER BY Date DESC
        ) AS last_row
    FROM stock_data
),
summary AS (
    SELECT
        Symbol,
        MAX(CASE WHEN first_row = 1 THEN Close END) AS starting_price,
        MAX(CASE WHEN last_row = 1 THEN Close END) AS ending_price
    FROM ranked_prices
    GROUP BY Symbol
)
SELECT
    Symbol,
    ROUND(starting_price, 2) AS starting_price,
    ROUND(ending_price, 2) AS ending_price,
    ROUND(
        ((ending_price - starting_price) / starting_price) * 100,
        2
    ) AS total_return_pct
FROM summary
ORDER BY total_return_pct DESC;
SELECT
    Date,
    Symbol,
    Close,
    ROUND(
        AVG(Close) OVER (
            PARTITION BY Symbol
            ORDER BY Date
            ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
        ),
        2
    ) AS moving_avg_30
FROM stock_data
ORDER BY Symbol, Date;
WITH prices AS (
    SELECT
        Date,
        Symbol,
        Close,
        LAG(Close) OVER (
            PARTITION BY Symbol
            ORDER BY Date
        ) AS previous_close
    FROM stock_data
),
returns AS (
    SELECT
        Symbol,
        ((Close - previous_close) / previous_close) * 100 AS daily_return
    FROM prices
    WHERE previous_close IS NOT NULL
)
SELECT
    Symbol,
    ROUND(STDDEV(daily_return), 2) AS volatility_pct
FROM returns
GROUP BY Symbol
ORDER BY volatility_pct DESC;
WITH ranked_prices AS (
    SELECT
        Symbol,
        Date,
        Close,
        ROW_NUMBER() OVER (
            PARTITION BY Symbol
            ORDER BY Date
        ) AS first_row,
        ROW_NUMBER() OVER (
            PARTITION BY Symbol
            ORDER BY Date DESC
        ) AS last_row
    FROM stock_data
),
performance AS (
    SELECT
        Symbol,
        MAX(CASE WHEN first_row = 1 THEN Close END) AS starting_price,
        MAX(CASE WHEN last_row = 1 THEN Close END) AS ending_price
    FROM ranked_prices
    GROUP BY Symbol
)
SELECT
    Symbol,
    ROUND(starting_price, 2) AS starting_price,
    ROUND(ending_price, 2) AS ending_price,
    ROUND(
        ((ending_price - starting_price) / starting_price) * 100,
        2
    ) AS total_return_pct,
    RANK() OVER (
        ORDER BY
        ((ending_price - starting_price) / starting_price) DESC
    ) AS performance_rank
FROM performance
ORDER BY performance_rank;


    






