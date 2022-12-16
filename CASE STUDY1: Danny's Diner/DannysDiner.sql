--------------------------------
--CASE STUDY #1: DANNY'S DINER--
--------------------------------

CREATE SCHEMA dannys_diner;

CREATE TABLE sales (
  "customer_id" VARCHAR(1),
  "order_date" DATE,
  "product_id" INTEGER
);

INSERT INTO sales
  ("customer_id", "order_date", "product_id")
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
 

CREATE TABLE menu (
  "product_id" INTEGER,
  "product_name" VARCHAR(5),
  "price" INTEGER
);

INSERT INTO menu
  ("product_id", "product_name", "price")
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  

CREATE TABLE members (
  "customer_id" VARCHAR(1),
  "join_date" DATE
);

INSERT INTO members
  ("customer_id", "join_date")
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');

SELECT *
FROM dannys_diner.members;

SELECT *
FROM dannys_diner.menu;

SELECT *
FROM dannys_diner.sales;

------------------------
--CASE STUDY QUESTIONS--
------------------------

--1. What is the total amount each customer spent at the restaurant?
SELECT
    s.customer_id,
    SUM(price) As price
FROM dannys_diner.sales s
JOIN dannys_diner.menu m
ON s.product_id = m.product_id
GROUP BY 1;

--2. How many days has each customer visited the restaurant?
SELECT
    customer_id,
    COUNT(DISTINCT order_date) AS number_of_visits
FROM dannys_diner.sales s
GROUP BY 1;

--3. What was the first item from the menu purchased by each customer?
WITH ordered_sales AS(
  SELECT s.customer_id,
         RANK() OVER (PARTITION BY s.customer_id ORDER BY order_date) AS rank,
           product_name
         FROM dannys_diner.sales s
         JOIN dannys_diner.menu m
           ON s.product_id = m.product_id
) 
SELECT customer_id, product_name
FROM ordered_sales
WHERE rank = 1
GROUP BY customer_id, product_name;

--4. What is the most purchased item on the menu and how many times was it purchased by all customers?
WITH purchases AS(
  SELECT m.product_name,
           COUNT(*) AS purchase_count
         FROM dannys_diner.sales s
           JOIN dannys_diner.menu m
           ON s.product_id = m.product_id
           GROUP BY 1   
) 
SELECT product_name, 
     purchase_count
       FROM purchases
       WHERE purchase_count = (
        SELECT max(purchase_count)
        FROM purchases
       );

-- 5. Which item was the most popular for each customer?
WITH order_counts AS (
  SELECT s.customer_id,
         m.product_name,
         COUNT(*) AS order_count
         FROM dannys_diner.sales s
         JOIN dannys_diner.menu m
         ON s.product_id = m.product_id
       GROUP BY 1,2
),
order_ranks AS (
  SELECT *, RANK() OVER (PARTITION BY customer_id ORDER BY order_count DESC) AS rank
    FROM order_counts
)
SELECT customer_id, product_name, order_count FROM order_ranks
WHERE rank = 1;

-- 6. Which item was purchased first by the customer after they became a member?
WITH orders_rank AS (
  SELECT m.customer_id, 
         me.product_name,
         s.order_date,
         RANK() OVER (PARTITION BY m.customer_id ORDER BY s.order_date) AS rank
         FROM dannys_diner.members m  
         JOIN dannys_diner.sales s 
         ON m.customer_id = s.customer_id
         AND m.join_date <= s.order_date
         JOIN dannys_diner.menu me
         ON s.product_id = me.product_id
 )
 SELECT customer_id, product_name, order_date
 FROM orders_rank
 WHERE rank = 1;

-- 7. Which item was purchased just before the customer became a member?
 WITH rank_before_join AS (
  SELECT m.customer_id, 
         me.product_name, 
         s.order_date,
         RANK() OVER (PARTITION BY m.customer_id ORDER BY s.order_date DESC) AS rank 
         FROM dannys_diner.members m
         JOIN dannys_diner.sales s
         ON m.customer_id = s.customer_id
         AND m.join_date > s.order_date
         JOIN dannys_diner.menu me
         ON s.product_id = me.product_id
)
SELECT customer_id, 
       product_name, 
       order_date
       FROM rank_before_join
       WHERE rank = 1;

-- 8. What is the total items and amount spent for each member before they became a member?
SELECT m.customer_id,
       COUNT(DISTINCT s.product_id) As unique_item_count,
       SUM(me.price)
       FROM dannys_diner.members m
       JOIN dannys_diner.sales s 
       ON m.customer_id = s.customer_id
       AND m.join_date > s.order_date
       JOIN dannys_diner.menu me
       ON s.product_id = me.product_id
       GROUP BY 1;

-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
SELECT s.customer_id, 
       SUM(CASE WHEN me.product_name = 'sushi' THEN  (me.price * 20)
            ELSE (me.price * 10) END ) AS total_points
FROM dannys_diner.sales AS s
JOIN dannys_diner.menu me
ON s.product_id = me.product_id
GROUP BY 1;

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
SELECT s.customer_id,
     SUM(CASE WHEN m.join_date <= s.order_date AND s.order_date <= m.join_date + INTERVAL '6 day'
          THEN me.price * 20
            WHEN LOWER(me.product_name) = 'sushi' 
            THEN me.price * 20
            ELSE me.price * 10 END) AS price_points
            FROM dannys_diner.members m
            JOIN dannys_diner.sales s
            ON m.customer_id = s.customer_id
            JOIN dannys_diner.menu me 
            ON s.product_id = me.product_id
            WHERE (s.customer_id = 'A' OR s.customer_id = 'B') AND s.order_date <= '2021-01-31'
            GROUP BY 1;

------------------------
--BONUS QUESTIONS-------
------------------------

-- Join All The Things
-- Recreate the table with: customer_id, order_date, product_name, price, member (Y/N)

SELECT s.customer_id, 
     s.order_date,
       me.product_name, 
       me.price,
       CASE WHEN m.join_date <= s.order_date THEN 'Y' 
       ELSE 'N' END AS member
       FROM dannys_diner.sales s
       LEFT JOIN dannys_diner.menu me
       ON s.product_id = me.product_id
       LEFT JOIN dannys_diner.members m
       ON s.customer_id = m.customer_id;

-- Rank All The Things
-- Recreate the table with: customer_id, order_date, product_name, price, member (Y/N), ranking(null/123)
WITH combined_order_data AS(       
  SELECT s.customer_id, 
         s.order_date,
         me.product_name, 
         me.price,
         CASE WHEN m.join_date <= s.order_date THEN 'Y' 
         ELSE 'N' END AS member
         FROM dannys_diner.sales s
         LEFT JOIN dannys_diner.menu me
         ON s.product_id = me.product_id
         LEFT JOIN dannys_diner.members m
         ON s.customer_id = m.customer_id
 )
 SELECT *, 
      CASE WHEN member = 'N' THEN NULL
        ELSE RANK() OVER(PARTITION BY customer_id, member ORDER BY order_date) END AS ranking
        FROM combined_order_data; 

--------------------------------
--------------------------------