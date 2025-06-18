# https://www.kaggle.com/datasets/syedanwarafridi/vehicle-sales-data/data
# year: The manufacturing year of the vehicle
# make: The brand or manufacturer of the vehicle
# model: The specific model of the vehicle
# trim: additional designation for the vehicle model
# body: The body type of the vehicle (e.g., SUV, Sedan)
# transmission: The type of transmission in the vehicle (e.g., automatic)
# vin:　Vehicle Identification Number, a unique code for each vehicle
# state: The state where the vehicle is registered
# condition: Condition of the vehicle, rated on a scale (0-50)
# odometer: The mileage or distance traveled by the vehicle
# color: Exterior color of the vehicle
# interior: Interior color of the vehicle
# seller: The entity selling the vehicle
# mmr: Manheim Market Report, possibly indicating the estimated market value of the vehicle
# sellingprice: The price at which the vehicle was sold
# saledate: The date and time when the vehicle was sold
select * from car_sales limit 100;
select count(*) from car_sales;

# Data Cleaning
create table car_sales_copy like car_sales;
insert into car_sales_copy select * from car_sales;

# 1. Remove duplicates
with duplicate_cte as (
	select *, row_number() over(partition by `year`, make, model, `trim`, body, transmission, vin, state, `condition`, odometer, color, interior, seller, mmr, sellingprice, saledate) row_num
	from car_sales_copy
)
select * from duplicate_cte where row_num > 1; # seems no duplicates?

with duplicate_cte2 as (
	select vin
	from car_sales_copy
	group by vin
	having count(*) > 1
)
# 8328 duplicated vin, remove all duplicated vin cases since vin should be unique
delete from car_sales_copy
where vin in (select vin 
			  from duplicate_cte2);

# 2. Handling missing values
delete from car_sales_copy
where `year` = '' or make = '' or model = '' or `trim` = '' or body = '' 
	or transmission = '' or vin = '' or state = '' or `condition` = '' 
	or odometer = '' or color = '' or interior = '' or seller = '' or mmr = '' 
	or sellingprice = '' or saledate = '';

delete from car_sales_copy where color = '—' or interior = '—';

# 3. Standardization
select distinct `year` from car_sales_copy;
select distinct make, model, `trim` from car_sales_copy order by make, model, `trim`;
select distinct body from car_sales_copy;
select distinct transmission from car_sales_copy;
select distinct state from car_sales_copy order by state; # need full state name
select distinct `condition` from car_sales_copy;
select distinct odometer from car_sales_copy;
select distinct color from car_sales_copy; # remove unknown '—' instances
select distinct interior from car_sales_copy; # remove unknown '—' instances
select distinct seller from car_sales_copy; # convert first letter of each word to uppercase
select distinct mmr from car_sales_copy;
select distinct sellingprice from car_sales_copy;
select distinct saledate from car_sales_copy;

alter table car_sales_copy add column std_state varchar(30);
update car_sales_copy set std_state = 
(case
	when state = 'al' then 'Alabama'
    when state = 'az' then 'Arizona'
    when state = 'ca' then 'California'
    when state = 'co' then 'Colorado'
    when state = 'fl' then 'Florida'
    when state = 'ga' then 'Georgia'
    when state = 'hi' then 'Hawaii'
    when state = 'il' then 'Illinois'
    when state = 'in' then 'Indiana'
    when state = 'la' then 'Louisiana'
    when state = 'ma' then 'Massachusetts'
    when state = 'md' then 'Maryland'
    when state = 'mi' then 'Michigan'
    when state = 'mn' then 'Minnesota'
    when state = 'mo' then 'Missouri'
    when state = 'ms' then 'Mississippi'
    when state = 'nc' then 'North Carolina'
    when state = 'ne' then 'Nebraska'
    when state = 'nj' then 'New Jersey'
    when state = 'nm' then 'New Mexico'
    when state = 'nv' then 'Nevada'
    when state = 'ny' then 'New York'
    when state = 'oh' then 'Ohio'
    when state = 'ok' then 'Oklahoma'
    when state = 'or' then 'Oregon'
    when state = 'pa' then 'Pennsylvania'
    when state = 'pr' then 'Puerto Rico'
    when state = 'sc' then 'South Carolina'
    when state = 'tn' then 'Tennessee'
    when state = 'tx' then 'Texas'
    when state = 'ut' then 'Utah'
    when state = 'va' then 'Virginia'
    when state = 'wa' then 'Washington'
    when state = 'wi' then 'Wisconsin'
end);
alter table car_sales_copy drop column state;

# function of converting first letter of each word to uppercase
/* CREATE FUNCTION `CAP_FIRST`(input VARCHAR(255)) 
	RETURNS varchar(255)
    DETERMINISTIC
BEGIN
    DECLARE len INT;
    DECLARE i INT;

    SET len = CHAR_LENGTH(input);
    SET input = LOWER(input);
    SET i = 0;

    WHILE (i < len) DO
        IF (MID(input, i, 1) = ' ' OR MID(input, i, 1) = '/' OR MID(input, i, 1) = '(' OR i = 0) THEN
            IF (i < len) THEN
                SET input = CONCAT(
                    LEFT(input,i),
                    UPPER(MID(input, i+1, 1)),
                    RIGHT(input, len-i-1)
                );
            END IF;
        END IF;
        SET i = i + 1;
    END WHILE;

    RETURN input;
END
*/
update car_sales_copy set seller = CAP_FIRST(seller);

