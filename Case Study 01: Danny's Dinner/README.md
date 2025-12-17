# 🍜 Case Study #1: Danny's Diner
<p align="center"><img width="413" height="413" alt="image" src="https://github.com/user-attachments/assets/d9ddbe42-190d-4c2c-8c3e-9cc63c4e9104" /></p>
<p align="center">Introduction</p>
<p align="justify">Danny seriously loves Japanese food so in the beginning of 2021, he decides to embark upon a risky venture and opens up a cute little restaurant that sells his 3 favourite foods: sushi, curry and ramen.</p>
<p align="justify">Danny’s Diner is in need of your assistance to help the restaurant stay afloat - the restaurant has captured some very basic data from their few months of operation but have no idea how to use their data to help them run the business.</p>

## 📌 Table of Contents
- [💡 Business Talk](#-business-talk)
- [🔗 Entity Relationship Diagram](#-entity-relationship-diagram)
- [🧠 Question & Solution](#-question--solution)
- To find out more: [here](https://8weeksqlchallenge.com/case-study-1/)

## 💡 Business Talk
<p align="justify">In this case study, I analyzed customer spending and visit patterns to identify high-value customers and popular menu items.</p>
<p align="justify">The insights suggest opportunities to improve loyalty programs, optimize the menu, and increase repeat visits.</p>

## 🔗 Entity Relationship Diagram
<p align="center"><img width="706" height="357" alt="image" src="https://github.com/user-attachments/assets/72565f79-fe6d-43f2-8a99-440dbb5c9cf8" /></p>

Or click [here](https://dbdiagram.io/d/608d07e4b29a09603d12edbd)

## 🧠 Question & Solution

You can use the embedded [DB Fiddle](https://www.db-fiddle.com/f/2rM8RAnq7h5LLDTzZiRWcd/138) to easily access the example datasets and start solving the SQL questions.

### <p align="center">Question</p>

### 1. What is the total amount each customer spent at the restaurant?
```sql
SELECT
  customer_id
  ,SUM(price) AS total_spent
FROM dannys_diner.sales AS s
INNER JOIN menu AS m
  ON s.product_id = m.product_id
GROUP BY customer_id
ORDER BY total_spent DESC;
```

### 2. How many days has each customer visited the restaurant?
```sql
SELECT
  customer_id
  ,COUNT(DISTINCT order_date) AS quantity_visitor
FROM sales
GROUP BY customer_id;
```
### 3. What was the first item from the menu purchased by each customer?
```sql
WITH CTE AS (
  SELECT
    s.customer_id
    ,s.order_date
    ,m.product_name
    ,RANK() OVER (
      PARTITION BY s.customer_id
      ORDER BY s.order_date) AS order_rank
    ,ROW_NUMBER() OVER (
      PARTITION BY s.customer_id
      ORDER BY s.order_date) AS order_row_num
  FROM sales AS s
  INNER JOIN menu AS m
    ON s.product_id = m.product_id
)

SELECT
  customer_id
  ,order_date
  ,product_name
FROM CTE
WHERE order_rank = 1
  AND order_row_num = 1;
```
### 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
```sql
SELECT
  m.product_id
  ,product_name
  ,COUNT(order_date) AS times
FROM sales AS s
INNER JOIN menu AS m
  ON S.product_id = M.product_id
GROUP BY m.product_id, product_name
ORDER BY times DESC
LIMIT 1;
```
### 5. Which item was the most popular for each customer?
```sql
WITH CTE AS (
  SELECT
    s.customer_id
    ,m.product_name
    ,COUNT(product_name) AS times_order
    ,DENSE_RANK() OVER(
      PARTITION BY customer_id 
      ORDER BY COUNT(product_name) DESC) AS drnk
    ,ROW_NUMBER() OVER(
      PARTITION BY customer_id
      ORDER BY COUNT(product_name) DESC) as rn
  FROM sales AS s
  LEFT JOIN menu AS m
    ON s.product_id = m.product_id
  GROUP BY s.customer_id, m.product_name
)

SELECT
  customer_id
  ,product_name
  ,times_order
FROM CTE
WHERE drnk = 1;
```
### 6. Which item was purchased first by the customer after they became a member?
```sql
WITH CTE AS (
  SELECT
    s.customer_id
    ,m.product_name
    ,order_date
    ,join_date
    ,ROW_NUMBER() OVER(
      PARTITION BY s.customer_id
      ORDER BY order_date ASC) as rn
  FROM sales AS s
  LEFT JOIN members AS e
    ON s.customer_id = e.customer_id
  LEFT JOIN menu AS m 
    ON s.product_id = m.product_id
  WHERE order_date > join_date
)

SELECT
  customer_id
  ,product_name
  ,order_date
  ,join_date
FROM CTE
WHERE rn = 1;
```
### 7. Which item was purchased just before the customer became a member?
This code may not be fully correct, but strictly following the requirement would result in only a small change from Question 6, so I included customer C to make it more interesting.
```sql
WITH CTE AS (
  SELECT
    s.customer_id
    ,M.product_name
    ,order_date
    ,join_date
    ,ROW_NUMBER() OVER(
      PARTITION BY s.customer_id
      ORDER BY order_date DESC) AS rn
  FROM sales AS s
  LEFT JOIN members AS e
    ON s.customer_id = e.customer_id
  LEFT JOIN menu as M
    ON s.product_id = m.product_id
  WHERE order_date < join_date
    OR join_date IS NULL
)
SELECT
  customer_id
  ,product_name
  ,order_date
  ,join_date
FROM CTE
WHERE rn = 1;
```
### 8. What is the total items and amount spent for each member before they became a member?
```sql
SELECT
  s.customer_id
  ,COUNT(s.product_id)
  ,SUM(price)
FROM sales AS s
LEFT JOIN members AS e
  ON s.customer_id = e.customer_id
LEFT JOIN menu AS m
  ON e.product_id = m.product_id
WHERE order_date < join_date OR join_date is NULL
GROUP BY s.customer_id
ORDER BY s.customer_id;
```
### 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
```sql
WITH CTE AS (
  SELECT
    s.customer_id
    ,m.product_name
    ,price
    ,CASE
      WHEN product_name = 'sushi' THEN price * 20
      ELSE price * 10
    END AS customer_point
  FROM sales AS s
  LEFT JOIN menu AS m
    ON s.product_id = m.product_id
)

SELECT
  customer_id
  ,SUM(customer_point) AS customer_point
FROM CTE
GROUP BY customer_id
ORDER BY customer_id
```
### 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
```sql
WITH CTE AS (
  SELECT
    s.customer_id
    ,s.order_date
    ,m.product_name
    ,m.price
    ,CASE
      WHEN s.order_date BETWEEN me.join_date AND me.join_date + INTERVAL '6 days'
        THEN m.price * 20
      WHEN s.order_date < DATE '2021-02-01' AND m.product_name = 'sushi'
        THEN m.price * 20
      WHEN s.order_date < DATE '2021-02-01'
        THEN m.price * 10
    END AS c_p
  FROM sales AS s
  LEFT JOIN menu AS m
      ON s.product_id = m.product_id
  LEFT JOIN members AS me
      ON s.customer_id = me.customer_id
)

SELECT
    customer_id
    ,SUM(c_p) AS customer_point
FROM CTE
GROUP BY customer_id
ORDER BY customer_id;
```
###<p align="center">Bonus Question</p>

### Join All The Things.
```sql
SELECT
	s.customer_id
	,s.order_date
	,m.product_name
	,m.price
	,CASE
		WHEN order_date < join_date THEN 'N'
		WHEN order_date >= join_date THEN 'Y'
		ELSE 'N'
	END AS member
FROM sales AS s
LEFT JOIN menu AS m
  ON s.product_id = m.product_id
LEFT JOIN members AS e
  ON s.customer_id = e.customer_id
ORDER BY s.customer_id, s.order_date;
```
### Rank All The Things.
```sql
WITH CTE AS (
	SELECT
		s.customer_id
		,s.order_date
		,m.product_name
		,m.price
		,CASE
			WHEN order_date < join_date THEN 'N'
			WHEN order_date >= join_date THEN 'Y'
			ELSE 'N'
		END AS member
	FROM sales AS s
	LEFT JOIN menu AS m
    ON s.product_id = m.product_id
	LEFT JOIN members AS e
    ON s.customer_id = e.customer_id
)

SELECT *
	,CASE 
		WHEN member = 'N' THEN NULL
		ELSE RANK() OVER(
      PARTITION BY customer_id, member
      ORDER BY order_date)
	END AS RANK
FROM CTE
ORDER BY 1, 2
``` 







