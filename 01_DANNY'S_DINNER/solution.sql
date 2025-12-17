-- =====================================
-- Case Study #1: Danny's Diner
-- =====================================

-- Question 1
-- What is the total amount each customer spent at the restaurant?
SELECT
		customer_id
		,SUM(price) AS total_spent
FROM dannys_diner.sales AS s
INNER JOIN menu AS m
  ON s.product_id = m.product_id
GROUP BY customer_id
ORDER BY total_spent DESC