update car_sales_copy set seller = 
REPLACE(
	REPLACE(
		REPLACE(seller, ' ', '<>'), 
	'><',''),
'<>',' '); # remove extra spaces between words

update car_sales_copy set seller = replace(seller, 'Tra', 'TRA');

# split datetime
select saledate, substring(saledate, 1, 3) `weekday`, str_to_date(substring(saledate, 5, 11), '%M %d %Y') `date`, substring(saledate, 17, 8) `time`, substring(saledate, 26, 8) GMT, substring(saledate, 36, 3) USA_time_sys
from car_sales_copy;
alter table car_sales_copy 
	add column `weekday` varchar(10),
	add column `date` date,
    add column `time` time,
    add column GMT varchar(10),
    add column USA_time_sys varchar(3);
update car_sales_copy set `weekday` = substring(saledate, 1, 3);
update car_sales_copy set `date` = str_to_date(substring(saledate, 5, 11), '%M %d %Y');
update car_sales_copy set `time` = substring(saledate, 17, 8);
update car_sales_copy set GMT = substring(saledate, 26, 8);
update car_sales_copy set USA_time_sys = substring(saledate, 36, 3);

# Finished cleaning
CREATE TABLE `car_sales_cleaned` (
  `vin` varchar(30) DEFAULT NULL,
  `year` varchar(4) DEFAULT NULL,
  `make` varchar(30) DEFAULT NULL,
  `model` varchar(40) DEFAULT NULL,
  `trim` varchar(60) DEFAULT NULL,
  `body` varchar(40) DEFAULT NULL,
  `transmission` varchar(10) DEFAULT NULL,
  `condition` int DEFAULT NULL,
  `odometer` int DEFAULT NULL,
  `color` varchar(15) DEFAULT NULL,
  `interior` varchar(15) DEFAULT NULL,
  `seller` varchar(100) DEFAULT NULL, 
  `state` varchar(30) DEFAULT NULL,
  `mmr` int DEFAULT NULL,
  `sellingprice` int DEFAULT NULL,
  `saledate` text,
  `weekday` varchar(10) DEFAULT NULL,
  `date` date DEFAULT NULL,
  `time` time DEFAULT NULL,
  `GMT` varchar(10) DEFAULT NULL,
  `USA_time_sys` varchar(3) DEFAULT NULL,
  UNIQUE KEY `vin` (`vin`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
insert into car_sales_cleaned 
select vin, `year`, make,  model, `trim`, body, transmission, `condition`, odometer, color, interior, seller, std_state,  mmr, sellingprice, saledate, `weekday`, `date`, `time`, GMT, USA_time_sys from car_sales_copy;

update car_sales_cleaned set seller = 'Nissan Infiniti Lt' where seller = 'Nissan-infiniti Lt';

# Data Analysis

# year total sales
select substring(`date`, 1, 4) `year`, sum(sellingprice) year_sales
from car_sales_cleaned
group by substring(`date`, 1, 4);

# month total sales
select substring(`date`, 1, 4) `year`, substring(`date`, 6, 2) `month`, sum(sellingprice) month_sales
from car_sales_cleaned
group by substring(`date`, 1, 4), substring(`date`, 6, 2)
order by `year`, `month`;

# weekday total sales
select `weekday`, sum(sellingprice) day_sales
from car_sales_cleaned
group by `weekday`;

# most expensive models
select make brand, model, sellingprice
from car_sales_cleaned
order by sellingprice desc;

# quantity sold by brand model
select concat(make, ' ', model) brand_model, transmission, count(*) quantity_sold
from car_sales_cleaned
group by make, model, transmission
order by count(*) desc;

# sales and price by brand model
select concat(make, ' ', model) brand_model, transmission, sum(sellingprice) brand_model_sales, round(avg(sellingprice), 2) avg_price
from car_sales_cleaned
group by make, model, transmission
order by avg_price desc;

# sales and quantity sold by state
select state, count(*) quantity_sold, sum(sellingprice) state_sales
from car_sales_cleaned
group by state
order by state_sales desc;

# sales and quantity sold by seller
select seller, count(*) quantity_sold, sum(sellingprice) seller_sales
from car_sales_cleaned
group by seller
order by seller_sales desc;

# most sales color
select color, sum(sellingprice) sales
from car_sales_cleaned
group by color
order by sales desc;

# difference between mmr and sellingprice based on condition and mileage of the car
select mmr, sellingprice, `condition`, odometer, concat(((sellingprice-mmr)/mmr)*100, '%') price_change
from car_sales_cleaned
order by `condition`, odometer;

#  top 1 seller from each body
with top_1_seller as (
	select seller, body, count(body) qty_body, row_number() over(partition by body order by count(*) desc) `rank`
	from car_sales_cleaned
	group by seller, body
    order by count(body) desc
)
select seller, body, qty_body
from top_1_seller
where `rank` = 1;

# top 1 state from each body
with top_1_state as (
	select state, body, count(body) qty_body, row_number() over(partition by body order by count(*) desc) `rank`
	from car_sales_cleaned
	group by state, body
    order by count(body) desc
)
select state, body, qty_body
from top_1_state
where `rank` = 1;