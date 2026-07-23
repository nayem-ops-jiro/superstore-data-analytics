SELECT *
FROM samplesuperstore;

SELECT *
FROM samplesuperstore
WHERE Discount != 0 AND Profit < 0
ORDER BY Profit ;

SELECT *
FROM samplesuperstore
WHERE Discount != 0 AND Profit < 0
ORDER BY Discount ;

SELECT State, AVG(Profit) AS AVG_Profit, SUM(Profit) AS SUM_Profit, MAX(Profit), MIN(Profit)
FROM samplesuperstore
GROUP BY State
ORDER BY AVG_Profit;

SELECT Region, AVG(Profit) AS AVG_Profit, SUM(Profit) AS SUM_Profit, MAX(Profit), MIN(Profit)
FROM samplesuperstore
GROUP BY Region
ORDER BY AVG_Profit;


SELECT Segment,SUM(Sales),AVG(Sales), MAX(Sales), MIN(Sales)
FROM samplesuperstore
GROUP BY Segment
ORDER BY SUM(Sales);

ALTER TABLE `supestore_data`.`samplesuperstore`
RENAME COLUMN `Ship Mode` TO `Ship_mode`;

SELECT Ship_mode, SUM(Sales),SUM(Profit), SUM(Quantity)
FROM samplesuperstore
GROUP BY Ship_mode
ORDER BY SUM(Sales);

SELECT Category,SUM(Sales),SUM(Profit), SUM(Quantity), MAX(Discount)
FROM samplesuperstore
GROUP BY Category;

SELECT 
    Category,
    ROUND((SUM(Profit) / SUM(Sales)) * 100, 2) AS profit_margin_pct,
    ROUND((SUM(Sales)/SUM(SUM(Sales))OVER())*100,2) AS TOTAL_SHARE
FROM samplesuperstore
GROUP BY Category;

ALTER TABLE samplesuperstore
RENAME COLUMN `Sub-Category` TO Sub_category;


SELECT Sub_category,SUM(Sales),SUM(Profit), SUM(Quantity), MAX(Discount)
FROM samplesuperstore
group by Sub_category
ORDER BY SUM(Profit);

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

SELECT 
    Category,
    ROUND(SUM(Sales), 2) AS discounted_revenue,
    ROUND(SUM(Sales / (1 - Discount) * Discount), 2) AS total_discount_given
FROM samplesuperstore
WHERE Discount > 0
GROUP BY Category
ORDER BY total_discount_given DESC;

SELECT 
    Sub_category,
    ROUND(AVG(Discount) * 100, 1) AS avg_discount_pct,
    ROUND(SUM(Profit), 2) AS total_profit
FROM samplesuperstore
GROUP BY Sub_category

ORDER BY total_profit ASC;

ALTER TABLE samplesuperstore
ADD Profit_status VARCHAR(15);

SELECT *
FROM samplesuperstore;

UPDATE samplesuperstore
SET Profit_status = CASE 
	WHEN Profit < 0 THEN 'Loss'
    WHEN Profit = 0 THEN 'Even'
    ELSE 'Profit'
END;    
    

CREATE TABLE samplesuperstore2
LIKE samplesuperstore;

INSERT samplesuperstore2
SELECT *
FROM samplesuperstore;

SELECT *
FROM samplesuperstore2;

SELECT Category,Sub_category,Sales,Quantity,Discount,Profit,Profit_status
FROM samplesuperstore2
where Profit > 100
UNION
SELECT Category,Sub_category,Sales,Quantity,Discount,Profit,Profit_status
FROM samplesuperstore2
where Profit < -100
ORDER BY Profit DESC;

SELECT  Discount, SUM(Profit), SUM(Sales), SUM(Quantity), ROUND(SUM(Profit)/SUM(Sales)*100,2) AS Profit_percentage
FROM samplesuperstore2
GROUP BY Discount
ORDER BY Discount ;

select DISTINCT State,
SUM(Sales)over (partition by State ) as state_sales,ROUND(SUM(Sales) OVER(PARTITION BY State)/SUM(Sales)OVER()*100,2) as pct_of_state_sales,
SUM(Profit) OVER(PARTITION BY State) as state_profit ,ROUND(SUM(Profit) OVER(PARTITION BY State)/SUM(Profit)OVER()*100,2) as pct_of_state_profit
from samplesuperstore2
order by pct_of_state_sales desc;


SELECT 
    Category,
    Sub_category,
    ROUND(SUM(Sales), 2) AS total_sales,
    ROUND(SUM(Profit), 2) AS total_loss,
    ROUND(AVG(Discount) * 100, 1) AS avg_discount_pct
FROM samplesuperstore2
GROUP BY Category, Sub_category
HAVING SUM(Profit) < 0
ORDER BY total_loss ASC;

SELECT City, SUM(Profit)
FROM samplesuperstore2
GROUP BY City
HAVING SUM(Profit) < 0
;


WITH CityTotals AS (
    SELECT 
        City,
        SUM(Profit) AS total_profit
    FROM samplesuperstore2
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


WITH RankedProducts AS (
    SELECT 
        Category,
        Sub_category,
        SUM(Profit) AS total_profit,
        DENSE_RANK() OVER (PARTITION BY Category ORDER BY SUM(Profit) DESC) AS category_rank
    FROM samplesuperstore2
    GROUP BY Category, Sub_category
)
SELECT Category, Sub_category, total_profit, category_rank
FROM RankedProducts
WHERE category_rank <= 2;
