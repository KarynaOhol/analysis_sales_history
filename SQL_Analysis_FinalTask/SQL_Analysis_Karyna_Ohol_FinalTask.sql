--======================================================================================================================
-- Task 1. Window Functions
--======================================================================================================================

-- Create a query to generate a report that identifies for each channel and throughout the entire period,
-- the regions with the highest quantity of products sold (quantity_sold).
-- The resulting report should include the following columns:
-- CHANNEL_DESC
-- COUNTRY_REGION
-- SALES: This column will display the number of products sold (quantity_sold) with two decimal places.
-- SALES %: This column will show the percentage of maximum sales in the region (as displayed in the SALES column)
-- compared to the total sales for that channel. The sales percentage should be displayed with two decimal
-- places and include the percent sign (%) at the end.
-- Display the result in descending order of SALES

WITH ranked_sales AS (SELECT ch.channel_desc
                           , cou.country_region
                           , SUM(s.quantity_sold)                                                          as sales
                           , SUM(SUM(s.quantity_sold)) OVER (PARTITION BY channel_desc)                    as channel_sales
                           , RANK() OVER (PARTITION BY ch.channel_desc ORDER BY SUM(s.quantity_sold) DESC) as rank
                      FROM sh.sales s
                               JOIN sh.channels ch ON ch.channel_id = s.channel_id
                               JOIN sh.customers c ON c.cust_id = s.cust_id
                               JOIN sh.countries cou ON c.country_id = cou.country_id
                      GROUP BY ch.channel_desc, cou.country_region)
SELECT channel_desc
     , country_region
     , ROUND(sales, 2)                                as sales
     , ROUND((sales / channel_sales) * 100, 2) || '%' as "sales%"
FROM ranked_sales
WHERE rank = 1
ORDER BY sales DESC;
--======================================================================================================================
-- Task 2. Window Functions
--======================================================================================================================

-- Identify the subcategories of products with consistently higher sales from 1998 to 2001 compared to the previous year.
-- Determine the sales for each subcategory from 1998 to 2001.
-- Calculate the sales for the previous year for each subcategory.
-- Identify subcategories where the sales from 1998 to 2001 are consistently higher than the previous year.
-- Generate a dataset with a single column containing the identified prod_subcategory values.

WITH sales_comparison AS (SELECT p.prod_subcategory
                               , t.calendar_year
                               , SUM(s.amount_sold) as current_sales
                               , LAG(SUM(s.amount_sold)) OVER (
        PARTITION BY p.prod_subcategory
        ORDER BY t.calendar_year
        )                                           as previous_sales
                          FROM sh.sales s
                                   JOIN sh.products p ON p.prod_id = s.prod_id
                                   JOIN sh.times t ON t.time_id = s.time_id
                          WHERE t.calendar_year BETWEEN 1998 AND 2001
                          GROUP BY p.prod_subcategory, t.calendar_year)
SELECT DISTINCT prod_subcategory
FROM sales_comparison
WHERE calendar_year BETWEEN 1998 AND 2001
  AND current_sales > previous_sales
GROUP BY prod_subcategory
HAVING COUNT(*) = 3 -- Must have growth in 1999 vs 1998,2000 vs 1999,2001 vs 2000
ORDER BY prod_subcategory;
--======================================================================================================================
-- Task 3. Window Frames
--======================================================================================================================

-- Create a query to generate a sales report for the years 1999 and 2000, focusing on quarters and product categories.
-- In the report you have to  analyze the sales of products from the categories 'Electronics,' 'Hardware,'
-- and 'Software/Other,' across the distribution channels 'Partners' and 'Internet'.
-- The resulting report should include the following columns:
-- CALENDAR_YEAR: The calendar year
-- CALENDAR_QUARTER_DESC: The quarter of the year
-- PROD_CATEGORY: The product category
-- SALES$: The sum of sales (amount_sold) for the product category and quarter with two decimal places
-- DIFF_PERCENT: Indicates the percentage by which sales increased or decreased compared to the
-- first quarter of the year. For the first quarter, the column value is 'N/A.' The percentage should be displayed
-- with two decimal places and include the percent sign (%) at the end.
-- CUM_SUM$: The cumulative sum of sales by quarters with two decimal places
-- The final result should be sorted in ascending order based on two criteria: first by 'calendar_year,'
-- then by 'calendar_quarter_desc'; and finally by 'sales' descending

WITH sales_base AS (SELECT t.calendar_year
                         , t.calendar_quarter_desc
                         , t.calendar_quarter_number
                         , p.prod_category
                         , SUM(s.amount_sold) AS sales
                    FROM sh.sales s
                             JOIN sh.channels ch ON ch.channel_id = s.channel_id
                             JOIN sh.products p ON p.prod_id = s.prod_id
                             JOIN sh.customers c ON c.cust_id = s.cust_id
                             JOIN sh.times t ON t.time_id = s.time_id
                    WHERE t.calendar_year IN (1999, 2000)
                      AND UPPER(p.prod_category) IN ('ELECTRONICS', 'HARDWARE', 'SOFTWARE/OTHER')
                      AND UPPER(ch.channel_desc) IN ('PARTNERS', 'INTERNET')
                    GROUP BY t.calendar_year, t.calendar_quarter_desc, p.prod_category, t.calendar_quarter_number)

SELECT calendar_year
     , calendar_quarter_desc
     , prod_category
     , ROUND(sales, 2) AS sales$
     , CASE
           WHEN calendar_quarter_number = 1 THEN 'N/A'
           ELSE ROUND(
                        (sales - FIRST_VALUE(sales) OVER (
                            PARTITION BY calendar_year, prod_category
                            ORDER BY calendar_quarter_number
                            ROWS UNBOUNDED PRECEDING
                            )) / FIRST_VALUE(sales) OVER (
                            PARTITION BY calendar_year, prod_category
                            ORDER BY calendar_quarter_number
                            ROWS UNBOUNDED PRECEDING
                            ) * 100, 2
                ) || '%'
    END                AS diff_percent
     -- Cumulative sum within each quarter
     , ROUND(SUM(sales) OVER (
    PARTITION BY calendar_year, calendar_quarter_desc -- Group by year and quarter
    ORDER BY sales DESC
    ROWS UNBOUNDED PRECEDING
    ), 2)              AS cum_sum$
FROM sales_base
ORDER BY calendar_year, calendar_quarter_desc, sales DESC;

