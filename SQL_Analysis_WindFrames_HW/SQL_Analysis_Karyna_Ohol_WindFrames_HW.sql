--======================================================================================================================
-- Task 1
--======================================================================================================================

-- Create a query for analyzing the annual sales data for the years 1999 to 2001, focusing on different sales channels
-- and regions: 'Americas,' 'Asia,' and 'Europe.'
-- The resulting report should contain the following columns:

-- AMOUNT_SOLD:
-- This column should show the total sales amount for each sales channel
-- % BY CHANNELS:
-- In this column, we should display the percentage of total sales for each channel (e.g. 100% - total
-- sales for Americas in 1999, 63.64% - percentage of sales for the channel “Direct Sales”)
-- % PREVIOUS PERIOD:
-- This column should display the same percentage values as in the '% BY CHANNELS' column but for the
-- previous year
-- % DIFF:
-- This column should show the difference between the '% BY CHANNELS' and '% PREVIOUS PERIOD' columns, indicating
-- the change in sales percentage from the previous year.
-- The final result should be sorted in ascending order based on three criteria: first by 'country_region,' then by
-- 'calendar_year,' and finally by 'channel_desc'

WITH sales_base AS (SELECT t.calendar_year,
                           cou.country_region,
                           ch.channel_desc,
                           SUM(s.amount_sold) AS amount_sold
                    FROM sh.sales s
                             JOIN sh.channels ch ON ch.channel_id = s.channel_id
                             JOIN sh.products p ON p.prod_id = s.prod_id
                             JOIN sh.customers c ON c.cust_id = s.cust_id
                             JOIN sh.times t ON t.time_id = s.time_id
                             JOIN sh.countries cou ON cou.country_id = c.country_id
                    WHERE t.calendar_year IN (1999, 2000, 2001)
                      AND cou.country_region IN ('Americas', 'Asia', 'Europe')
                    GROUP BY t.calendar_year, cou.country_region, ch.channel_desc),
     sales_with_pct AS (SELECT calendar_year,
                               country_region,
                               channel_desc,
                               amount_sold,
                               -- Calculate % BY CHANNELS
                               ROUND(amount_sold / SUM(amount_sold) OVER (
                                   PARTITION BY country_region, calendar_year
                                   ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING -- getting the total for the entire partition (region and year)
                                   ) * 100, 2) AS pct_by_channel
                        FROM sales_base)
SELECT country_region,
       calendar_year,
       channel_desc,
       amount_sold,
       pct_by_channel AS "% BY CHANNELS",
       -- Calculate % PREVIOUS PERIOD
       LAG(pct_by_channel, 1) OVER (
           PARTITION BY country_region, channel_desc
           ORDER BY calendar_year
           ROWS BETWEEN 1 PRECEDING AND 1 PRECEDING --exact previous row
           )          AS "% PREVIOUS PERIOD",
       -- Calculate % DIFF
       CASE
           WHEN calendar_year = 1999 THEN NULL --- check for the first year , there's no previous year data
           ELSE ROUND(pct_by_channel - LAG(pct_by_channel, 1) OVER (
               PARTITION BY country_region, channel_desc
               ORDER BY calendar_year
               ), 2)
           END        AS "% DIFF"
FROM sales_with_pct
ORDER BY country_region, calendar_year, channel_desc;
--======================================================================================================================
-- Task 2
--======================================================================================================================

-- You need to create a query that meets the following requirements:
-- Generate a sales report for the 49th, 50th, and 51st weeks of 1999.
-- Include a column named CUM_SUM to display the amounts accumulated during each week.
-- Include a column named CENTERED_3_DAY_AVG to show the average sales for the previous, current, and following days
-- using a centered moving average.
-- For Monday, calculate the average sales based on the weekend sales (Saturday and Sunday) as well as Monday and Tuesday.
-- For Friday, calculate the average sales on Thursday, Friday, and the weekend.
-- Ensure that your calculations are accurate for the beginning of week 49 and the end of week 51.

