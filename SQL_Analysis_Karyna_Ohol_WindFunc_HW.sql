-- =====================================================================================================================
--     Task 1
-- Create a query to produce a sales report highlighting the top customers with the highest sales across different
-- sales channels. This report should list the top 5 customers for each channel. Additionally, calculate a
-- key performance indicator (KPI) called 'sales_percentage,' which represents the percentage of a customer's sales
-- relative to the total sales within their respective channel.
-- Please format the columns as follows:
-- Display the total sales amount with two decimal places
-- Display the sales percentage with four decimal places and include the percent sign (%) at the end
-- Display the result for each channel in descending order of sales
-- =====================================================================================================================

WITH customer_channel_sales AS (
    -- Step: Calculate total sales per customer per channel
    SELECT ch.channel_desc
         , c.cust_first_name
         , c.cust_last_name
         , SUM(s.amount_sold)                                        as total_sales_per_cust
         , SUM(SUM(s.amount_sold)) OVER (PARTITION BY ch.channel_id) as total_sales_per_channel

    FROM sh.customers c
             JOIN sh.sales s ON c.cust_id = s.cust_id
             JOIN sh.channels ch ON s.channel_id = ch.channel_id
    GROUP BY c.cust_id, ch.channel_id)

   , ranked_customers AS (
-- Step: Add ranking and percentage calculation
    SELECT channel_desc
         , cust_first_name
         , cust_last_name
         , total_sales_per_cust
         , total_sales_per_cust / total_sales_per_channel                             as sales_ratio
         , RANK() OVER (PARTITION BY channel_desc ORDER BY total_sales_per_cust DESC) as rank_of_sales_per_cust
    FROM customer_channel_sales)
-- Step: Filter top 5 and format output
SELECT channel_desc
     , cust_first_name
     , cust_last_name
     , ROUND(total_sales_per_cust::numeric, 2)     as amount_sold
     , ROUND(sales_ratio::numeric * 100, 4) || '%' as sales_percentage
FROM ranked_customers
WHERE rank_of_sales_per_cust <= 5
ORDER BY channel_desc, amount_sold DESC;
-- =====================================================================================================================
--     Task 2
-- Create a query to retrieve data for a report that displays the total sales for all products in the Photo category
-- in the Asian region for the year 2000. Calculate the overall report total and name it 'YEAR_SUM'
-- Display the sales amount with two decimal places
-- Display the result in descending order of 'YEAR_SUM'
-- For this report, consider exploring the use of the crosstab function.
-- =====================================================================================================================
CREATE EXTENSION IF NOT EXISTS tablefunc;

WITH pivoted_data AS (
    -- Apply crosstab to pivot months
    SELECT *
    FROM crosstab(
                 $$SELECT prod_name, calendar_month_desc, sales_amount
          FROM (
             SELECT p.prod_name,
           t.calendar_month_desc,
           ROUND(SUM(s.amount_sold)::numeric, 2) as sales_amount
    FROM sh.sales s
    JOIN sh.products p ON s.prod_id = p.prod_id
    JOIN sh.customers cu ON s.cust_id = cu.cust_id
    JOIN sh.countries c ON cu.country_id = c.country_id
    JOIN sh.times t ON s.time_id = t.time_id
    WHERE UPPER(p.prod_category) = 'PHOTO'
      AND UPPER(c.country_region) = 'ASIA'
      AND t.calendar_year = 2000
    GROUP BY p.prod_name, t.calendar_month_desc
    ORDER BY p.prod_name, t.calendar_month_desc

          ) sq$$,
                 $$SELECT DISTINCT calendar_month_desc
          FROM sh.times
          WHERE calendar_year = 2000
          ORDER BY calendar_month_desc$$
         ) AS ct (
                  prod_name text,
                  apr numeric, aug numeric, dec numeric,
                  feb numeric, jan numeric, jul numeric,
                  jun numeric, mar numeric, may numeric,
                  nov numeric, oct numeric, sep numeric
        ))
-- Calculate YEAR_SUM and final output
SELECT prod_name,
       COALESCE(jan, 0)                                                            as jan,
       COALESCE(feb, 0)                                                            as feb,
       COALESCE(mar, 0)                                                            as mar,
       COALESCE(apr, 0)                                                            as apr,
       COALESCE(may, 0)                                                            as may,
       COALESCE(jun, 0)                                                            as jun,
       COALESCE(jul, 0)                                                            as jul,
       COALESCE(aug, 0)                                                            as aug,
       COALESCE(sep, 0)                                                            as sep,
       COALESCE(oct, 0)                                                            as oct,
       COALESCE(nov, 0)                                                            as nov,
       COALESCE(dec, 0)                                                            as dec,
       ROUND((COALESCE(jan, 0) + COALESCE(feb, 0) + COALESCE(mar, 0) +
              COALESCE(apr, 0) + COALESCE(may, 0) + COALESCE(jun, 0) +
              COALESCE(jul, 0) + COALESCE(aug, 0) + COALESCE(sep, 0) +
              COALESCE(oct, 0) + COALESCE(nov, 0) + COALESCE(dec, 0))::numeric, 2) as YEAR_SUM
