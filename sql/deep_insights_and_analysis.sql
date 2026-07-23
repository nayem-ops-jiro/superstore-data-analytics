-- =============================================================================
-- Project: Superstore Sales & Profitability Analysis
-- Author: Nayem Sij
-- Tool: MySQL / PostgreSQL
-- Purpose: Exploratory Data Analysis (EDA) to investigate discount impact,
--          regional performance, and product-level profit loss.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- SECTION 1: DATA CLEANING & PREPARATION
-- -----------------------------------------------------------------------------

-- Standardize column names for ease of querying
ALTER TABLE samplesuperstore RENAME COLUMN `Ship Mode` TO Ship_mode;
ALTER TABLE samplesuperstore RENAME COLUMN `Sub-Category` TO Sub_category;

-- Add a Profit Status flag to categorize transaction health
ALTER TABLE samplesuperstore ADD Profit_status VARCHAR(15);

UPDATE samplesuperstore
SET Profit_status = CASE 
    WHEN Profit < 0 THEN 'Loss'
    WHEN Profit = 0 THEN 'Even'
    ELSE 'Profit'
END;


-- -----------------------------------------------------------------------------
-- SECTION 2: EXECUTIVE SUMMARY & CATEGORY-LEVEL ANALYSIS
-- -----------------------------------------------------------------------------

-- Calculate Profit Margin % and Share of Overall Revenue per Category
SELECT 
    Category,
    ROUND(SUM(Sales), 2) AS total_sales,
    ROUND(SUM(Profit), 2) AS total_profit,
    ROUND((SUM(Profit) / SUM(Sales)) * 100, 2) AS profit_margin_pct,
    ROUND((SUM(Sales) / SUM(SUM(Sales)) OVER()) * 100, 2) AS pct_share_of_total_sales
FROM samplesuperstore
GROUP BY Category;

-- Identify Sub-Categories operating at an overall NET LOSS
SELECT 
    Category,
    Sub_category,
    ROUND(SUM(Sales), 2) AS total_sales,
    ROUND(SUM(Profit), 2) AS total_loss,
    ROUND(AVG(Discount) * 100, 1) AS avg_discount_pct
FROM samplesuperstore
GROUP BY Category, Sub_category
HAVING SUM(Profit) < 0
ORDER BY total_loss ASC;


-- -----------------------------------------------------------------------------
-- SECTION 3: DISCOUNT ANALYSIS (KEY PROFIT DRIVER INVESTIGATION)
-- -----------------------------------------------------------------------------

-- Group orders by Discount Tiers to prove deep discounting causes profit loss
SELECT 
    CASE 
        WHEN Discount = 0 THEN '0% (No Discount)'
        WHEN Discount > 0 AND Discount <= 0.20 THEN '1% - 20% (Low)'
        WHEN Discount > 0.20 AND Discount <= 0.50 THEN '21% - 50% (Medium)'
        ELSE '51%+ (High)'
    END AS discount_tier,
    COUNT(*) AS total_orders,
    ROUND(SUM(Sales), 2) AS total_sales,
    ROUND(SUM(Profit), 2) AS total_profit,
    ROUND((SUM(Profit) / SUM(Sales)) * 100, 2) AS profit_margin_pct
FROM samplesuperstore
GROUP BY discount_tier
ORDER BY total_profit DESC;

-- Calculate total revenue lost directly to discounting across categories
SELECT 
    Category,
    ROUND(SUM(Sales), 2) AS discounted_revenue,
    ROUND(SUM(Sales / (1 - Discount) * Discount), 2) AS estimated_discount_dollars
FROM samplesuperstore
WHERE Discount > 0
GROUP BY Category
ORDER BY estimated_discount_dollars DESC;


-- -----------------------------------------------------------------------------
-- SECTION 4: GEOGRAPHIC PERFORMANCE & DEEP DIVES
-- -----------------------------------------------------------------------------

-- State-level Sales & Profit contribution (% of total company metrics)
SELECT DISTINCT 
    State,
    SUM(Sales) OVER (PARTITION BY State) AS state_sales,
    ROUND(SUM(Sales) OVER (PARTITION BY State) / SUM(Sales) OVER() * 100, 2) AS pct_of_total_sales,
    SUM(Profit) OVER (PARTITION BY State) AS state_profit,
    ROUND(SUM(Profit) OVER (PARTITION BY State) / SUM(Profit) OVER() * 100, 2) AS pct_of_total_profit
FROM samplesuperstore
ORDER BY state_sales DESC;

-- CTE: Find Cities whose total losses are worse than the average loss-making city
WITH CityTotals AS (
    SELECT 
        City,
        SUM(Profit) AS total_profit
    FROM samplesuperstore
    GROUP BY City
)
SELECT 
    City,
    ROUND(total_profit, 2) AS total_profit
FROM CityTotals
WHERE total_profit < (
    SELECT AVG(total_profit) 
    FROM CityTotals 
    WHERE total_profit < 0
)
ORDER BY total_profit ASC;


-- -----------------------------------------------------------------------------
-- SECTION 5: ADVANCED RANKING (TOP PRODUCTS PER CATEGORY)
-- -----------------------------------------------------------------------------

-- Rank top 2 sub-categories within each product category using DENSE_RANK()
WITH RankedProducts AS (
    SELECT 
        Category,
        Sub_category,
        SUM(Profit) AS total_profit,
        DENSE_RANK() OVER (PARTITION BY Category ORDER BY SUM(Profit) DESC) AS category_rank
    FROM samplesuperstore
    GROUP BY Category, Sub_category
)
SELECT Category, Sub_category, total_profit, category_rank
FROM RankedProducts
WHERE category_rank <= 2;
