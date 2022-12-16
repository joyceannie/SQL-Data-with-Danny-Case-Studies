# 🍜 Case Study #1: Danny's Diner

## Solution

View the complete syntax [here](https://github.com/joyceannie/SQL-Data-with-Danny-Case-Studies/blob/main/CASE%20STUDY1:%20Danny's%20Diner/DannysDiner.sql).

***

### 1. What is the total amount each customer spent at the restaurant?

````sql
SELECT
    s.customer_id,
    SUM(price) As price
FROM dannys_diner.sales s
JOIN dannys_diner.menu m
ON s.product_id = m.product_id
GROUP BY 1; 
````

#### Answer:
| customer_id | total_sales |
| ----------- | ----------- |
| B           | 74          |
| C           | 36          |
| A           | 76          |

- Customer A spent $76.
- Customer B spent $74.
- Customer C spent $36.

***

### 2. How many days has each customer visited the restaurant?

````sql
SELECT
    customer_id,
    COUNT(DISTINCT order_date) AS number_of_visits
FROM dannys_diner.sales s
GROUP BY 1;
````

#### Answer:
| customer_id | number_of_visits |
| ----------- | ---------------- |
| A           | 4                |
| B           | 6                |
| C           | 2                |

- Customer A visited 4 times.
- Customer B visited 6 times.
- Customer C visited 2 times.

***

### 3. What was the first item from the menu purchased by each customer?

````sql
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
````

#### Answer:
| customer_id | product_name | 
| ----------- | ------------ |
| A           | curry        | 
| A           | sushi        | 
| B           | curry        | 
| C           | ramen        |

- Customer A's first orders are curry and sushi.
- Customer B's first order is curry.
- Customer C's first order is ramen.

***

### 4. What is the most purchased item on the menu and how many times was it purchased by all customers?

````sql
WITH purchases AS(
  SELECT m.product_name,
           COUNT(*) AS purchase_count
         FROM dannys_diner.sales s
           JOIN dannys_diner.menu m
           ON s.product_id = m.product_id
           GROUP BY 1   
) 
SELECT product_name AS most_purchased_product, 
     purchase_count
       FROM purchases
       WHERE purchase_count = (
        SELECT max(purchase_count)
        FROM purchases
       );
````

#### Answer:
| most_purchased_product | purchase_count | 
| ---------------------- | -----------    |
| ramen                  | 8              |


- Most purchased item on the menu is ramen which is 8 times. Yummy!

***

### 5. Which item was the most popular for each customer?

````sql
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
````

#### Answer:
| customer_id | product_name | order_count |
| ----------- | ---------- |------------  |
| A           | ramen        |  3   |
| B           | sushi        |  2   |
| B           | curry        |  2   |
| B           | ramen        |  2   |
| C           | ramen        |  3   |

- Customer A and C's favourite item is ramen.
- Customer B enjoys all items on the menu. He/she is a true foodie, sounds like me!

***

### 6. Which item was purchased first by the customer after they became a member?

````sql
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
 SELECT customer_id, order_date, product_name
 FROM orders_rank
 WHERE rank = 1;
````


#### Answer:
| customer_id | order_date  | product_name |
| ----------- | ---------- |----------   |
| A           | 2021-01-07 | curry        |
| B           | 2021-01-11 | sushi        |

- Customer A's first order as member is curry.
- Customer B's first order as member is sushi.

***

### 7. Which item was purchased just before the customer became a member?

````sql
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
       order_date,
       product_name       
       FROM rank_before_join
       WHERE rank = 1;
````

#### Answer:
| customer_id | order_date  | product_name |
| ----------- | ---------- |----------  |
| A           | 2021-01-01 |  sushi        |
| A           | 2021-01-01 |  curry        |
| B           | 2021-01-04 |  sushi        |

- Customer A’s last order before becoming a member is sushi and curry.
- Whereas for Customer B, it's sushi. That must have been a real good sushi!

***

### 8. What is the total items and amount spent for each member before they became a member?

````sql
SELECT m.customer_id,
       COUNT(DISTINCT s.product_id) As unique_item_count,
       SUM(me.price) AS total_sales
       FROM dannys_diner.members m
       JOIN dannys_diner.sales s 
       ON m.customer_id = s.customer_id
       AND m.join_date > s.order_date
       JOIN dannys_diner.menu me
       ON s.product_id = me.product_id
       GROUP BY 1;
````


#### Answer:
| customer_id | unique_item_count | total_sales |
| ----------- | ---------- |----------  |
| A           | 2 |  25       |
| B           | 2 |  40       |

Before becoming members,
- Customer A spent $ 25 on 2 items.
- Customer B spent $40 on 2 items.

***

### 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier — how many points would each customer have?

````sql
SELECT s.customer_id, 
       SUM(CASE WHEN me.product_name = 'sushi' THEN  (me.price * 20)
            ELSE (me.price * 10) END ) AS total_points
FROM dannys_diner.sales AS s
JOIN dannys_diner.menu me
ON s.product_id = me.product_id
GROUP BY 1;
````

#### Answer:
| customer_id | total_points | 
| ----------- | ---------- |
| A           | 860 |
| B           | 940 |
| C           | 360 |

- Total points for Customer A is 860.
- Total points for Customer B is 940.
- Total points for Customer C is 360.

***

### 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi — how many points do customer A and B have at the end of January?

````sql
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
````

#### Answer:
| customer_id | price_points | 
| ----------- | ---------- |
| A           | 1370 |
| B           | 820 |

- Total points for Customer A is 1,370.
- Total points for Customer B is 820.

***

## BONUS QUESTIONS

### Join All The Things - Recreate the table with: customer_id, order_date, product_name, price, member (Y/N)

````sql
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
 ````
 
#### Answer: 
| customer_id | order_date | product_name | price | member |
| ----------- | ---------- | -------------| ----- | ------ |
| A           | 2021-01-01 | sushi        | 10    | N      |
| A           | 2021-01-01 | curry        | 15    | N      |
| A           | 2021-01-07 | curry        | 15    | Y      |
| A           | 2021-01-10 | ramen        | 12    | Y      |
| A           | 2021-01-11 | ramen        | 12    | Y      |
| A           | 2021-01-11 | ramen        | 12    | Y      |
| B           | 2021-01-01 | curry        | 15    | N      |
| B           | 2021-01-02 | curry        | 15    | N      |
| B           | 2021-01-04 | sushi        | 10    | N      |
| B           | 2021-01-11 | sushi        | 10    | Y      |
| B           | 2021-01-16 | ramen        | 12    | Y      |
| B           | 2021-02-01 | ramen        | 12    | Y      |
| C           | 2021-01-01 | ramen        | 12    | N      |
| C           | 2021-01-01 | ramen        | 12    | N      |
| C           | 2021-01-07 | ramen        | 12    | N      |

***

### Rank All The Things - Danny also requires further information about the ```ranking``` of customer products, but he purposely does not need the ranking for non-member purchases so he expects null ```ranking``` values for the records when customers are not yet part of the loyalty program.

````sql
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
````

#### Answer: 
| customer_id | order_date | product_name | price | member | ranking | 
| ----------- | ---------- | -------------| ----- | ------ |-------- |
| A           | 2021-01-01 | sushi        | 10    | N      | NULL
| A           | 2021-01-01 | curry        | 15    | N      | NULL
| A           | 2021-01-07 | curry        | 15    | Y      | 1
| A           | 2021-01-10 | ramen        | 12    | Y      | 2
| A           | 2021-01-11 | ramen        | 12    | Y      | 3
| A           | 2021-01-11 | ramen        | 12    | Y      | 3
| B           | 2021-01-01 | curry        | 15    | N      | NULL
| B           | 2021-01-02 | curry        | 15    | N      | NULL
| B           | 2021-01-04 | sushi        | 10    | N      | NULL
| B           | 2021-01-11 | sushi        | 10    | Y      | 1
| B           | 2021-01-16 | ramen        | 12    | Y      | 2
| B           | 2021-02-01 | ramen        | 12    | Y      | 3
| C           | 2021-01-01 | ramen        | 12    | N      | NULL
| C           | 2021-01-01 | ramen        | 12    | N      | NULL
| C           | 2021-01-07 | ramen        | 12    | N      | NULL


***