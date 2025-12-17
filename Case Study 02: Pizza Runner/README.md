# 🍕 Case Study 02: Pizza Runner
<p align="center"><img width="413" height="413" alt="image" src="https://github.com/user-attachments/assets/7f2d4c74-efc2-4c98-b00d-27807e45641b" /></p>
<p align="center">**Introduction**</p>
<p align="justify">Did you know that over 115 million kilograms of pizza is consumed daily worldwide??? (Well according to Wikipedia anyway…).</p>
<p align="justify">Danny was scrolling through his Instagram feed when something really caught his eye - “80s Retro Styling and Pizza Is The Future!”</p>
<p align="justify">Danny was sold on the idea, but he knew that pizza alone was not going to help him get seed funding to expand his new Pizza Empire - so he had one more genius idea to combine with it - he was going to Uberize it - and so Pizza Runner was launched!</p>
<p align="justify">Danny started by recruiting “runners” to deliver fresh pizza from Pizza Runner Headquarters (otherwise known as Danny’s house) and also maxed out his credit card to pay freelance developers to build a mobile app to accept orders from customers.</p>

## 📌 Table of Contents
- [💡 Business Talk](#-business-talk)
- [🔗 Entity Relationship Diagram](#-entity-relationship-diagram)
- [📊 About the Data](#-about-the-data)
  - [🔨 Table: customer_orders]()
  - [🔨 Table: runner_orders]()
- [🧠 Question & Solution](#-question--solution)
  - [A. Pizza Metrics](#a-pizza-metrics)
  - [B. Runner and Customer Experience]()
  - [C. Ingredient Optimisation]()
  - [D. Pricing and Ratings]()
- [⭐ Bonus Question](#-bonus-question)
- To find out more: Click [here](https://8weeksqlchallenge.com/case-study-1/)

## 💡 Business Talk
<p align="justify">Pizza Runner aims to analyze order and delivery data to evaluate runner performance, delivery efficiency, and customer ordering behavior in order to improve operational efficiency and customer experience.</p>


## 🔗 Entity Relationship Diagram
<p align="center"><img width="919" height="473" alt="image" src="https://github.com/user-attachments/assets/5f0934ea-4105-4899-8444-4357a3fb2fc4" /></p>

You can also click [here](https://dbdiagram.io/d/5f3e085ccf48a141ff558487) to view the diagram.

## 📊 About the Data
<p align="justify">I will clean the data only when the question requires working with columns that need cleaning. Therefore, the columns listed below contain inconsistent or incorrectly formatted data and require data cleaning.</p>

### 🔨 Table: customer_orders
Looking at the customer_orders table below, we can see that there are
- In the exclusions column, there are missing/ blank spaces ' ' and null values.
- In the extras column, there are missing/ blank spaces ' ' and null values.
<p align="center"><img width="1133" height="478" alt="image" src="https://github.com/user-attachments/assets/36d08f08-1411-4de2-88e0-b0cc2d679748" /></p>

### 🔨 Table: runner_orders
Looking at the runner_orders table below, we can see that there are
- In pickup_time column, remove nulls and replace with blank space ' '.
- In distance column, remove "km" and nulls and replace with blank space ' '.
- In duration column, remove "minutes", "minute" and nulls and replace with blank space ' '.
- In cancellation column, remove NULL and null and and replace with blank space ' '.
<p align="center"><img width="1595" height="490" alt="image" src="https://github.com/user-attachments/assets/a9e08a99-112e-4468-b3c6-9e398155760c" /></p>

## 🧠 Question & Solution

You can use the embedded [DB Fiddle](https://www.db-fiddle.com/f/7VcQKQwsS3CTkGRFG7vu98/65) to easily access the example datasets and start solving the SQL questions.

## <p align="center">A. Pizza Metrics.</p>

### 1. How many pizzas were ordered?
```sql
SELECT
	COUNT(*) AS pizza_ordered
FROM customer_orders;
```
### 2. How many unique customer orders were made?
```sql
SELECT
	COUNT(DISTINCT order_id) AS unique_pizza_ordered
FROM customer_orders;
```
### 3. How many successful orders were delivered by each runner?
```sql
SELECT
	runner_id
	,COUNT(order_id) AS complete_orders
FROM runner_orders
WHERE pickup_time <> 'null'
GROUP BY runner_id
ORDER BY runner_id;
```
### 4. How many of each type of pizza was delivered?
```sql
SELECT
	pn.pizza_name
	,COUNT(*) AS quantity
FROM customer_orders AS co
LEFT JOIN runner_orders AS ro
  ON co.order_id = ro.order_id
LEFT JOIN pizza_names AS pn
  ON co.pizza_id = pn.pizza_id
WHERE pickup_time <> 'null'
GROUP BY pn.pizza_name;
```
### 5. How many Vegetarian and Meatlovers were ordered by each customer?
```sql
SELECT
	co.customer_id
	,COUNT(CASE WHEN pizza_name = 'Meatlovers' THEN 1 END) AS meatlovers
	,COUNT(CASE WHEN pizza_name = 'Vegetarian' THEN 1 END) AS vegetarian
FROM customer_orders AS co
LEFT JOIN pizza_names AS pn
  ON co.pizza_id = pn.pizza_id
GROUP BY co.customer_id
ORDER BY co.customer_id
```
### 6. What was the maximum number of pizzas delivered in a single order?
```sql
SELECT
	order_id
	,COUNT(order_id) AS max_in_order
FROM customer_orders AS co
GROUP BY order_id
ORDER BY max_in_order DESC
LIMIT 1
```
### 7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
```sql
WITH CTE AS (
	SELECT
		customer_id
		,CASE WHEN extras IS NULL OR extras IN ('', 'null') THEN NULL ELSE extras END AS ext
		,CASE WHEN exclusions IS NULL OR exclusions IN ('', 'null') THEN NULL ELSE exclusions END AS exc
	FROM customer_orders AS co
	LEFT JOIN pizza_names AS pn
    ON co.pizza_id = pn.pizza_id
)

SELECT
	customer_id
	,SUM(CASE WHEN ext IS NULL AND exc IS NULL THEN 1 ELSE 0 END) AS none_change
	,SUM(CASE WHEN ext IS NOT NULL OR exc IS NOT NULL THEN 1 ELSE 0 END) AS some_change
FROM CTE
GROUP BY customer_id
ORDER BY customer_id
```
### 8. How many pizzas were delivered that had both exclusions and extras?
```sql
WITH CTE AS (
	SELECT *
		,CASE WHEN exclusions IS NULL OR exclusions IN ('', 'null') THEN NULL ELSE exclusions END AS exc
		,CASE WHEN extras IS NULL OR extras IN ('', 'null') THEN NULL ELSE extras END AS ext
	FROM runner_orders AS ro
	LEFT JOIN customer_orders AS co ON ro.order_id = co.order_id
	WHERE pickup_time <> 'null'
)

SELECT *
FROM CTE
WHERE exc IS NOT NULL AND ext IS NOT NULL
```
### 9. What was the total volume of pizzas ordered for each hour of the day?
```sql
SELECT
	EXTRACT(hour FROM order_time) AS hour_in_day
  ,COUNT(order_id) AS volume_order
FROM customer_orders
GROUP BY hour_in_day
ORDER BY hour_in_day
```
### 10. What was the volume of orders for each day of the week?
```sql
SELECT
  TO_CHAR(order_time, 'Dy') AS day_of_week
  ,COUNT(order_id)
FROM customer_orders
GROUP BY 1
```














