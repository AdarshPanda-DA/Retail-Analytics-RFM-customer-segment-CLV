select count(*) from consumer360.customer;

describe consumer360.customer;

alter table consumer360.customer
modify column signup_date date;

ALTER TABLE consumer360.customer 
MODIFY COLUMN customer_name VARCHAR(255);

-- check if there is any null or missing values in customer_table
select * from consumer360.customer
where  customer_id IS NULL
   OR customer_name IS NULL
   OR region IS NULL
   OR signup_date IS NULL;
   
   SELECT 
    SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END) AS missing_id,
    SUM(CASE WHEN customer_name IS NULL OR customer_name = '' THEN 1 ELSE 0 END) AS missing_name,
    SUM(CASE WHEN region IS NULL OR region = '' THEN 1 ELSE 0 END) AS missing_region,
    SUM(CASE WHEN signup_date IS NULL THEN 1 ELSE 0 END) AS missing_date
FROM consumer360.customer;

-- update the missing values with unknown in region column 
UPDATE consumer360.customer
SET region = 'Unknown'
WHERE region IS NULL OR region = '';

-- validate if the update is successfull
SELECT * FROM consumer360.customer where region = 'Unknown';
   
   -- check if there is any duplicate rows
select customer_id, customer_name, region, count(*) from consumer360.customer 
group by customer_id, customer_name, region
having count(*) > 1;

-- create a temp_table and distinct all row to remove duplicate and store it in the temp_table
CREATE TABLE customer_temp AS
SELECT DISTINCT * FROM consumer360.customer;

-- delete all rows from the original table
TRUNCATE TABLE consumer360.customer;

-- insert all rows from the temp_table to original table
INSERT INTO consumer360.customer SELECT * FROM customer_temp;

-- drop the temp_table 
DROP TABLE customer_temp;
