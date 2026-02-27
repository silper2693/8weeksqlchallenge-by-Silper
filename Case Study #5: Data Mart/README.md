# 💰 Case Study #5: Data Mart
<p align="center"><img width="413" height="413" alt="image" src="https://github.com/user-attachments/assets/5a1311b7-2c1b-4554-8f92-6aa952d8b16f" /></p>
<p align="center">Introduction</p>

<p align="justify">Data Mart is Danny’s latest venture and after running international operations for his online supermarket that specialises in fresh produce - Danny is asking for your support to analyse his sales performance.</p>

<p align="justify">In June 2020 - large scale supply changes were made at Data Mart. All Data Mart products now use sustainable packaging methods in every single step from the farm all the way to the customer.</p>

<p align="justify">Danny needs your help to quantify the impact of this change on the sales performance for Data Mart and it’s separate business areas.</p>

## 📌 Table of Contents
- [💡 Business Talk](#-business-talk)
- [🔗 Entity Relationship Diagram](#-entity-relationship-diagram)
- [🧠 Question & Solution](#-question--solution)
  - [A. Data Cleansing Steps](#a-data-cleansing-steps)
  - [B. Data Exploration](#b-data-exploration)
  - [C. Before & After Analysis](#c-before--after-analysis)
  - [D. Bonus Question](#d-bonus-question)
- To find out more: Click [here](https://8weeksqlchallenge.com/case-study-5/)

## 💡 Business Talk
<p align="justify">The analysis indicates that the introduction of sustainable packaging did not result in a significant negative impact on overall sales. While minor declines were observed in certain segments and platforms, transaction volumes remained largely stable, suggesting consistent customer demand. Variations across regions and platforms imply that differences are more likely driven by implementation factors rather than the packaging change itself. Overall, the initiative appears to be strategically sound, with opportunities for further optimization at the segment level.</p>

## 🔗 Entity Relationship Diagram
<p align="center"><img width="308" height="310" alt="image" src="https://github.com/user-attachments/assets/5c906098-b9b8-43de-888a-c493d32587d3" /></p>

## 🧠 Question & Solution
You can use the embedded [DB Fiddle](https://www.db-fiddle.com/f/jmnwogTsUE8hGqkZv9H7E8/8) to easily access the example datasets and start solving the SQL questions.

## <p align="center">A. Data Cleansing Steps.</p>

In a single query, perform the following operations and generate a new table in the data_mart schema named clean_weekly_sales:
- Convert the week_date to a DATE format
- Add a week_number as the second column for each week_date value, for example any value from the 1st of January to 7th of January will be 1, 8th to 14th will be 2 etc
- Add a month_number with the calendar month for each week_date value as the 3rd column
- Add a calendar_year column as the 4th column containing either 2018, 2019 or 2020 values
- Add a new column called age_band after the original segment column using the following mapping on the number inside the segment value
<p align="center"><img width="283" height="198" alt="image" src="https://github.com/user-attachments/assets/1be1e5f7-dafa-4907-a4fd-e8880ceeb8c9" /></p>
- Add a new demographic column using the following mapping for the first letter in the segment values:
<p align="center"><img width="290" height="154" alt="image" src="https://github.com/user-attachments/assets/09293ba7-359a-4585-ab15-81367879e5ae" /></p>
- Ensure all null string values with an "unknown" string value in the original segment column as well as the new age_band and demographic columns
- Generate a new avg_transaction column as the sales value divided by transactions rounded to 2 decimal places for each record

```sql
DROP TABLE IF EXISTS clean_data;
CREATE TEMP TABLE clean_data AS 

SELECT
  TO_DATE(week_date, 'dd-mm-yy') AS week_date
  ,DATE_PART('week', TO_DATE(week_date, 'dd-mm-yy')) AS week_number
  ,DATE_PART('month', TO_DATE(week_date, 'dd-mm-yy')) AS month_number
  ,DATE_PART('year', TO_DATE(week_date, 'dd-mm-yy')) AS calendar_year
  ,region
  ,platform
  ,CASE
    WHEN segment IS NULL OR segment = 'null' THEN 'unknown'
    ELSE segment END AS segment
  ,CASE
    WHEN RIGHT(segment, 1) = '1' THEN 'Young Adults'
    WHEN RIGHT(segment, 1) = '2' THEN 'Middle Aged'
    WHEN RIGHT(segment, 1) IN ('3', '4') THEN 'Retirees'
    ELSE 'unknown'
  END AS age_band
  ,CASE
    WHEN LEFT(segment, 1) = 'C' THEN 'Couples'
    WHEN LEFT(segment, 1) = 'F' THEN 'Families'
    ELSE 'unknown'
  END AS demographic
  ,customer_type
  ,transactions
  ,sales
  ,ROUND(sales::NUMERIC / transactions::NUMERIC, 2) AS avg_transaction
FROM data_mart.weekly_sales;
```  
## <p align="center">B. Data Exploration.</p>

### 1. What day of the week is used for each week_date value?
```sql
SELECT DISTINCT(TO_CHAR(week_date, 'day')) AS week_day 
FROM clean_data;
```
Monday is used for the `week_date` value.
### 2. What range of week numbers are missing from the dataset?
```sql
SELECT week_date
  ,EXTRACT(week FROM week_date)
FROM clean_data
GROUP BY 1
ORDER BY 1;
```
Miss 1 - 12 and 37 - 52
### 3. How many total transactions were there for each year in the dataset?
```sql
SELECT
  EXTRACT(YEAR FROM week_date)
  ,SUM(transactions)
FROM clean_data
GROUP BY 1
ORDER BY 1;
```
### 4. What is the total sales for each region for each month?
```sql
SELECT
  region
  ,DATE_TRUNC('month', week_date)::DATE AS month_year
  ,SUM(sales) AS total_net_sales
FROM clean_data
GROUP BY 1, 2
ORDER BY 1, 2;
```
### 5. What is the total count of transactions for each platform
```sql
SELECT
  platform
  ,SUM(transactions)
FROM clean_data
GROUP BY 1;
```
### 6. What is the percentage of sales for Retail vs Shopify for each month?
```sql
SELECT
  calendar_year
  ,month_number
  ,platform
  ,ROUND(
    SUM(sales) * 100 / SUM(SUM(sales)) OVER(
      PARTITION BY calendar_year, month_number), 2) AS pct_sales
FROM clean_data
GROUP BY calendar_year, month_number, platform
ORDER BY calendar_year, month_number, platform;
```
OR
```sql
SELECT
  calendar_year
  ,month_number
  ,ROUND( 100.0 * SUM(
    CASE
      WHEN platform = 'Retail' THEN sales
      ELSE NULL
    END) / SUM(sales), 2) AS retail_sales
  ,ROUND( 100.0 * SUM(
    CASE
      WHEN platform = 'Shopify' THEN sales
      ELSE NULL
    END) / SUM(sales), 2) AS shopify_sales
FROM clean_data
GROUP BY calendar_year, month_number
ORDER BY calendar_year, month_number;
```
### 7. What is the percentage of sales by demographic for each year in the dataset?
```sql
SELECT
  calendar_year
  ,demographic
  ,ROUND(
    SUM(sales) *100 / SUM(SUM(sales)) OVER(
      PARTITION BY calendar_year), 2) AS pct_demog_sale
FROM clean_data
GROUP BY calendar_year, demographic
ORDER BY calendar_year, demographic;
```
### 8. Which age_band and demographic values contribute the most to Retail sales?
```sql
SELECT
  segment
  ,SUM(sales)
FROM clean_data
WHERE platform = 'Retail'
GROUP BY 1
ORDER BY 2 DESC
```
First row is 'unknown' so second row is 'F3'. Retirees and Families is top contributor
### 9. Can we use the avg_transaction column to find the average transaction size for each year for Retail vs Shopify? If not - how would you calculate it instead?

The `avg_transaction` column is not suitable for calculating yearly average transaction size because it is already a pre-aggregated metric. Taking AVG(avg_transaction) would result in an average of averages, which can distort the true value when transaction counts differ across records. Instead, the metric should be recalculated using the base measures: SUM(sales) / SUM(transactions). This approach ensures the result reflects the correct weighted average transaction value for each year and platform.

For example:
| avg_transaction | transactions |
|----------|----------|
| 10  | 100  |
| 20  | 10  |

If we simply take the average:

(10 + 20) / 2 = 15 ❌

However, the correct weighted average should consider the number of transactions:

(10 * 100 + 20 * 10) / 110 = 10.91 ✔

Therefore, the correct way to calculate the metric is:

SUM(sales) / SUM(transactions)

This ensures the result reflects the true weighted average transaction size.
```sql
SELECT 
  calendar_year
  ,platform
  ,ROUND(AVG(avg_transaction),0) AS avg_transaction_collumn
  ,SUM(sales) / sum(transactions) AS transaction_collumn
FROM clean_data
GROUP BY calendar_year, platform
ORDER BY calendar_year, platform;
```

calendar_year |	platform |	avg_transaction_collumn |	transaction_collumn
|----------|----------|----------|----------|
2018 |	Retail |	43 |	36
2018 |	Shopify |	188 |	192
2019 |	Retail |	42 |	36
2019 |	Shopify |	178 |	183
2020 |	Retail |	41 |	36

## <p align="center">C. Before & After Analysis.</p>

This technique is usually used when we inspect an important event and want to inspect the impact before and after a certain point in time.

Taking the week_date value of 2020-06-15 as the baseline week where the Data Mart sustainable packaging changes came into effect.

We would include all week_date values for 2020-06-15 as the start of the period after the change and the previous week_date values would be before

Using this analysis approach - answer the following questions:

### 1. What is the total sales for the 4 weeks before and after 2020-06-15? What is the growth or reduction rate in actual values and percentage of sales?
```sql

```
### 2. What about the entire 12 weeks before and after?
```sql

```
### 3. How do the sale metrics for these 2 periods before and after compare with the previous years in 2018 and 2019?
```sql

```

## <p align="center">D. Bonus Question.</p>

Which areas of the business have the highest negative impact in sales metrics performance in 2020 for the 12 week before and after period?
- region
- platform
- age_band
- demographic
- customer_type

Do you have any further recommendations for Danny’s team at Data Mart or any interesting insights based off this analysis?

