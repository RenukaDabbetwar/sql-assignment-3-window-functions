use mavenmovies;
-- Q.1 Rank the customers based on the total amount they've spent on rentals.
with customer_rank as (
select customer_id, sum(amount) as total_amt, dense_rank() over (order by sum(amount) desc) as rank_
from payment group by customer_id)
select customer_id, total_amt, rank_ from customer_rank;
    
-- Q.2 Calculate the cumulative revenue generated by each film over time.
select * from film; -- film_id, title
select * from payment; -- rental_id
select * from inventory; -- film_id
select * from rental; -- inventory_id

select f.film_id,f.title,p.payment_date, sum(p.amount)
over(partition by f.film_id order by p.payment_date) as total_revenue
from payment p join rental r on p.rental_id = r.rental_id 
join inventory i on i.inventory_id = r.inventory_id 
join film f on f.film_id = i.film_id 
order by 1,3;



-- Q.3 Determine the average rental duration for each film, considering films with similar lengths.
select film_id,title,rental_duration, avg(rental_duration) over(partition by length) as avg_rental_duration
from film where length is not null ;

-- Q.4 Identify the top 3 films in each category based on their rental counts.
-- film_category,rental,inventory

WITH RankedFilms AS (
    SELECT fc.category_id, fc.film_id, f.title,
        ROW_NUMBER() OVER (PARTITION BY fc.category_id ORDER BY COUNT(r.rental_id) DESC) AS ranking
    FROM film_category fc
    JOIN rental r ON fc.film_id = r.inventory_id
    JOIN film f ON fc.film_id = f.film_id
    GROUP BY fc.category_id, fc.film_id, f.title
)
SELECT category_id, film_id, title, ranking
FROM RankedFilms
WHERE ranking <= 3;


-- Q.5 Calculate the difference in rental counts between each customer's total rentals and the average rentals across all customers.
select customer_id, count(rental_id), 
avg(count(rental_id)) over(),
count(rental_id)-avg(count(rental_id)) over() as diff_in_rental
from rental
group by customer_id;


-- Q.6 Find the monthly revenue trend for the entire rental store over time.
with monthly_revenue as (
select date_format(payment_date,'%y-%m') as month, 
sum(amount) as total from payment
group by date_format(payment_date,'%y-%m') )
select month,total, sum(total) over(order by month) as cumulative_revenue from monthly_revenue;


-- Q.7 Identify the customers whose total spending on rentals falls within the top 20% of all customers.
with customer_spending as( 
select customer_id, sum(amount) as total_spending, rank() over(order by sum(amount) desc) as rnk
from payment
group by 1)
select customer_id, total_spending from customer_spending
where rnk <= (select 0.2*count( distinct customer_id) +1 from customer_spending); -- +1 to roundup nxt integer 

-- Q.8 Calculate the running total of rentals per category, ordered by rental count.
with rental_category as(
select fc.category_id, count(r.rental_id) as total_count,
rank() over(partition by fc.category_id order by count(r.rental_id) desc) as rnk_
from film_category fc join inventory i on fc.film_id = i.film_id 
join rental r on r.inventory_id = i.inventory_id
group by 1)
select category_id,total_count, sum(total_count) over(order by total_count) as running_count
from rental_category
order by rnk_;


-- Q.9 Find the films that have been rented less than the average rental count for their respective categories.
with films_rented_less as (
select fc.film_id,fc.category_id,count(r.rental_id) as total_rental, 
avg(count(r.rental_id)) over (partition by fc.category_id) as avg_rental_count
from film_category fc join inventory i on fc.film_id = i.film_id 
join rental r on r.inventory_id = i.inventory_id
group by 1,2)
select film_id,category_id,total_rental,avg_rental_count
from films_rented_less 
where total_rental < avg_rental_count;

-- Q.10 Identify the top 5 months with the highest revenue and display the revenue generated in each month.
with monthly_revenue as (
select date_format(payment_date,'%m') as month_, 
sum(amount) as total_revenue, rank() over(order by sum(amount) desc) as total from payment
group by date_format(payment_date,'%m'))
select total,month_,total_revenue from monthly_revenue
limit 5;