WITH daily_sales AS (SELECT t.calendar_week_number,
                            t.time_id,
                            t.day_name,
                            t.day_number_in_week,
                            SUM(s.amount_sold) AS amount_sold
                     FROM sh.sales s
                              JOIN sh.times t ON t.time_id = s.time_id
                     WHERE t.calendar_year = 1999
                       AND t.calendar_week_number BETWEEN 48 AND 52 -- Include  for boundaries
                     GROUP BY t.calendar_week_number, t.time_id, t.day_name, t.day_number_in_week),
     weekly_sales AS (SELECT calendar_week_number,
                             time_id,
                             day_name,
                             day_number_in_week,
                             amount_sold,
                             SUM(amount_sold) OVER (
                                 PARTITION BY calendar_week_number
                                 ORDER BY day_number_in_week
                                 ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW -- start from the first day of the current week
                                 ) AS cum_sum
                      FROM daily_sales)
SELECT calendar_week_number,
       time_id,
       day_name,
       amount_sold,
       cum_sum,
       CASE
           WHEN day_name = 'Monday' THEN
                       AVG(amount_sold) OVER (
                   ORDER BY time_id
                   RANGE BETWEEN INTERVAL '2' DAY PRECEDING AND INTERVAL '1' DAY FOLLOWING -- 4-day average (Sat + Sun + Mon + Tue)
                   )
           WHEN day_name = 'Friday' THEN
                       AVG(amount_sold) OVER (
                   ORDER BY time_id
                   RANGE BETWEEN INTERVAL '1' DAY PRECEDING AND INTERVAL '2' DAY FOLLOWING -- Thu + Fri + Sat + Sun
                   )
           ELSE
                       AVG(amount_sold) OVER (
                   ORDER BY time_id
                   RANGE BETWEEN INTERVAL '1' DAY PRECEDING AND INTERVAL '1' DAY FOLLOWING
                   )
           END AS CENTERED_3_DAY_AVG
FROM weekly_sales
WHERE calendar_week_number IN (49, 50, 51) -- Filter back to just the requested weeks
ORDER BY calendar_week_number, day_number_in_week;

--======================================================================================================================
-- Task 3
--======================================================================================================================
-- Please provide 3 instances of utilizing window functions that include a frame clause, using RANGE, ROWS,
-- and GROUPS modes.
-- Additionally, explain the reason for choosing a specific frame type for each example.
-- This can be presented as a single query or as three distinct queries.

SELECT
    t.calendar_month_number,
    SUM(amount_sold) AS monthly_sales,

    -- RANGE example: Moving average based on logical month values
    -- This creates a classic 3-month moving average (current month plus one month before and after)
    -- If any month had no sales and was missing from the result set,
    -- RANGE would still include the correct preceding/following months based on their values
    AVG(SUM(amount_sold)) OVER (
        ORDER BY t.calendar_month_number
        RANGE BETWEEN 1 PRECEDING AND 1 FOLLOWING
    ) AS range_3month_avg,

    -- ROWS example: Cumulative sum based on physical row positions
    -- For cumulative sums, we need to include exactly every previous row plus the current one
    -- We want to include every single row in the running sum, regardless of its value
    SUM(SUM(amount_sold)) OVER (
        ORDER BY t.calendar_month_number
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS rows_cumulative_sum,

    -- GROUPS example: First value from each duplicate month group
    -- GROUPS treats rows with the same values in the ORDER BY clause as a single group
    -- that's perfect for finding "top performers" within categories
   FIRST_VALUE(SUM(amount_sold)) OVER (
        PARTITION BY
            CASE
                WHEN t.calendar_month_number BETWEEN 1 AND 3 THEN 'Q1'
                WHEN t.calendar_month_number BETWEEN 4 AND 6 THEN 'Q2'
                WHEN t.calendar_month_number BETWEEN 7 AND 9 THEN 'Q3'
                WHEN t.calendar_month_number BETWEEN 10 AND 12 THEN 'Q4'
            END
        ORDER BY SUM(amount_sold) DESC
        GROUPS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) AS groups_quarterly_max

FROM
    sh.sales s
    JOIN sh.customers cust ON cust.cust_id = s.cust_id
    JOIN sh.times t ON t.time_id = s.time_id
    JOIN sh.channels ch ON ch.channel_id = s.channel_id
    JOIN sh.countries cn ON cn.country_id = cust.country_id
WHERE
    t.calendar_year = 1998
    AND ch.channel_desc = 'Tele Sales'
GROUP BY
    t.calendar_month_number
ORDER BY
    t.calendar_month_number;



