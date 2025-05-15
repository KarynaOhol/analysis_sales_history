# Sales History Database Analytics

## Overview

This repository contains SQL analytics for the Sales History database, focusing on advanced SQL window functions, frames, and complex analytical queries. The work demonstrates proficiency in sophisticated data analysis techniques using PostgreSQL.

## Database Schema

The analysis works with the following main tables in the `sh` schema:
- **`sales`** - Main transaction table
- **`customers`** - Customer information
- **`products`** - Product catalog
- **`channels`** - Sales channels
- **`countries`** - Geographic data
- **`times`** - Time dimension table

## Project Structure

```
├── SQL_Analysis_Karyna_Ohol_FinalTask.sql
├── SQL_Analysis_Karyna_Ohol_WindFrames_HW.sql
├── SQL_Analysis_Karyna_Ohol_WindFunc_HW.sql
└── README.md
```
## Technical Highlights

### Advanced SQL Techniques Used:
1. **Window Functions**
   - `ROW_NUMBER()`, `RANK()`, `DENSE_RANK()`
   - `LAG()`, `LEAD()`, `FIRST_VALUE()`, `LAST_VALUE()`
   - Aggregate functions with `OVER` clause

2. **Frame Clauses**
   - `ROWS BETWEEN`
   - `RANGE BETWEEN`
   - `GROUPS BETWEEN`
   - `UNBOUNDED PRECEDING/FOLLOWING`

3. **Common Table Expressions (CTEs)**
   - Multi-level CTEs for complex calculations
   - Recursive patterns for data analysis

4. **Advanced PostgreSQL Features**
   - `tablefunc` extension for crosstab
   - Conditional aggregation
   - Complex partitioning strategies

## Key Insights Derived

1. **Customer Segmentation**: Identified top-performing customers across different channels
2. **Product Performance**: Analyzed category-wise sales trends over time
3. **Regional Patterns**: Discovered geographic sales distribution variations
4. **Temporal Analysis**: Quarter-over-quarter and year-over-year growth patterns
5. **Channel Efficiency**: Compared performance across different sales channels

## Best Practices Demonstrated

- **Readable Code**: Well-commented SQL with clear variable names
- **Performance Optimization**: Efficient use of window functions to avoid self-joins
- **Data Quality**: Proper handling of edge cases and null values
- **Modularity**: Breaking complex queries into CTEs for clarity
- **Formatting**: Consistent indentation and structure

## Usage Instructions

1. Ensure PostgreSQL installation with `tablefunc` extension
2. Connect to the Sales History database
3. Execute queries in order, respecting dependencies
4. Results are formatted for easy interpretation with proper decimal places


*This project demonstrates advanced SQL analytics capabilities using real-world sales data, showcasing expertise in window functions, complex aggregations, and business intelligence reporting.*

## Key Features

### 1. Window Functions Analysis (`WindFunc_HW.sql`)

#### Task 1: Top Customers by Channel
- Identifies top 5 customers per sales channel
- Calculates sales percentage relative to channel total
- Demonstrates `RANK()` and percentage calculations

#### Task 2: Photo Products Sales Report (2000, Asia)
- Uses PostgreSQL's `crosstab()` function for pivot tables
- Monthly breakdown of photo product sales
- Calculates year-over-year totals

#### Task 3: Consistent Top Performers
- Finds customers ranking in top 300 across multiple years (1998, 1999, 2001)
- Cross-channel analysis
- Demonstrates complex CTE chaining

#### Task 4: Regional Sales Comparison
- Compares Americas vs Europe sales (Q1 2000)
- Month-over-month analysis by product category
- Conditional aggregation using `CASE`

### 2. Window Frames Analysis (`WindFrames_HW.sql`)

#### Task 1: Channel Performance Analysis
- Year-over-year percentage changes by region
- Uses `LAG()` for previous period comparisons
- Demonstrates frame clause with percentage calculations

#### Task 2: Weekly Sales with Moving Averages
- Analyzes weeks 49-51 of 1999
- Implements centered moving averages
- Special handling for edge cases (Monday/Friday)
- Uses `RANGE` frame for flexible date calculations

#### Task 3: Frame Types Comparison
- **RANGE**: Moving averages based on logical values
- **ROWS**: Physical row-based calculations
- **GROUPS**: Group-based window operations
- Practical examples of each frame type with explanations

### 3. Final Task Analysis (`FinalTask.sql`)

#### Task 1: Regional Analysis by Channel
- Identifies highest-selling regions per channel
- Percentage calculations with window functions
- Ranking analysis across product categories

#### Task 2: Consistent Growth Analysis
- Identifies product subcategories with year-over-year growth (1998-2001)
- Uses `LAG()` to compare with previous year
- Filters for consistent growth patterns

#### Task 3: Quarter-over-Quarter Analysis
- Sales trends for Electronics, Hardware, Software (1999-2000)
- Cumulative sums within partitions
- Percentage changes from first quarter baseline

