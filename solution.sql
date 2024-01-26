-- Provide the list of markets in which customer "Atliq Exclusive" operates its business in the APAC region.

select 
		 distinct market
from dim_customer
where customer = "Atliq Exclusive" and
	region = "APAC"
order by market asc;

-- What is the percentage of unique product increase in 2021 vs. 2020? The
-- final output contains these fields,
-- unique_products_2020
-- unique_products_2021
-- percentage_chg

with cte1 as
(select
		count(distinct product_code) as unique_products_2020
from fact_sales_monthly
where fiscal_year = 2020
),
cte2 as
(
select
		count(distinct product_code) as unique_products_2021
from fact_sales_monthly
where fiscal_year = 2021
)
select  *,
		(unique_products_2021-unique_products_2020)*100/unique_products_2020 as percentage_chg
from cte1,cte2;

-- Provide a report with all the unique product counts for each segment and
-- sort them in descending order of product counts. The final output contains
-- 2 fields,
-- segment
-- product_count

select
		segment,
        count(distinct product_code) as product_count
from dim_product
group by segment
order by product_count desc;

-- Follow-up: Which segment had the most increase in unique products in
-- 2021 vs 2020? The final output contains these fields,
-- segment
-- product_count_2020
-- product_count_2021
-- difference
with 
cte1 as
(select 
      p.segment as col1,
     count(distinct product_code) as col2
from dim_product p
join fact_sales_monthly f
using(product_code)
where fiscal_year = 2020
group by p.segment
order by col2
),
cte2 as
(
select 
       p.segment as col3 ,
       count(distinct product_code) as col4
from dim_product p
join fact_sales_monthly f
using(product_code)
where fiscal_year = 2021
group by p.segment
order by col4
)
select
		col1 as segment,
        col2 as product_count_2020,
        col4 as product_count_2021,
        (col4-col2) as difference
from cte1,cte2
where col1 = col3
order by difference desc;

-- Get the products that have the highest and lowest manufacturing costs.
-- The final output should contain these fields,
-- product_code
-- product
-- manufacturing_cost

select
		p.product_code,
        p.product,
        m.manufacturing_cost
from dim_product p
join fact_manufacturing_cost m
using (product_code)
where m.manufacturing_cost in(
(select max(manufacturing_cost) from fact_manufacturing_cost),
(select min(manufacturing_cost) from fact_manufacturing_cost))
order by m.manufacturing_cost desc;

-- Generate a report which contains the top 5 customers who received an
-- average high pre_invoice_discount_pct for the fiscal year 2021 and in the
-- Indian market. The final output contains these fields,
-- customer_code
-- customer
-- average_discount_percentage

select  c.customer_code,
		c.customer,
        round(avg(pre_invoice_discount_pct)*100,2) as average_discount_percentage
from fact_pre_invoice_deductions d
join dim_customer c
using(customer_code)
where fiscal_year =2021 and
market = "India" and (select avg(pre_invoice_discount_pct)  from fact_pre_invoice_deductions)
group by c.customer_code
order by average_discount_percentage desc
limit 5;

-- Get the complete report of the Gross sales amount for the customer “Atliq
-- Exclusive” for each month. This analysis helps to get an idea of low and
-- high-performing months and take strategic decisions.
-- The final report contains these columns:
-- Month
-- Year
-- Gross sales Amount

select
		month(s.date) as Month,
        year(s.date) as Year,
        sum((s.sold_quantity * g.gross_price)) as Gross_Sales_Amount
from fact_Sales_monthly s
join fact_gross_price g
using(product_code,fiscal_year)
join dim_customer c
using(customer_code)
where c.customer = "Atliq Exclusive"
group by month,year
order by year,month;

 -- In which quarter of 2020, got the maximum total_sold_quantity? The final
-- output contains these fields sorted by the total_sold_quantity,
-- Quarter
-- total_sold_quantity

select
		case
        when month(s.date) in(9,10,11) then "Q1"
        when month(s.date) in(12,1,2) then "Q2"
        when month(s.date) in(3,4,5) then "Q3"
        else "Q4"
        end as qtr,
        sum(sold_quantity) as tottal_sold_quantity
from fact_sales_monthly s
where fiscal_year = 2020
group by qtr;

-- Which channel helped to bring more gross sales in the fiscal year 2021
-- and the percentage of contribution? The final output contains these fields,
-- channel
-- gross_sales_mln
-- percentag

with cte1 as
(
select 
		c.channel,
        round(sum((s.sold_quantity*g.gross_price)/1000000),2) as gross_sales_mln
from dim_customer c
join fact_sales_monthly s
using(customer_code)
join fact_gross_price g
using(product_code)
where s.fiscal_year = 2021
group by c.channel
)
select 
		*,
		round(gross_sales_mln*100/sum(gross_sales_mln) over(),2) as percentage
from cte1;

-- Get the Top 3 products in each division that have a high
-- total_sold_quantity in the fiscal_year 2021? The final output contains these
-- fields,
-- division
-- product_code
-- product
-- total_sold_quantity
-- rank_order
with cte1 as
(
select 
		p.division,
        p.product_code,
        p.product,
        sum(s.sold_quantity) as total_sold_quantity
from dim_product p
join fact_sales_monthly s
using(product_code)
where s.fiscal_year = 2021
group by p.product_code, p.division,p.product
),
cte2 as
(
select *,
		dense_rank() over(partition by division order by total_sold_quantity desc) as rank_order
from cte1
)
select *
from cte2
where rank_order <=3