FROM pivoted_data
ORDER BY YEAR_SUM DESC;
-- =====================================================================================================================
--     Task 3
--     Create a query to generate a sales report for customers ranked in the top 300 based on total sales
--     in the years 1998, 1999, and 2001. The report should be categorized based on sales channels,
--     and separate calculations should be performed for each channel.
-- Retrieve customers who ranked among the top 300 in sales for the years 1998, 1999, and 2001
-- Categorize the customers based on their sales channels
-- Perform separate calculations for each sales channel
-- Include in the report only purchases made on the channel specified
-- Format the column so that total sales are displayed with two decimal places
-- =====================================================================================================================
--- Step 1: Calculate total sales per customer per channel per year
WITH yearly_sales AS (SELECT s.cust_id,
                             s.channel_id,
                             t.calendar_year,
                             SUM(s.amount_sold) AS yearly_sales
                      FROM sh.sales s
                               JOIN sh.times t ON s.time_id = t.time_id
                      WHERE t.calendar_year IN (1998, 1999, 2001)
                      GROUP BY s.cust_id, s.channel_id, t.calendar_year),

-- Step 2: Rank customers within each channel for each year
     yearly_ranked_customers AS (SELECT ys.cust_id,
                                        ys.channel_id,
                                        ys.calendar_year,
                                        ys.yearly_sales,
                                        RANK() OVER (
                                            PARTITION BY ys.channel_id, ys.calendar_year
                                            ORDER BY ys.yearly_sales DESC
                                            ) AS yearly_rank
                                 FROM yearly_sales ys),

-- Step 3: Find customers who ranked in top 300 for all three years
     consistent_top_customers AS (SELECT yrc.cust_id,
                                         yrc.channel_id!
                                  FROM yearly_ranked_customers yrc
                                  WHERE yrc.yearly_rank <= 300
                                  GROUP BY yrc.cust_id, yrc.channel_id
                                  HAVING COUNT(DISTINCT yrc.calendar_year) = 3 -- Must be in top 300 for all three years
     ),

-- Step 4: Calculate total sales for these customers across all three years
     total_customer_sales AS (SELECT s.cust_id,
                                     s.channel_id,
                                     SUM(s.amount_sold) AS total_sales
                              FROM sh.sales s
                                       JOIN sh.times t ON s.time_id = t.time_id
                                       JOIN consistent_top_customers ctc
                                            ON s.cust_id = ctc.cust_id AND s.channel_id = ctc.channel_id
                              WHERE t.calendar_year IN (1998, 1999, 2001)
                              GROUP BY s.cust_id, s.channel_id)

-- Final output with customer details
SELECT ch.channel_desc,
       c.cust_id,
       c.cust_last_name,
       c.cust_first_name,
       ROUND(tcs.total_sales, 2) AS total_sales
FROM total_customer_sales tcs
         JOIN sh.customers c ON tcs.cust_id = c.cust_id
         JOIN sh.channels ch ON tcs.channel_id = ch.channel_id
ORDER BY tcs.total_sales DESC, ch.channel_desc;
-- =====================================================================================================================
--     Task 4
-- Create a query to generate a sales report for January 2000, February 2000, and March 2000 specifically
-- for the Europe and Americas regions.
-- Display the result by months and by product category in alphabetical order.
-- =====================================================================================================================
SELECT t.calendar_month_desc                                                                   as calendar_month_desc,
       p.prod_category,
       ROUND(SUM(CASE
                     WHEN UPPER(co.country_region) = 'AMERICAS' THEN s.amount_sold
                     ELSE 0 END))                                                              as Americas_sales,
       ROUND(SUM(CASE WHEN UPPER(co.country_region) = 'EUROPE' THEN s.amount_sold ELSE 0 END)) as Europe_sales
FROM sales s
         JOIN times t ON s.time_id = t.time_id
         JOIN products p ON s.prod_id = p.prod_id
         JOIN customers c ON s.cust_id = c.cust_id
         JOIN countries co ON c.country_id = co.country_id
WHERE t.calendar_year = 2000
  AND t.calendar_month_number BETWEEN 1 AND 3
  AND UPPER(co.country_region) IN ('EUROPE', 'AMERICAS')
GROUP BY t.calendar_month_desc, p.prod_category
ORDER BY t.calendar_month_desc, p.prod_category;
