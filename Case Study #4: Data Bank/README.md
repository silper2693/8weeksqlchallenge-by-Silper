# 💰 Case Study #4: Data Bank
<p align="center"><img width="413" height="413" alt="image" src="https://github.com/user-attachments/assets/0b4c8a9b-7ce9-4664-923e-f2691a3d29f2" /></p>
<p align="center">Introduction</p>
<p align="justify">There is a new innovation in the financial industry called Neo-Banks: new aged digital only banks without physical branches.</p>
<p align="justify">Danny thought that there should be some sort of intersection between these new age banks, cryptocurrency and the data world…so he decides to launch a new initiative - Data Bank! Data Bank runs just like any other digital bank - but it isn’t only for banking activities, they also have the world’s most secure distributed data storage platform!</p>
<p align="justify">Customers are allocated cloud data storage limits which are directly linked to how much money they have in their accounts. There are a few interesting caveats that go with this business model, and this is where the Data Bank team need your help! The management team at Data Bank want to increase their total customer base - but also need some help tracking just how much data storage their customers will need.</p>
<p align="justify">This case study is all about calculating metrics, growth and helping the business analyse their data in a smart way to better forecast and plan for their future developments!</p>

## 📌 Table of Contents
- [💡 Business Talk](#-business-talk)
- [🔗 Entity Relationship Diagram](#-entity-relationship-diagram)
- [🧠 Question & Solution](#-question--solution)
  - [A. Customer Nodes Exploration](#a-customer-nodes-exploration)
  - [B. Customer Transactions](#b-customer-transactions)
  - [C. Data Allocation Challenge](#c-data-allocation-challenge)
  - [D. Extra Challenge](#d-extra-challenge)
- To find out more: Click [here](https://8weeksqlchallenge.com/case-study-4/)

## 💡 Business Talk
<p align="justify">By aggregating customer transactions at a monthly level, Data Bank can better understand cash flow behavior, identify high-value active customers, and proactively manage churn and liquidity risk.</p>

## 🔗 Entity Relationship Diagram
<p align="center"><img width="791" height="218" alt="image" src="https://github.com/user-attachments/assets/a6690638-bb35-4ed0-852a-3a64aafd727d" />
</p>

## 🧠 Question & Solution
You can use the embedded [DB Fiddle](https://www.db-fiddle.com/f/2GtQz4wZtuNNu7zXH5HtV4/3) to easily access the example datasets and start solving the SQL questions.

## <p align="center">A. Customer Nodes Exploration.</p>

### 1. How many unique nodes are there on the Data Bank system?
```sql
SELECT 
  COUNT(DISTINCT node_id)
FROM customer_nodes;
```
### 2. What is the number of nodes per region?
```sql
SELECT 
  r.region_name
  ,COUNT(DISTINCT cn.node_id) AS node_quantity
FROM customer_nodes AS cn
LEFT JOIN regions AS r
  ON r.region_id = cn.region_id
GROUP BY r.region_name
ORDER BY r.region_name;
```
### 3. How many customers are allocated to each region?
```sql
SELECT 
  r.region_name
  ,COUNT(DISTINCT customer_id)
FROM customer_nodes AS cn
LEFT JOIN regions AS r
  ON r.region_id = cn.region_id
GROUP BY r.region_name
ORDER BY r.region_name;
```
### 4. How many days on average are customers reallocated to a different node?
```sql
WITH CTE AS (
  SELECT
    customer_id
    ,node_id
    ,SUM(end_date - start_date) AS avd
  FROM customer_nodes AS cn
  WHERE end_date <> '9999-12-31'
  GROUP BY customer_id, node_id
)

SELECT
  ROUND(AVG(avd), 0) AS average_day_per_node
FROM CTE;
```
### 5. What is the median, 80th and 95th percentile for this same reallocation days metric for each region?
```sql
WITH CTE AS (
  SELECT
    region_name
    ,customer_id
    ,node_id
    ,start_date
    ,end_date
    ,LEAD(start_date) OVER(
      PARTITION BY customer_id
      ORDER BY end_date) - start_date AS day_trans_count
    ,LEAD(node_id) OVER(
      PARTITION BY customer_id
      ORDER BY start_date) AS next_node
  FROM customer_nodes AS cn
  LEFT JOIN regions AS r
    ON cn.region_id = r.region_id
  WHERE end_date <> '9999-12-31'
)

SELECT
  region_name
  ,ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY avg_day_trans)) AS median
  ,ROUND(PERCENTILE_CONT(0.8) WITHIN GROUP (ORDER BY avg_day_trans)) AS p80
  ,ROUND(PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY avg_day_trans)) AS p95
FROM (
  SELECT
    region_name
    ,customer_id
    ,ROUND(AVG(day_trans_count), 0) AS avg_day_trans
  FROM CTE
  WHERE node_id <> next_node
  GROUP BY region_name, customer_id
) AS x
GROUP BY region_name;
```
## <p align="center">B. Customer Transactions.</p>

### 1. What is the unique count and total amount for each transaction type?
```sql
SELECT
  txn_type
  ,COUNT(txn_type) AS quantity_transaction
  ,SUM(txn_amount) AS total_amount
FROM customer_transactions
GROUP BY txn_type
```
### 2. What is the average total historical deposit counts and amounts for all customers?
```sql
WITH CTE AS (
  SELECT
    customer_id
    ,COUNT(txn_type) AS quantity_transaction
    ,SUM(txn_amount) AS total_amount
  FROM customer_transactions
  WHERE txn_type = 'deposit'
  GROUP BY customer_id
)

SELECT
  ROUND(AVG(quantity_transaction), 1) AS avg_deposit
  ,ROUND(AVG(total_amount), 1) AS avg_amount
FROM CTE;
```
### 3. For each month - how many Data Bank customers make more than 1 deposit and either 1 purchase or 1 withdrawal in a single month?
```sql
WITH CTE AS (
  SELECT
    DATE_TRUNC('month', txn_date)::DATE AS txn_month
    ,customer_id
    ,SUM(CASE WHEN txn_type = 'deposit' THEN 1 ELSE 0 END) AS deposit
    ,SUM(CASE WHEN txn_type = 'purchase' THEN 1 ELSE 0 END) AS purchase
    ,SUM(CASE WHEN txn_type = 'withdrawal' THEN 1 ELSE 0 END) AS withdrawal
  FROM customer_transactions
  GROUP BY DATE_TRUNC('month', txn_date), customer_id
)

SELECT
  txn_month
  ,COUNT(customer_id) AS total_customer
FROM CTE
WHERE deposit > 1
  AND (purchase >= 1 OR withdrawal >= 1)
GROUP BY txn_month
ORDER BY txn_month;
```
### 4. What is the closing balance for each customer at the end of the month?
```sql
WITH CTE AS (
  SELECT
    DATE_TRUNC('month', txn_date) + INTERVAL '1 month' - INTERVAL '1 day' AS txn_month
    ,customer_id
    ,SUM(CASE
      WHEN txn_type = 'deposit' THEN txn_amount
      ELSE -txn_amount
    END) AS net_amount
  FROM customer_transactions
  GROUP BY DATE_TRUNC('month', txn_date) + INTERVAL '1 month' - INTERVAL '1 day', customer_id
)

SELECT
  txn_month::DATE
  ,customer_id
  ,SUM(net_amount) OVER(
    PARTITION BY customer_id
    ORDER BY txn_month
  ) AS closing_balance
FROM CTE
```
### 5.What is the percentage of customers who increase their closing balance by more than 5%?

Since Danny did not require the customers’ account balances to be greater than 0, my solution presents two scenarios:
- Including customers with negative balances that increase either to a positive balance or to a higher (less negative) balance
- Including only customers with positive balances, or those whose balances increase from negative to positive

From the beginning up to CTE_2, I will use the query from question 4.
```sql
WITH CTE AS (
  SELECT
    DATE_TRUNC('month', txn_date) + INTERVAL '1 month' - INTERVAL '1 day' AS txn_month
    ,customer_id
    ,SUM(CASE
      WHEN txn_type = 'deposit' THEN txn_amount
      ELSE -txn_amount
    END) AS net_amount
  FROM customer_transactions
  GROUP BY DATE_TRUNC('month', txn_date) + INTERVAL '1 month' - INTERVAL '1 day', customer_id
)

, CTE_2 AS (
SELECT
  txn_month::DATE
  ,customer_id
  ,SUM(net_amount) OVER(
    PARTITION BY customer_id
    ORDER BY txn_month
  ) AS closing_balance
FROM CTE
)
```
Question 5 start here.
1. Find the previous month’s balance.
```sql
, CTE_3 AS (
  SELECT *
    ,LAG(closing_balance) OVER(
      PARTITION BY customer_id
      ORDER BY txn_month) AS prev_closing_balance
  FROM CTE_2

)
```
2. Types of balance conditions.
```sql
, CTE_4 AS (
  SELECT *
    ,CASE
```
Both balances are positive.
```sql
      WHEN closing_balance > 0 AND prev_closing_balance > 0 THEN ROUND((closing_balance - prev_closing_balance) * 100 / prev_closing_balance, 2)
```
When the prev is negative and closing is positive, the balance has increased; however, the formula needs to include the ABS() (absolute value) function to produce the correct result.
```sql
      WHEN closing_balance > 0 AND prev_closing_balance < 0 THEN ROUND((closing_balance - prev_closing_balance) * 100 / ABS(prev_closing_balance), 2)
```
Both balances are negative, but since the previous balance is lower than the closing balance, it means the balance has increased, so it should still be counted.
```sql
      WHEN prev_closing_balance < closing_balance AND closing_balance < 0 THEN ROUND((closing_balance - prev_closing_balance) * 100 * -1 / prev_closing_balance, 2)
```
When the prev is 0 and the closing is greater than 0, the calculation will be incorrect due to a division-by-zero error. In some cases, an increase from 0 to a positive number cannot yield a percentage result, but since this represents a customer account balance, I will assume it as a 100% increase.
```sql
      WHEN prev_closing_balance = 0 AND closing_balance > 0 THEN 100
```
```sql
      ELSE NULL
    END AS percentage
  FROM CTE_3
  WHERE prev_closing_balance IS NOT NULL
)

SELECT
  COUNT(DISTINCT customer_id) * 100 / (SELECT COUNT(DISTINCT customer_id) FROM customer_transactions) AS mom_balance_growth_pct
FROM CTE_4
WHERE percentage IS NOT NULL
  AND percentage > 5
```
