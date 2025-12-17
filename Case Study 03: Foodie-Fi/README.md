# 🥑 Case Study 03: Foodie-Fi
<p align="center"><img width="413" height="413" alt="image" src="https://github.com/user-attachments/assets/0430d15b-e1b3-4dcb-8467-8c119a6758a0" /></p>
<p align="center">Introduction</p>
<p align="justify">Subscription based businesses are super popular and Danny realised that there was a large gap in the market - he wanted to create a new streaming service that only had food related content - something like Netflix but with only cooking shows!</p>
<p align="justify">Danny finds a few smart friends to launch his new startup Foodie-Fi in 2020 and started selling monthly and annual subscriptions, giving their customers unlimited on-demand access to exclusive food videos from around the world!</p>
<p align="justify">Danny created Foodie-Fi with a data driven mindset and wanted to ensure all future investment decisions and new features were decided using data. This case study focuses on using subscription style digital data to answer important business questions.</p>

## 📌 Table of Contents
- [💡 Business Talk](#-business-talk)
- [🔗 Entity Relationship Diagram](#-entity-relationship-diagram)
- [🧠 Question & Solution](#-question--solution)
  - [A. Customer Journey](#a-customer-journey)
  - [B. Data Analysis Questions](#b-data-analysis-question)
  - [C. Challenge Payment Question](#c-challenge-payment-question)
  - [D. Outside The Box Questions](#d-outside-the-box-questions)
- To find out more: Click [here](https://8weeksqlchallenge.com/case-study-3/)

## 💡 Business Talk
<p align="justify">Foodie-Fi operates as a subscription-based streaming platform, where customers progress through a free trial before converting into paid monthly or annual plans. Understanding customer behaviour, churn, and revenue timing is critical for sustainable growth.</p>

## 🔗 Entity Relationship Diagram
<p align="center"><img width="548" height="166" alt="image" src="https://github.com/user-attachments/assets/805862dc-b149-479a-91ac-3f0a7737ee4e" /></p>

## 🧠 Question & Solution
You can use the embedded [DB Fiddle](https://www.db-fiddle.com/f/rHJhRrXy5hbVBNJ6F6b9gJ/16) to easily access the example datasets and start solving the SQL questions.

## <p align="center">A. Customer Journey.</p>
Based off the 8 sample customers provided in the sample from the subscriptions table, write a brief description about each customer’s onboarding journey. Try to keep it as short as possible - you may also want to run some sort of join to make your explanations a bit easier!

We will use this table. This is Table 2: subscriptions.
<p align="center"><img width="277" height="667" alt="image" src="https://github.com/user-attachments/assets/14f0d2a0-2cc0-49d2-adf4-a9d4cba5eb11" /></p>

```sql
SELECT
  customer_id
  ,'Customer ' || customer_id || ' ' || STRING_AGG(
    CASE
      WHEN plan_id = 0 THEN 'used free trial'
      WHEN plan_id = 1 THEN 'used basic monthly'
      WHEN plan_id = 2 THEN 'used pro monthly'
      WHEN plan_id = 3 THEN 'used pro annual'
      WHEN plan_id = 4 THEN 'cancelled subscription'
    END || ' at ' || start_date, ' → ' ORDER BY start_date
  ) AS customer_journey
FROM subscriptions
WHERE customer_id IN (1, 2, 11, 13, 15, 16, 18, 19)
GROUP BY customer_id
ORDER BY customer_id;
```
## <p align="center">B. Data Analysis Questions.</p>

### 1.How many customers has Foodie-Fi ever had?
```sql
SELECT
  COUNT(customer_id)
FROM subscriptions;
```
### 2. What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value
```sql
SELECT
  TO_CHAR(DATE_TRUNC('month', start_date), 'MM/YYYY') AS month
  ,COUNT(*) AS quantity_sub
FROM subscriptions
WHERE plan_id = 0
GROUP BY month;
```
### 3. What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name
```sql
SELECT
  p.plan_name
  ,COUNT(*) AS quantity_start
FROM subscriptions AS s
LEFT JOIN plans AS p
  ON s.plan_id = p.plan_id
WHERE start_date >= '2021-01-01'
GROUP BY p.plan_name
ORDER BY p.plan_name
```
### 4.What is the customer count and percentage of customers who have churned rounded to 1 decimal place?
```sql
SELECT
  s.plan_id
  ,COUNT(*) AS plant_count
  ,ROUND(COUNT(*) * 100 / SUM(COUNT(*)) OVER(), 1) AS percentage
FROM subscriptions AS s
LEFT JOIN plans AS p
  ON s.plan_id = p.plan_id
GROUP BY s.plan_id
ORDER BY s.plan_id DESC
LIMIT 1;
```
### 5. How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?
```sql
WITH CTE_1 AS (
  SELECT
    customer_id
    ,COUNT(CASE WHEN plan_id = 0 THEN 1 ELSE NULL END) AS a
    ,COUNT(CASE WHEN plan_id = 1 THEN 1 ELSE NULL END) AS b
    ,COUNT(CASE WHEN plan_id = 2 THEN 1 ELSE NULL END) AS c
    ,COUNT(CASE WHEN plan_id = 3 THEN 1 ELSE NULL END) AS d
    ,COUNT(CASE WHEN plan_id = 4 THEN 1 ELSE NULL END) AS e
  FROM subscriptions
  GROUP BY 1
  ORDER BY 1
)

SELECT
  COUNT(*)
  ,ROUND(COUNT(*) * 100.0 / (SELECT COUNT(DISTINCT customer_id) FROM subscriptions), 0)
FROM CTE_1
WHERE a = 1 AND b = 0 AND c = 0 AND d = 0 AND e = 1;
```
### 6. What is the number and percentage of customer plans after their initial free trial?
```sql
WITH CTE_1 AS (
  SELECT
    customer_id
    ,COUNT(CASE WHEN plan_id = 0 THEN 1 ELSE NULL END) AS a
    ,COUNT(CASE WHEN plan_id = 1 THEN 1 ELSE NULL END) AS b
    ,COUNT(CASE WHEN plan_id = 2 THEN 1 ELSE NULL END) AS c
    ,COUNT(CASE WHEN plan_id = 3 THEN 1 ELSE NULL END) AS d
    ,COUNT(CASE WHEN plan_id = 4 THEN 1 ELSE NULL END) AS e
  FROM subscriptions
  GROUP BY 1
  ORDER BY 1
)

, CTE_2 AS (
  SELECT *
    ,CASE
      WHEN a = 1 AND b = 1 THEN 'basic monthly'
      WHEN a = 1 AND b = 0 THEN CASE
        WHEN c = 1 THEN 'pro monthly'
        WHEN c = 0 THEN CASE
          WHEN d = 1 THEN 'pro annual'
          WHEN d = 0 THEN CASE
            WHEN e = 1 THEN 'churn'
            ELSE 'Undefined'
          END
          ELSE 'Undefined'
        END
        ELSE 'Undefined'
      END
      ELSE 'Undefined'
    END AS note
  FROM CTE_1
)

SELECT
  note
  ,COUNT(customer_id)
  ,ROUND(COUNT(customer_id) *100 / (SELECT COUNT(DISTINCT customer_id) FROM subscriptions)::NUMERIC, 1) AS percentage
FROM CTE_2
GROUP BY 1
ORDER BY 1;
```
### 7. What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?
```sql
WITH CTE_1 AS (
  SELECT 
    ROW_NUMBER() OVER(
      PARTITION BY customer_id
      ORDER BY start_date DESC) AS plan_no
    ,*
  FROM subscriptions
  WHERE start_date <= '2020-12-31'
)

SELECT
  plan_id
  ,COUNT(customer_id) AS quantity
  ,ROUND(COUNT(customer_id) * 100 / (SELECT COUNT(DISTINCT customer_id) FROM subscriptions)::NUMERIC, 1) AS percentage
FROM CTE_1
WHERE plan_no = 1
GROUP BY 1;
```
### 8. How many customers have upgraded to an annual plan in 2020?
```sql
SELECT
  COUNT(customer_id)
FROM subscriptions
WHERE plan_id = 3
  AND start_date <= '2020-12-31';
```
### 9. How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?
```sql
WITH CTE_1 AS (
  SELECT
    customer_id
    ,start_date AS trial_date
  FROM subscriptions
  WHERE plan_id = 0
)

, CTE_2 AS (
  SELECT
    customer_id
    ,start_date AS annual_date
  FROM subscriptions
  WHERE plan_id = 3
)

SELECT
  ROUND(AVG(annual_date - trial_date), 0)
FROM CTE_2 AS c2
LEFT JOIN CTE_1 AS c1
  ON c2.customer_id = c1.customer_id;
```
### 10. Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)
```sql
WITH CTE_1 AS (
  SELECT
    customer_id
    ,start_date AS trial_date
  FROM subscriptions
  WHERE plan_id = 0
)

, CTE_2 AS (
  SELECT
    customer_id
    ,start_date AS annual_date
  FROM subscriptions
  WHERE plan_id = 3
)

, CTE_3 AS (
  SELECT
    WIDTH_BUCKET(annual_date - trial_date, 0, 365, 12) AS period
  FROM CTE_2 AS c2
  LEFT JOIN CTE_1 AS c1
    ON c2.customer_id = c1.customer_id
)

SELECT
  CASE
    WHEN period = 1 THEN '0 - 30 days'
    WHEN period > 1 THEN (period - 1) * 30 + 1||' - '||period * 30||' days' 
  END AS bucket
  ,COUNT(*)
FROM CTE_3
GROUP BY period
ORDER BY period;
```
### 11. How many customers downgraded from a pro monthly to a basic monthly plan in 2020?
```sql
WITH CTE_1 AS (
  SELECT
    customer_id
    ,plan_id
    ,start_date
    ,LEAD(plan_id) OVER (
      PARTITION BY customer_id
      ORDER BY start_date) AS next_plan
  FROM subscriptions
  WHERE start_date BETWEEN '2020-01-01' AND '2020-12-31'
)

SELECT
  COUNT(DISTINCT customer_id) AS dowgrade_customer
FROM CTE_1
WHERE plan_id = 2
  AND next_plan = 1
```

## <p align="center">C. Challenge Payment Question.</p>
The Foodie-Fi team wants you to create a new payments table for the year 2020 that includes amounts paid by each customer in the subscriptions table with the following requirements:
- monthly payments always occur on the same day of month as the original start_date of any monthly paid plan upgrades from basic to monthly or pro plans are reduced by the current paid amount in that month and start immediately
- upgrades from pro monthly to pro annual are paid at the end of the current billing period and also starts at the end of the month period
- once a customer churns they will no longer make payments
Example outputs for this table might look like the following:
<p align="center"><img width="541" height="549" alt="image" src="https://github.com/user-attachments/assets/4eb6d2d8-a69f-449f-ad4d-e9748d70cfa3" />

</p>





