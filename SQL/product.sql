SELECT * from consumer360.product;

-- checking if there is any null value or empty string available
SELECT 
    SUM(CASE WHEN product_id IS NULL OR product_id = '' THEN 1 ELSE 0 END) AS null_ids,
    SUM(CASE WHEN product_name IS NULL OR product_name = '' THEN 1 ELSE 0 END) AS null_names,
    SUM(CASE WHEN category IS NULL OR category = '' THEN 1 ELSE 0 END) AS null_categories,
    SUM(CASE WHEN price IS NULL OR price = '' THEN 1 ELSE 0 END) AS null_prices
FROM consumer360.product;

-- check for any duplicate
select product_id, product_name, category, price, count(*) from consumer360.product 
group by product_id, product_name, category, price
having count(*) > 1;

-- creating a temp_table to distinct the row and calculate median number for missing value in price column
create table product_temp as select distinct * from consumer360.product; 

-- using cte calculate the median number partition by category
WITH Ranked_Prices AS (
    SELECT category, price,
           ROW_NUMBER() OVER (PARTITION BY category ORDER BY price) AS row_num,
           COUNT(*) OVER (PARTITION BY category) AS total_count
    FROM consumer360.product
    WHERE price IS NOT NULL
)
SELECT category, AVG(price) AS median_price
FROM Ranked_Prices
WHERE row_num IN (FLOOR((total_count + 1) / 2), CEIL((total_count + 1) / 2))
GROUP BY category;

-- update the median number in missing value section
update consumer360.product_temp
set price = '354.84000000000003'
where price is null or price = '';

-- delete the records from original table
truncate table consumer360.product;

-- insert temp_table records into original table
insert into consumer360.product (select * from consumer360.product_temp);

-- delete temp_table
drop table consumer360.product_temp;

-- checking datatype of columns
describe consumer360.product;

-- typecast
alter table consumer360.product
modify column product_name varchar(255);

-- typecast
alter table consumer360.product
modify column category varchar(255);

-- typecast for price column 
alter table consumer360.product
modify column price decimal(10, 2) not null;