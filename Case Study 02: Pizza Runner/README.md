# 🍕 Case Study 02: Pizza Runner
<p align="center"><img width="413" height="413" alt="image" src="https://github.com/user-attachments/assets/7f2d4c74-efc2-4c98-b00d-27807e45641b" /></p>
<p align="center">Introduction</p>
<p align="justify">Did you know that over 115 million kilograms of pizza is consumed daily worldwide??? (Well according to Wikipedia anyway…).</p>
<p align="justify">Danny was scrolling through his Instagram feed when something really caught his eye - “80s Retro Styling and Pizza Is The Future!”</p>
<p align="justify">Danny was sold on the idea, but he knew that pizza alone was not going to help him get seed funding to expand his new Pizza Empire - so he had one more genius idea to combine with it - he was going to Uberize it - and so Pizza Runner was launched!</p>
<p align="justify">Danny started by recruiting “runners” to deliver fresh pizza from Pizza Runner Headquarters (otherwise known as Danny’s house) and also maxed out his credit card to pay freelance developers to build a mobile app to accept orders from customers.</p>

## 📌 Table of Contents
- [💡 Business Talk](#-business-talk)
- [🔗 Entity Relationship Diagram](#-entity-relationship-diagram)
- [📊 About the Data](#-about-the-data)
  - [🔨 Table: customer_orders](#-table-customer_orders)
  - [🔨 Table: runner_orders](#-table-runner_orders)
- [🧠 Question & Solution](#-question--solution)
  - [A. Pizza Metrics](#a-pizza-metrics)
  - [B. Runner and Customer Experience](#b-runner-and-customer-experience)
  - [C. Ingredient Optimisation](#c-ingredient-optimisation)
  - [D. Pricing and Ratings](#d-pizza-metrics)
- [⭐ Bonus Question](#-bonus-question)
- To find out more: Click [here](https://8weeksqlchallenge.com/case-study-2/)

## 💡 Business Talk
<p align="justify">Pizza Runner aims to analyze order and delivery data to evaluate runner performance, delivery efficiency, and customer ordering behavior in order to improve operational efficiency and customer experience.</p>


## 🔗 Entity Relationship Diagram
<p align="center"><img width="919" height="473" alt="image" src="https://github.com/user-attachments/assets/5f0934ea-4105-4899-8444-4357a3fb2fc4" /></p>

You can also click [here](https://dbdiagram.io/d/5f3e085ccf48a141ff558487) to view the diagram.

## 📊 About the Data
<p align="justify">The data in this case study is not fully standardized and contains empty fields and inconsistent formats. To reflect real-world scenarios, I only clean the data when required by a question. This helps me build the habit of validating and cleaning data before analysis.</p>

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
ORDER BY co.customer_id;
```
### 6. What was the maximum number of pizzas delivered in a single order?
```sql
SELECT
  order_id
  ,COUNT(order_id) AS max_in_order
FROM customer_orders AS co
GROUP BY order_id
ORDER BY max_in_order DESC
LIMIT 1;
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
ORDER BY customer_id;
```
### 8. How many pizzas were delivered that had both exclusions and extras?
```sql
WITH CTE AS (
  SELECT *
	,CASE WHEN exclusions IS NULL OR exclusions IN ('', 'null') THEN NULL ELSE exclusions END AS exc
	,CASE WHEN extras IS NULL OR extras IN ('', 'null') THEN NULL ELSE extras END AS ext
  FROM runner_orders AS ro
  LEFT JOIN customer_orders AS co
    ON ro.order_id = co.order_id
  WHERE pickup_time <> 'null'
)

SELECT *
FROM CTE
WHERE exc IS NOT NULL
  AND ext IS NOT NULL;
```
### 9. What was the total volume of pizzas ordered for each hour of the day?
```sql
SELECT
  EXTRACT(hour FROM order_time) AS hour_in_day
  ,COUNT(order_id) AS volume_order
FROM customer_orders
GROUP BY hour_in_day
ORDER BY hour_in_day;
```
### 10. What was the volume of orders for each day of the week?
```sql
SELECT
  TO_CHAR(order_time, 'Dy') AS day_of_week
  ,COUNT(order_id)
FROM customer_orders
GROUP BY 1;
```
## <p align="center">B. Runner and Customer Experience.</p>
### 1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
```sql
SELECT 
  FLOOR((registration_date::DATE - DATE '2021-01-01') / 7) + 1
  ,COUNT(*) AS runner_signups
FROM runners
GROUP BY 1
ORDER BY 1;
```
### 2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
```sql
WITH CTE AS (
  SELECT *
	,CASE WHEN pickup_time = 'null' THEN NULL ELSE pickup_time::timestamp END AS pckp_tm
  FROM runner_orders AS ro
  LEFT JOIN customer_orders AS co
    ON ro.order_id = co.order_id
)

SELECT
  AVG(pckp_tm - order_time) AS average_time
FROM CTE
WHERE pckp_tm IS NOT NULL;
```
### 3. Is there any relationship between the number of pizzas and how long the order takes to prepare?
```sql
WITH CTE AS (
  SELECT
	co.order_time
	,COUNT(co.order_id) AS order_volume
	,AVG(pickup_time::TIMESTAMP - order_time) AS prep_time
  FROM customer_orders AS co
  LEFT JOIN runner_orders AS ro
    ON co.order_id = ro.order_id
  WHERE pickup_time <> 'null'
  GROUP BY co.order_time
)

SELECT
  order_volume
  ,DATE_TRUNC('MINUTE', AVG(prep_time)) AS avg_prep_per_volume
FROM CTE
GROUP BY order_volume;
```
### 4. What was the average distance travelled for each customer?
```sql
WITH CTE AS (
  SELECT
	customer_id
	,AVG(REGEXP_REPLACE(distance, '[^0-9\.]', '', 'g')::numeric) AS avg_dis
  FROM runner_orders AS ro
  LEFT JOIN customer_orders AS co
    ON co.order_id = ro.order_id
  WHERE distance <> 'null'
  GROUP BY 1
)

SELECT
  customer_id
  ,TO_CHAR(avg_dis, 'FM99.#')
FROM CTE;
```
### 5. What was the difference between the longest and shortest delivery times for all orders?
```sql
SELECT
  MAX(clean_duration) - MIN(clean_duration) AS time_diff
FROM (
  SELECT
    REGEXP_REPLACE(duration, '[^0-9\.]', '', 'g')::numeric AS clean_duration
  FROM runner_orders
  WHERE duration <> 'null'
) t;
```
### 6. What was the average speed for each runner for each delivery and do you notice any trend for these values?
```sql
SELECT
  DISTINCT(co.order_id)
  ,co.customer_id
  ,runner_id
  ,REGEXP_REPLACE(distance, '[^0-9\.]', '', 'g')::numeric AS dista
  ,REGEXP_REPLACE(duration, '[^0-9\.]', '', 'g')::numeric AS durat
  ,ROUND(REGEXP_REPLACE(distance, '[^0-9\.]', '', 'g')::numeric / (REGEXP_REPLACE(duration, '[^0-9\.]', '', 'g')::numeric / 60), 2) AS speed
FROM runner_orders AS ro
LEFT JOIN customer_orders AS co
  ON co.order_id = ro.order_id
WHERE distance <> 'null'
ORDER BY 1;
```
### 7. What is the successful delivery percentage for each runner?
```sql
SELECT
  runner_id
  ,100 * SUM(CASE WHEN distance <> 'null' THEN 1 ELSE 0 END) / COUNT (*) AS success_perc
FROM runner_orders 
GROUP BY runner_id
ORDER BY runner_id;
```
## <p align="center">C. Ingredient Optimisation.</p>
### 1. What are the standard ingredients for each pizza?
```sql
SELECT
  pn.pizza_name
  ,STRING_AGG(pt.topping_name, ', ' ORDER BY x.toppin) AS topping_name
FROM pizza_recipes AS pr
JOIN LATERAL regexp_split_to_table(toppings, ',') AS x(toppin)
  ON TRUE
LEFT JOIN pizza_toppings AS pt
  ON x.toppin::INTEGER = pt.topping_id
LEFT JOIN pizza_names AS pn
  ON pr.pizza_id = pn.pizza_id
GROUP BY pn.pizza_name, pr.toppings;
```
### 2. What was the most commonly added extra?
```sql
WITH CTE AS (
  SELECT
    x.extra_toppin
  FROM customer_orders
  JOIN LATERAL regexp_split_to_table(extras, ',') AS x(extra_toppin)
    ON TRUE
)

SELECT
  topping_name
  ,COUNT(*) AS popular
FROM CTE
LEFT JOIN pizza_toppings AS pt
  ON pt.topping_id = extra_toppin::INTEGER
WHERE extra_toppin IS NOT NULL
  AND extra_toppin NOT IN ('','null')
GROUP BY topping_name
ORDER BY popular DESC;
```
### 3. What was the most common exclusion?
Solution: Replace extra with exclusion in question 2
### 4. Generate an order item for each record in the customers_orders table in the format of one of the following:
- Meat Lovers
- Meat Lovers - Exclude Beef
- Meat Lovers - Extra Bacon
- Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers
```sql
SELECT
  co.order_id
  ,CASE
    WHEN pizza_name = 'Meatlovers' THEN '- Meat Lovers'
    WHEN pizza_name = 'Vegetarian' THEN '- Vegetarian'
  END||
  CASE
    WHEN excl IS NOT NULL THEN ' - Exclude '||excl
    ELSE ''
  END||
  CASE
    WHEN extr IS NOT NULL THEN ' - Extra '||extr
    ELSE ''
  END AS order_item
FROM customer_orders co
JOIN pizza_names pn
		ON co.pizza_id = pn.pizza_id

--Exclusion
LEFT JOIN LATERAL(
  SELECT STRING_AGG(pt.topping_name, ', ' ORDER BY pt.topping_name) AS excl
  FROM regexp_split_to_table(exclusions, ',') AS x(exc)
LEFT JOIN pizza_toppings pt
  ON x.exc::INT = pt.topping_id
WHERE exclusions NOT IN ('', 'null')
  AND exclusions IS NOT NULL
) e ON TRUE

--Extra
LEFT JOIN LATERAL(
  SELECT STRING_AGG(pt.topping_name, ', ' ORDER BY pt.topping_name ) AS extr
  FROM regexp_split_to_table(extras, ',') AS x(ext)
JOIN pizza_toppings pt
  ON x.ext::INT = pt.topping_id
WHERE extras NOT IN ('', 'null')
  AND extras IS NOT NULL
) x ON TRUE
ORDER BY 1;
```
### 5. Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table and add a 2x in front of any relevant ingredients
- For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"
```sql
--1. Standardize the data and convert empty values to NULL.
WITH CTE_1 AS (
  SELECT
    ROW_NUMBER() OVER(
      ORDER BY order_id) AS order_no
	,co.order_id
	,co.customer_id
	,pn.pizza_name
	,pr.toppings
	,NULLIF(NULLIF(exclusions, ''), 'null') AS exclusions
	,NULLIF(NULLIF(extras, ''), 'null') AS extras
	,co.order_time
  FROM customer_orders co
  LEFT JOIN pizza_names pn
	ON co.pizza_id = pn.pizza_id
  LEFT JOIN pizza_recipes pr
	ON co.pizza_id = pr.pizza_id
)

--2. Remove ingredients listed in exclusions from the recipes.
, CTE_2 AS (
  SELECT *
  FROM CTE_1 c1
  LEFT JOIN LATERAL(
    SELECT STRING_AGG(t.toppin, ', ' ORDER BY t.toppin::INT) AS toppings_not_exclude
	FROM regexp_split_to_table(c1.toppings, ',') AS t(toppin)
    WHERE t.toppin::INT NOT IN (
	  SELECT trim(x)::INT
	  FROM regexp_split_to_table(c1.exclusions, ',') AS x
	)
  ) e ON TRUE
)

--3. Add extras to toppings_not_exclude.
--3.1. Filter based on two columns.
, et_base AS (
  SELECT
	extras
	,toppings_not_exclude
	,order_no
	,order_id
	,pizza_name
  FROM CTE_2
)

--3.2. Pivot rows into columns for the toppings_not_exclude column.
, et_1 AS(
  SELECT
	order_no
	,order_id
	,pizza_name
	,(trim(x))::INT AS topping
	,'orig' AS src
  FROM et_base eb
  CROSS JOIN LATERAL regexp_split_to_table(eb.toppings_not_exclude, ',') AS x
)

--3.3. Pivot rows into columns for the extras column.
, et_2 AS(
  SELECT
	order_no
	,order_id
	,pizza_name
	,(trim(x))::INT AS topping
	,'extra' AS src
  FROM et_base eb
  CROSS JOIN LATERAL regexp_split_to_table(eb.extras, ',') AS x
  WHERE eb.extras IS NOT NULL
)

--3.4. Combine 2 columns.
, et_1_2 AS(
  SELECT * FROM et_1
  UNION ALL
  SELECT * FROM et_2
)

--4. Add 'x2' after any ingredient that appears in both columns.
--4.1. Count toppings in both columns and map topping_id to topping_name.
,et_counted AS (
  SELECT
    order_no
    ,order_id
    ,pizza_name
    ,topping
    ,topping_name
    ,COUNT(*) AS cnt
  FROM et_1_2 e12
  LEFT JOIN pizza_toppings pt
    ON e12.topping = pt.topping_id
  GROUP BY order_no, topping, topping_name, order_id, pizza_name
  ORDER BY order_no, topping
)

--4.2. Combine the topping_names into a single line with 'x2' placed before duplicates.
, et_final AS (
  SELECT
    order_no
    ,order_id
    ,pizza_name
    ,STRING_AGG(
      CASE 
        WHEN cnt = 2 THEN 'x2 ' || topping_name
        ELSE topping_name::text
      END, ', ' ORDER BY topping_name) AS final_toppings
  FROM et_counted
  GROUP BY order_no, order_id, pizza_name
  ORDER BY order_no
)

--5. Add the pizza name before the ingredients.
SELECT
  order_id
  ,CASE
	WHEN pizza_name = 'Meatlovers' THEN 'Meat Lovers: '
	WHEN pizza_name = 'Vegetarian' THEN 'Vegetarian: '
  END||final_toppings AS igredien_order_pizza
FROM et_final ef;
```
### 6. What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?
```sql
WITH CTE_1 AS (
  SELECT
    ROW_NUMBER() OVER(
	  ORDER BY co.order_id) AS order_no
    ,pr.toppings
    ,NULLIF(NULLIF(exclusions, ''), 'null') AS exclusions
    ,NULLIF(NULLIF(extras, ''), 'null') AS extras
  FROM customer_orders co
  LEFT JOIN pizza_recipes pr
    ON co.pizza_id = pr.pizza_id
)

, CTE_2 AS (
  SELECT *
  FROM CTE_1
  LEFT JOIN LATERAL(
    SELECT STRING_AGG(t.toppin, ', ' ORDER BY t.toppin::INT) AS t_n_e
    FROM regexp_split_to_table(toppings, ',') AS t(toppin)
    WHERE t.toppin::INT NOT IN(
      SELECT trim(x)::INT
      FROM regexp_split_to_table(exclusions, ',') AS x
    )
  ) e ON TRUE
)

, CTE_3 AS (
  SELECT *
    ,t_n_e||CASE
      WHEN extras IS NULL THEN ''
      WHEN extras IS NOT NULL THEN ', '||extras
      ELSE ''
    END AS t_n_e_h_x
  FROM CTE_2
)

, CTE_4 AS (
  SELECT
    order_no
    ,f.toppin
    ,topping_name
  FROM CTE_3 ct3
  LEFT JOIN LATERAL (
    SELECT regexp_split_to_table(t_n_e_h_x, ',') AS toppin
  ) f ON TRUE
  LEFT JOIN pizza_toppings pt
    ON f.toppin::INT = pt.topping_id
)

SELECT
  topping_name
  ,COUNT(*)
FROM CTE_4
GROUP BY topping_name
ORDER BY 2;
```
## <p align="center">D. Pizza Metrics.</p>
### 1. If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes - how much money has Pizza Runner made so far if there are no delivery fees?
```sql
WITH CTE AS (
  SELECT
    pizza_id
    ,CASE
      WHEN pizza_id = 1 THEN 12
      WHEN pizza_id = 2 THEN 10
      ELSE 0
    END AS price
  FROM customer_orders
)

SELECT
  pizza_id
  ,SUM(price)
FROM CTE
GROUP BY pizza_id;
```
### 2. What if there was an additional $1 charge for any pizza extras? Add cheese is $1 extra
```sql
WITH CTE AS (
  SELECT 
  	ROW_NUMBER() OVER(ORDER BY order_id) AS order_no
	,order_id
    ,pizza_id
    ,CASE
      WHEN pizza_id = 1 THEN 12
      WHEN pizza_id = 2 THEN 10
      ELSE 0
    END AS price
    ,NULLIF(NULLIF(exclusions, ''), 'null') AS exclusions
    ,NULLIF(NULLIF(extras, ''), 'null') AS extras
  FROM customer_orders
)

, CTE_2 AS (
  SELECT
    order_no
    ,pizza_id
    ,price
    ,TRIM(x.toppin) AS toppin
  FROM CTE
  LEFT JOIN LATERAL(
    SELECT regexp_split_to_table(extras,',') AS toppin) AS x ON TRUE
)

, CTE_3 AS (
  SELECT
    order_no
    ,pizza_id
    ,price
    ,COUNT(toppin) AS extras_price
  FROM CTE_2
  GROUP BY order_no, pizza_id, price
)

SELECT
  pizza_id
  ,SUM(price + extras_price) AS total_price
FROM CTE_3
GROUP BY pizza_id
ORDER BY pizza_id;
```
### 3. The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner, how would you design an additional table for this new dataset - generate a schema for this new table and insert your own data for ratings for each successful customer order between 1 to 5.
```sql
DROP TABLE IF EXISTS runner_ratings;
CREATE TABLE runner_ratings (
  "rating_id" VARCHAR(5),
  "order_id" INTEGER,
  "runner_id" INTEGER,
  "rating" VARCHAR(3),
  "rating_time" VARCHAR(19),
  "comment" VARCHAR(20)
);
INSERT INTO runner_ratings
  ("rating_id", "order_id", "runner_id", "rating", "rating_time", "comment")
VALUES
  ('r_n01', '1', '1', '4', '2020-01-01 18:50:47', 'a lil bit late'),
  ('r_n02', '2', '1', '4', '2020-01-01 19:42:28', 'just in time'),
  ('r_n03', '3', '1', '4', '2020-01-02 00:37:53', 'good delivery'),
  ('r_n04', '4', '2', '3', '2020-01-04 14:33:42', 'a lil bit late'),
  ('r_n05', '5', '3', '5', '2020-01-08 21:31:04', 'fast and friendly'),
  ('r_n06', '6', '3', 'null', 'null', NULL),
  ('r_n07', '7', '2', '4', '2020-01-08 22:04:06', 'just in time'),
  ('r_n08', '8', '2', '5', '2020-01-09 00:38:57', 'fast and friendly'),
  ('r_n09', '9', '2', '', 'null', NULL),
  ('r_n10', '10', '1', '5', '2020-01-11 19:07:29', 'perfect timing');
```
### 4. Using your newly generated table - can you join all of the information together to form a table which has the following information for successful deliveries?
- customer_id
- order_id
- runner_id
- rating
- order_time
- pickup_time
- Time between order and pickup
- Delivery duration
- Average speed
- Total number of pizzas
```sql	
SELECT
  co.customer_id
  ,ro.order_id
  ,ro.runner_id
  ,rr.rating
  ,co.order_time
  ,ro.pickup_time
  ,ro.pickup_time::TIMESTAMP - co.order_time::TIMESTAMP AS order_pickup_duration
  ,regexp_replace(ro.duration, '[^0-9\.]', '', 'g') AS duration
  ,regexp_replace(ro.distance, '[^0-9\.]', '', 'g') AS distance
  ,ROUND(regexp_replace(ro.distance, '[^0-9\.]', '', 'g')::NUMERIC / regexp_replace(ro.duration, '[^0-9\.]', '', 'g')::NUMERIC * 60, 2) AS avg_speed
  ,COUNT(*) AS total_pizza
FROM runner_orders ro
LEFT JOIN customer_orders co
  ON ro.order_id = co.order_id
LEFT JOIN runner_ratings rr
  ON rr.order_id = ro.order_id
WHERE pickup_time NOT IN ('', 'null')
GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10;
```
### 5. If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras and each runner is paid $0.30 per kilometre traveled - how much money does Pizza Runner have left over after these deliveries?
```sql
SELECT
  ,SUM(
    CASE
      WHEN pizza_id = 1 THEN 12 - (regexp_replace(ro.distance, '[^0-9\.]', '', 'g')::NUMERIC * 0.3)
      WHEN pizza_id = 2 THEN 10 - (regexp_replace(ro.distance, '[^0-9\.]', '', 'g')::NUMERIC * 0.3)
    END) AS price_after_deli
FROM runner_orders ro
LEFT JOIN customer_orders co
  ON ro.order_id = co.order_id
WHERE distance <> 'null'
GROUP BY 1;
```
## ⭐ Bonus Question
If Danny wants to expand his range of pizzas - how would this impact the existing data design? Write an INSERT statement to demonstrate what would happen if a new Supreme pizza with all the toppings was added to the Pizza Runner menu?

Solution: Danny can easily expand the menu without changing the existing schema. Adding a new pizza only requires inserting a new record into pizza_names and mapping its toppings in pizza_recipes. This demonstrates that the current data model is flexible and scalable for new products.
