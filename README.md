# Second-hand Cars Sales Analysis Project

## Project Overview
This data analysis project aims to provide insights into the sales performance of the second-hand cars sales in the United State in a specific period. By analyzing various aspects of the sales data, an interactive dashboard can be made for visualizing key findings. Also, the trends can be identified and analyzed for making data-driven decisions.

## Dataset
- Downloaded from [Kaggle](https://www.kaggle.com/datasets/syedanwarafridi/vehicle-sales-data/data)
- 558837 rows, 16 columns

## Tools
- MySQL Server - Data Cleaning and Data Analysis
- Power BI - Creating dashboard

## Data Cleaning/Preparation
In the initial data preparation phase, the following tasks were performed:
1. Data loading and inspection

    The original csv file of the data was loaded using the Import Data Wizard of MySQL, changing all data type to 'text' to avoid loading data incompletely due to data type mismatch, since almost all data can be stored in 'text' format.

2. Removing duplicates
    ```sql
    with duplicate_cte as (
    	select *, row_number() over(partition by `year`, make, model, `trim`, body, transmission, vin, state, `condition`, odometer, color, interior, seller, mmr, sellingprice, saledate) row_num
    	from car_sales_copy
    )
    select * from duplicate_cte where row_num > 1;
    ```
    ```sql
    with duplicate_cte2 as (
    	select vin
    	from car_sales_copy
    	group by vin
    	having count(*) > 1
    )
    delete from car_sales_copy
    where vin in (select vin
                  from duplicate_cte2);
    ```
    No duplicates were found using the first query above. However, the 'vin' column should be unique, thus the second query above was used to remove duplicates.

3. Handling missing values

    The null values or empty string are heavily distributed in 'condition' and 'transmission', it is too difficult to fill in those fields. Also, there are unknown '—' in 'color' and 'interior'. Therefore, simple deletion was done on those rows.
   
4. Data formatting/Standardization

   - The 'state' column contains only the short form of the state name in the United State, it was converted to full name using CASE...WHEN in SQL.
   - The instances in 'seller' column are all in lowercase, the first character of each words in an instance was converted to uppercase using a modified version of custom function from [Joe Zack](https://joezack.com/2008/10/20/mysql-capitalize-function/).
   ```sql
   CREATE FUNCTION `CAP_FIRST`(input VARCHAR(255)) 
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
   ```
   Also, the extra spaces between each word in an instance were removed.
   - The 'saledate' column is split into 'weekday', 'date', 'time', 'GMT', 'USA_time_sys'.
   
## Exploratory Data Analysis (EDA)
- Basic
  - Total sales from all data
  - Total sales by year, month and weekday respectively
  - Top 4 selling models by quantity sold
  - Top 4 expensive models by average price
  - Total sales by states
  - Total cars sold and sales by seller
  - Color distribution of the cars
- Advanced
  - Price comparison between average sellingprice and average market price, subjected to mileage, condition, and manufacturing year
  - The states selling the most cars categorized by car body type
  - The sellers selling the most cars categorized by car body type
  - Overall difference between each selling price and market price of the cars

## Results/Findings
View the dashboard in [here](https://app.powerbi.com/groups/me/reports/b3644ff2-4a32-42ed-8357-852cbce65cbe/2ec90e14580ab1e644a8?experience=power-bi).

![螢幕擷取畫面 (241)](https://github.com/user-attachments/assets/af67afc6-34de-4fea-b3f3-5650db324450)

- The top 4 selling models are Nissan Altima, Ford F-150, Toyota Camry, and Ford Fusion. Ford models occupied the 2nd and 4th place, proving its reliability and convenience. Nissan and Toyota are both originated from Japan, occupying the 1st and 3rd place respectively with resonable price and reliability.
- The color of the cars sold were mostly in range of black and white, which is common.
- Florida had the most sales among all states, which is $894.38 Million.
- Other findings can be found in the dashboard.

![螢幕擷取畫面 (242)](https://github.com/user-attachments/assets/195ec8d4-8fe4-4cf7-846f-dd5429a7bb9e)

![螢幕擷取畫面 (245)](https://github.com/user-attachments/assets/2d645607-7ef8-4a2c-80e7-5b9cd8fc9e56)
- Mileage travelled and prices(average selling price and average market price) are negatively correlated, with average sellingp price slightly higher than average market price.

![螢幕擷取畫面 (246)](https://github.com/user-attachments/assets/6d1d2ea1-6be0-4ef2-90d8-9b3e97749749)
- Condition and prices are positively correlated, but there are some outliers when condition in range 0 and 5.

![螢幕擷取畫面 (247)](https://github.com/user-attachments/assets/3305e4f4-c669-43f0-8abd-bca446cf71a2)
- Manufacturing year and prices are positively correlated. Cars manufactured in 1990's had a very slightly higher price than expected, possibly due to some classic car models.

![螢幕擷取畫面 (244)](https://github.com/user-attachments/assets/f09e7807-eb76-4873-a87d-3df7d7d00d40)
