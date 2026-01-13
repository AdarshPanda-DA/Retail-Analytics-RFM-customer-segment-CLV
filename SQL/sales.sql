SELECT * FROM consumer360.sales;

describe consumer360.sales;

-- typecast
alter table consumer360.sales
modify column date date;

select sales_id, count(*)
from consumer360.sales
group by sales_id
having count(*) > 1;

-- creating temp_table
create table consumer360.sales_temp as 
select distinct * from consumer360.sales;

-- clear records from original table
truncate table consumer360.sales;

-- insert records into original table to temp_table
insert into consumer360.sales (select * from consumer360.sales_temp);

-- delete temp_table
drop table consumer360.sales_temp;

-- updating the sales_amount
update consumer360.sales
set sales_amount = quantity * unit_price;

alter table consumer360.sales
modify column sales_amount decimal(10, 2) not null;

--  Add column is_return for Handle returns and negative values
ALTER TABLE consumer360.sales
ADD COLUMN is_return BOOLEAN DEFAULT 0;

-- handles negative values
update consumer360.sales
set is_return = 1
where quantity < 0 or sales_amount < 0;

-- checking if is_return returns 1
select sales_id, customer_id, quantity, sales_amount, is_return from consumer360.sales
where is_return = 1;

-- normalise the row
UPDATE sales
SET quantity = ABS(quantity),
    sales_amount = ABS(sales_amount)
WHERE is_return = 1;

-- drop column is-return 
alter table consumer360.sales
drop column is_return;

select * from consumer360.sales order by date asc;

ALTER TABLE `consumer360`.`sales` 
ADD INDEX `product_id_idx` (`product_id` ASC) VISIBLE;
;

ALTER TABLE `consumer360`.`sales` 
ADD CONSTRAINT `product_id`
  FOREIGN KEY (`product_id`)
  REFERENCES `consumer360`.`product` (`product_id`)
  ON DELETE NO ACTION
  ON UPDATE NO ACTION;

ALTER TABLE consumer360.sales
ADD CONSTRAINT date
FOREIGN KEY (date) 
REFERENCES dates(date);

-- checking execution time < 2 sec
select 
	customer_id,
    SUM(sales_amount) AS total_spend,
    COUNT(sales_id) AS transaction_count,
    MAX(date) AS last_purchase_date
FROM consumer360.sales
GROUP BY customer_id;

CREATE VIEW single_customer_view AS
WITH base_sales AS (
    -- Join fact and dimension tables
    SELECT
        s.sales_id,
        s.customer_id,
        c.customer_name,
        c.region,
        d.date AS order_date,
        s.quantity,
        s.sales_amount
    FROM consumer360.sales s
    JOIN customer c
        ON s.customer_id = c.customer_id
    JOIN dates d
        ON s.date = d.date
),

customer_aggregates AS (
    -- Aggregations by customer
    SELECT
        customer_id,
        customer_name,
        region,
        COUNT(DISTINCT sales_id) AS total_orders,
        SUM(quantity) AS total_quantity,
        SUM(sales_amount) AS total_sales,
        AVG(sales_amount) AS avg_order_value,
        MIN(order_date) AS first_purchase_date,
        MAX(order_date) AS last_purchase_date
    FROM base_sales
    GROUP BY
        customer_id,
        customer_name,
        region
),

customer_order_analysis AS (
    -- Window functions: RANK, LAG, LEAD
    SELECT
        customer_id,
        order_date,
        sales_amount,

        RANK() OVER (
            PARTITION BY customer_id
            ORDER BY sales_amount DESC
        ) AS sales_rank,

        LAG(order_date) OVER (
            PARTITION BY customer_id
            ORDER BY order_date
        ) AS previous_order_date,

        LEAD(order_date) OVER (
            PARTITION BY customer_id
            ORDER BY order_date
        ) AS next_order_date
    FROM base_sales
),

customer_purchase_gaps AS (
    -- Calculate days between purchases
    SELECT
        customer_id,
        AVG(order_date - previous_order_date) AS avg_days_between_orders
    FROM customer_order_analysis
    WHERE previous_order_date IS NOT NULL
    GROUP BY customer_id
)

-- Final Single Customer View
SELECT
    ca.customer_id,
    ca.customer_name,
    ca.region,
    ca.total_orders,
    ca.total_quantity,
    ca.total_sales,
    ca.avg_order_value,
    ca.first_purchase_date,
    ca.last_purchase_date,
    COALESCE(pg.avg_days_between_orders, 0) AS avg_days_between_orders
FROM customer_aggregates ca
LEFT JOIN customer_purchase_gaps pg
    ON ca.customer_id = pg.customer_id;

select * from consumer360.single_customer_view;
describe single_customer_view;

