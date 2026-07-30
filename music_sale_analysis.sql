create table artist(
artist_id int primary key,
name varchar(85)
)
create table playlist(
playlist_id	 int primary key,
name varchar(30)
)
create table album(
album_id int primary key,
title varchar(60),
artist_id int,
foreign key(artist_id) references artist(artist_id)
)
create table media_type(
media_type_id int primary key,
name varchar(30)
)
create table genre(
genre_id int primary key,	
name varchar(25)
)
create table track(
track_id int primary key,
name varchar(130),
album_id int,
media_type_id int,
genre_id int,
composer varchar(180),
milliseconds int,
bytes int,
unit_price float,
foreign key (album_id) references album(album_id),
foreign key (media_type_id) references media_type(media_type_id),
foreign key (genre_id) references genre(genre_id)
)
create table playlist_track(
playlist_id int,
track_id int,
foreign key (playlist_id) references playlist(playlist_id),
foreign key (track_id) references track(track_id)
)
create table invoice_line(
invoice_line_id	int primary key,
invoice_id	int,
track_id int,
unit_price	float,
quantity int,
foreign key (invoice_id) references invoice(invoice_id),
foreign key (track_id) references track(track_id)
)
create table customers(
customer_id	int primary key,
first_name varchar(15),
last_name varchar(15),
company varchar(30),
address varchar(50),
city varchar(30),
state varchar(10),
country varchar(20),
postal_code varchar(15),
phone varchar(25),
fax varchar(25),
email varchar(30),
support_rep_id int
)
create table invoice(
invoice_id	int primary key,
customer_id int,
invoice_date TIMESTAMP,
billing_address varchar(50),
billing_city varchar(30),
billing_state varchar(10),
billing_country	varchar(20),
billing_postal_code varchar(15),
total float,
foreign key (customer_id) references customers(customer_id)
)
ALTER TABLE customers
ADD CONSTRAINT fk_customer_employee
FOREIGN KEY (support_rep_id) REFERENCES employee(employee_id);

CREATE TABLE employee (
    employee_id INT PRIMARY KEY,
    last_name VARCHAR(20),
    first_name VARCHAR(20),
    title VARCHAR(30),
    reports_to INT,
	levels varchar(10),
    birthdate TIMESTAMP,
    hire_date TIMESTAMP,
    address VARCHAR(30),
    city VARCHAR(30),
    state VARCHAR(30),
    country VARCHAR(30),
    postal_code VARCHAR(10),
    phone VARCHAR(30),
    fax VARCHAR(30),
    email VARCHAR(60),
    FOREIGN KEY (reports_to) REFERENCES employee(employee_id)
);

--now we solving the bussiness questions 


--1/* Q1: Who is the senior most employee based on job title? */

select
*
from employee
order by levels desc 
limit 1;

--2/* Q2: Which countries have the most Invoices? */
select
billing_country,
count(invoice_id) as invoices 
from invoice
group by 1 
order by 2 desc

/* Q3: What are top 3 values of total invoice? */
select 
*
from invoice
order by total 
desc limit 3;

/* Q4: Which city has the best customers? We would like to throw a promotional Music Festival in the city we made the most money. 
Write a query that returns one city that has the highest sum of invoice totals. 
Return both the city name & sum of all invoice totals */
select
billing_city,
round(sum(total)::numeric,2) as total_invoices 
from invoice group by 1 
order by 2 desc;


/* Q5: Who is the best customer? The customer who has spent the most money will be declared the best customer. 
Write a query that returns the person who has spent the most money.*/

select 
c.customer_id,
c.first_name,
c.last_name,
round(sum(invoice.total)::numeric,2) as total_spent 
from
customers as c
inner join
invoice
on c.customer_id=invoice.customer_id
group by 1 
order by total_spent desc 
limit 1;

/* Q6: Write query to return the email, first name, last name, & Genre of all Rock Music listeners. 
Return your list ordered alphabetically by email starting with A. */

