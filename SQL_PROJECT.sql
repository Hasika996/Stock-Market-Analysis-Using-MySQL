-- ============================================================
-- 1. CREATE DATABASE
-- Creates a new database called stock_market
-- ============================================================

CREATE DATABASE stock_market;

-- Select the database so that all following commands use it
USE stock_market;


-- ============================================================
-- 2. CREATE TABLE
-- Creates a table to store stock market data
-- ============================================================

CREATE TABLE stock_data (
    Date DATE,                    -- Trading date
    Close DECIMAL(12,6),          -- Closing price
    High DECIMAL(12,6),           -- Highest price of the day
    Low DECIMAL(12,6),            -- Lowest price of the day
    Open DECIMAL(12,6),           -- Opening price
    Volume BIGINT,                -- Number of shares traded
    Symbol VARCHAR(10)            -- Company stock symbol (AAPL, MSFT, etc.)
);


-- ============================================================
-- 3. COUNT TOTAL RECORDS
-- Finds how many rows/records are present in the table
-- ============================================================

SELECT COUNT(*)
FROM stock_data;


-- ============================================================
-- 4. VIEW SAMPLE DATA
-- Displays the first 10 rows to check the imported data
-- ============================================================

SELECT *
FROM stock_data
LIMIT 10;


-- ============================================================
-- 5. FIND ALL COMPANIES
-- DISTINCT removes duplicate company symbols
-- Shows which companies are present in the dataset
-- ============================================================

SELECT DISTINCT Symbol
FROM stock_data;


-- ============================================================
-- 6. NUMBER OF RECORDS FOR EACH COMPANY
-- COUNT(*) counts how many records each company has
-- GROUP BY Symbol groups the data company-wise
-- ============================================================

SELECT 
    Symbol,
    COUNT(*) AS total_records
FROM stock_data
GROUP BY Symbol
ORDER BY total_records DESC;


-- ============================================================
-- 7. DATASET DATE RANGE FOR EACH COMPANY
-- MIN(Date) = earliest date
-- MAX(Date) = latest date
-- Shows how much historical data we have for each company
-- ============================================================

SELECT
    Symbol,
    MIN(Date) AS first_date,
    MAX(Date) AS last_date
FROM stock_data
GROUP BY Symbol
ORDER BY Symbol;


-- ============================================================
-- 8. HIGHEST CLOSING PRICE
-- Finds the maximum closing price recorded for each company
-- ============================================================

SELECT
    Symbol,
    MAX(Close) AS highest_close
FROM stock_data
GROUP BY Symbol
ORDER BY highest_close DESC;


-- ============================================================
-- 9. AVERAGE CLOSING PRICE
-- Calculates the average closing price for each company
-- ============================================================

SELECT
    Symbol,
    ROUND(AVG(Close), 2) AS average_close
FROM stock_data
GROUP BY Symbol
ORDER BY average_close DESC;


-- ============================================================
-- 10. HIGHEST AND LOWEST CLOSING PRICE
-- MAX(Close) gives the highest closing price
-- MIN(Close) gives the lowest closing price
-- ============================================================

SELECT
    Symbol,
    MAX(Close) AS highest_close,
    MIN(Close) AS lowest_close
FROM stock_data
GROUP BY Symbol
ORDER BY Symbol;


-- ============================================================
-- 11. HIGHEST TRADING VOLUME FOR EACH COMPANY
-- Finds the maximum number of shares traded on a single day
-- ============================================================

SELECT
    Symbol,
    MAX(Volume) AS highest_volume
FROM stock_data
GROUP BY Symbol
ORDER BY highest_volume DESC;


-- ============================================================
-- 12. TOP 20 HIGHEST-VOLUME TRADING DAYS
-- Shows the 20 days with the highest trading volume
-- ============================================================

SELECT
    Date,
    Symbol,
    Volume
FROM stock_data
ORDER BY Volume DESC
LIMIT 20;


-- ============================================================
-- 13. PREVIOUS DAY'S CLOSING PRICE
-- LAG() gets the previous closing price for each company
--
-- PARTITION BY Symbol:
-- Calculates previous price separately for each company
--
-- ORDER BY Date:
-- Makes sure prices are considered chronologically
-- ============================================================

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


-- ============================================================
-- 14. TOTAL RETURN OF EACH STOCK
--
-- ROW_NUMBER() identifies:
-- first_row = first trading day
-- last_row  = last trading day
--
-- Then we calculate:
--
-- Total Return % =
-- ((Ending Price - Starting Price) / Starting Price) * 100
--
-- This tells us how much each stock gained/lost
-- over the entire dataset period.
-- ============================================================

WITH ranked_prices AS (

    SELECT
        Symbol,
        Date,
        Close,

        -- Number rows from the beginning
        ROW_NUMBER() OVER (
            PARTITION BY Symbol
            ORDER BY Date
        ) AS first_row,

        -- Number rows from the end
        ROW_NUMBER() OVER (
            PARTITION BY Symbol
            ORDER BY Date DESC
        ) AS last_row

    FROM stock_data
),

summary AS (

    SELECT
        Symbol,

        -- Get closing price from the first trading day
        MAX(CASE WHEN first_row = 1 THEN Close END) AS starting_price,

        -- Get closing price from the last trading day
        MAX(CASE WHEN last_row = 1 THEN Close END) AS ending_price

    FROM ranked_prices
    GROUP BY Symbol
)

SELECT
    Symbol,

    ROUND(starting_price, 2) AS starting_price,
    ROUND(ending_price, 2) AS ending_price,

    -- Calculate total percentage return
    ROUND(
        ((ending_price - starting_price) / starting_price) * 100,
        2
    ) AS total_return_pct

FROM summary

ORDER BY total_return_pct DESC;


-- ============================================================
-- 15. 30-DAY MOVING AVERAGE
--
-- AVG(Close) calculates the average closing price
--
-- ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
-- means:
-- Current day + previous 29 days = 30 trading-day window
--
-- Moving averages help identify the overall price trend.
-- ============================================================

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


-- ============================================================
-- 16. STOCK VOLATILITY
--
-- Step 1:
-- LAG() gets the previous day's closing price
--
-- Step 2:
-- Calculate daily return:
--
-- ((Today's Close - Previous Close)
--  / Previous Close) * 100
--
-- Step 3:
-- STDDEV() calculates the standard deviation
-- of daily returns.
--
-- Higher volatility = stock price changes more heavily
-- Lower volatility = stock price is relatively more stable
-- ============================================================

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

        -- Daily percentage return
        ((Close - previous_close) / previous_close) * 100
            AS daily_return

    FROM prices

    WHERE previous_close IS NOT NULL
)

SELECT
    Symbol,

    -- Standard deviation of daily returns = volatility
    ROUND(STDDEV(daily_return), 2) AS volatility_pct

FROM returns

GROUP BY Symbol

ORDER BY volatility_pct DESC;


-- ============================================================
-- 17. STOCK PERFORMANCE RANKING
--
-- First we find the starting and ending price.
--
-- Then calculate total return.
--
-- Finally RANK() ranks companies based on their return.
--
-- Rank 1 = highest-performing stock
-- ============================================================

WITH ranked_prices AS (

    SELECT
        Symbol,
        Date,
        Close,

        -- First trading day
        ROW_NUMBER() OVER (
            PARTITION BY Symbol
            ORDER BY Date
        ) AS first_row,

        -- Last trading day
        ROW_NUMBER() OVER (
            PARTITION BY Symbol
            ORDER BY Date DESC
        ) AS last_row

    FROM stock_data
),

performance AS (

    SELECT
        Symbol,

        -- Starting price
        MAX(CASE WHEN first_row = 1 THEN Close END)
            AS starting_price,

        -- Ending price
        MAX(CASE WHEN last_row = 1 THEN Close END)
            AS ending_price

    FROM ranked_prices

    GROUP BY Symbol
)

SELECT
    Symbol,

    ROUND(starting_price, 2) AS starting_price,

    ROUND(ending_price, 2) AS ending_price,

    -- Calculate total return percentage
    ROUND(
        ((ending_price - starting_price) / starting_price) * 100,
        2
    ) AS total_return_pct,

    -- Rank stocks according to total return
    RANK() OVER (
        ORDER BY
        ((ending_price - starting_price) / starting_price) DESC
    ) AS performance_rank

FROM performance

ORDER BY performance_rank;


    