select
c.email,c.first_name,c.last_name,genre.name
from customers as c
inner join
invoice as inl
on c.customer_id=inl.customer_id 
join
invoice_line as il 
on
il.invoice_id=inl.invoice_id 
join
track
on il.track_id=track.track_id
join
genre
on track.genre_id=genre.genre_id
where genre.name like 'Rock'
order by email

/* Q7: Let's invite the artists who have written the most rock music in our dataset. 
Write a query that returns the Artist name and total track count of the top 10 rock bands. */

select a.name,
count(a.artist_id) as total_track,
genre.name as genre
from artist as a 
join 
album as al 
on a.artist_id=al.artist_id
join
track 
on track.album_id=al.album_id 
join 
genre
on genre.genre_id=track.genre_id
where genre.name like 'Rock'
group by 1,3
order by 2 desc
limit 10;

/* Q8: Return all the track names that have a song length longer than the average song length. 
Return the Name and Milliseconds for each track. Order by the song length with the longest songs listed first. */
select 
name,
milliseconds
from
track
where
milliseconds>(select avg(milliseconds) as avg_milliseconds from track);


--/* Q9: Find how much amount spent by each customer on artists? Write a query to return customer name, artist name and total spent */
with best_selling_artist as (
select a.artist_id,a.name as artist_name,sum(il.unit_price*il.quantity) as total_purchase
from artist as a join album al
on a.artist_id=al.artist_id join track as t
on al.album_id=t.album_id join invoice_line as il
on t.track_id=il.track_id join invoice as inl on
inl.invoice_id=il.invoice_id
group by 1,2
order by 3 desc
limit 1
)
select c.customer_id,c.first_name,c.last_name,bsa.artist_name,sum(il.unit_price*il.quantity) as amount_spent
from customers as c join invoice as inl 
on c.customer_id=inl.customer_id join invoice_line il
on il.invoice_id=inl.invoice_id join track as t
on t.track_id=il.track_id join album as al on 
al.album_id=t.album_id join artist as a
on a.artist_id=al.artist_id join best_selling_artist as bsa
on bsa.artist_id=a.artist_id
group by 1,2,3,4
order by 5 desc;

/* Q9: We want to find out the most popular music Genre for each country. We determine the most popular genre as the genre 
with the highest amount of purchases. Write a query that returns each country along with the top Genre. For countries where 
the maximum number of purchases is shared return all Genres.*/
WITH popular_genre AS 
(
    SELECT COUNT(invoice_line.quantity) AS purchases, customers.country, genre.name, genre.genre_id, 
	ROW_NUMBER() OVER(PARTITION BY customers.country ORDER BY COUNT(invoice_line.quantity) DESC) AS RowNo 
    FROM invoice_line 
	JOIN invoice ON invoice.invoice_id = invoice_line.invoice_id
	JOIN customers ON customers.customer_id = invoice.customer_id
	JOIN track ON track.track_id = invoice_line.track_id
	JOIN genre ON genre.genre_id = track.genre_id
	GROUP BY 2,3,4
	ORDER BY 2 ASC, 1 DESC
)
SELECT * FROM popular_genre WHERE RowNo <= 1

/* Q10: Write a query that determines the customer that has spent the most on music for each country. 
Write a query that returns the country along with the top customer and how much they spent. 
For countries where the top amount spent is shared, provide all customers who spent this amount. */
WITH Customter_with_country AS (
		SELECT customers.customer_id,first_name,last_name,billing_country,SUM(invoice.total) AS total_spending,
	    ROW_NUMBER() OVER(PARTITION BY billing_country ORDER BY SUM(total) DESC) AS RowNo 
		FROM invoice
		JOIN customers ON customers.customer_id = invoice.customer_id
		GROUP BY 1,2,3,4
		ORDER BY 4 ASC,5 DESC)
SELECT * FROM Customter_with_country WHERE RowNo <= 1

