select * from `202401-capitalbikeshare-tripdata`
limit 5;

drop table tripdata_01;
create table tripdata_01 as (
select ride_id , rideable_type, started_at, ended_at, start_station_name, member_casual, 
timestampdiff(second, started_at, ended_at) as duration
from `202401-capitalbikeshare-tripdata`
);

select count(*) from tripdata_01

select * from tripdata_01
limit 4

select *,
#sum(duration) over() as normal_sum, 
sum(duration) over (order by started_at) as running_total
from tripdata_01

select *,
sum(duration) over (partition by rideable_type order by started_at) as running_total
from tripdata_01

select *,
sum(duration) over (partition by start_station_name order by started_at) as running_total
from tripdata_01

select *,
sum(duration) over (partition by rideable_type, start_station_name order by started_at) as running_total
from tripdata_01

select *,
sum(duration) over (partition by start_station_name order by started_at) as running_total
from tripdata_01
where started_at > '2024-01-15'

#Create running total of duration, partition by member_casual and start_stn name, order by ended_at in descending order 
#where start date after 15 Jan

select * , sum(duration) over ( partition by member_casual ,start_station_name
 order by ended_at desc) as running_total
 from tripdata_01
 where started_at > '2015-01-15';

#Try at home: In the same query create three columns, running_total, running_count, running_avg

select * , sum(duration) over ( partition by member_casual ,start_station_name
 order by ended_at desc) as running_total ,
 count(duration) over ( partition by member_casual ,start_station_name
 order by ended_at desc) as running_count,
 avg(duration) over ( partition by member_casual ,start_station_name
 order by ended_at desc) as running_avg
 from tripdata_01
 where started_at > '2015-01-15';

Row_number()

select *,
row_number() over (order by started_at) as row_num
from tripdata_01

select *,
row_number() over (partition by start_station_name order by started_at) as row_num
from tripdata_01

#create row number based on duration, parition by rideable_type


select *,
rank() over (partition by start_station_name order by started_at) as rank_1
from tripdata_01

select *,
row_number() over (order by duration) as row_num,
rank() over (order by duration) as rnk,
dense_rank() over (order by duration) as dense_rnk
from tripdata_01

select *,
row_number() over (partition by rideable_type order by duration desc) as row_num,
rank() over (partition by rideable_type order by duration desc) as rnk,
dense_rank() over (partition by rideable_type order by duration desc) as dense_rnk
from tripdata_01


#Lag And Lead


select *,
Lag(duration, 1) over (partition by start_station_name order by started_at ) as prev_ride_dur,
lead(duration, 1) over (partition by start_station_name order by started_at ) as next_ride_dur
from tripdata_01

select *,
Lag(duration, 2) over (partition by start_station_name order by started_at ) as prev_ride_dur,
lead(duration, 2) over (partition by start_station_name order by started_at ) as next_ride_dur
from tripdata_01

select *,
Lag(duration) over (partition by start_station_name order by started_at ) as prev_ride_dur,
lead(duration) over (partition by start_station_name order by started_at ) as next_ride_dur
from tripdata_01


select *,
Lag(duration) over (partition by start_station_name order by started_at ) as prev_ride_dur,
duration - Lag(duration) over (partition by start_station_name order by started_at) as diff
from tripdata_01

select *,
Ntile(5) over (order by duration ) as quartile
from tripdata_01

# Running total of rides per user type
# Time difference between consecutive rides at each start station
# Assign a rank to each ride per day based on duration - Date function
# Group rides into 5 buckets (NTILE) based on duration

SELECT
*,
COUNT(*) OVER(PARTITION BY member_casual ORDER BY started_at) AS running_total
FROM tripdata_01;

select *, duration - lag(duration) over(partition by start_station_name order by ended_at) as time_diff from tripdata_01;


select *, rank() over(partition by date(started_at) order by duration desc) as rank_ride from tripdata_01;

select *, ntile(5) over(order by duration) as quintile from tripdata_01;


create table interim_trip_data as (
select *, date(started_at) as date_ride,
rank() over(partition by date(started_at) order by duration desc) as rank_ride from tripdata_01
)
;

select * from interim_trip_data
where rank_ride = 5;

select * from (
select *, date(started_at) as date_ride,
rank() over(partition by date(started_at) order by duration desc) as rank_ride from tripdata_01
) as a
where rank_ride = 5

select * from customer2

select * from orders2

select a.*, b.* 
from customer2 as a
inner join 
(
select * from orders2 
where price > 20000
)
as b
on a.customer_id = b.customer_id

select avg(salary) from employee_data

select * from employee_data
where salary > 77534

select * from employee_data
where salary > (select avg(salary) from employee_data)

select * from employee_data
where department in (select department from employee_data
group by department 
having count(*) > 7)

#Show all rides from tripdata where the ride duration (in seconds) is greater than the average ride duration

select * from tripdata_01
 where duration > (select avg(duration) from tripdata_01);
 
 
#Create a derived table that shows ride duration in minutes, then select the top 10 longest rides from it.

 create table tripdata_02 as (
select *, 
timestampdiff(minute, started_at, ended_at) as min_dur
from tripdata_01
);

-- select * , row_number() over(order by min_dur desc) as duration_rank 
-- from tripdata_02 where duration_rank >=10;

#From tripdata, show all rides that start from a station which had more than 10 rides overall.

select * from tripdata_01
where start_station_name in (select start_station_name from tripdata_01
	group by start_station_name
	having count(*) > 10);
    

#Show all countries with HDI greater than the global average HDI.

select distinct country from gapminder_data_graphs 
where hdi_index >= (select avg(hdi_index) from gapminder_data_graphs)

#Using a subquery, show all rides that started within 10 minutes after the previous ride at the same station.
select *
from (
    select *, lag(started_at) over(partition by start_station_name order by started_at) as prev_ride_start,
    timestampdiff(minute, started_at, lag(started_at) over(partition by start_station_name order by started_at)) as diff 
    from tripdata_01
    ) as a
where abs(diff) <=  10
order by started_at;


SELECT 
  *, 
  (SELECT AVG(salary) FROM employee_data) AS avg_salary, 
  (salary - (SELECT AVG(salary) FROM employee_data)) AS diff_salary
FROM employee_data;


#CTE

with trip_60 as (
Select * from tripdata_01
where duration > 60
),
trip_70 as (
Select * from tripdata_01
where duration > 60
)
select a.* from  trip_60 as a
inner join
trip_70 as b
on a.ride_id = b.ride_id














SELECT 
  ride_id,
  TIMESTAMPDIFF(MINUTE, started_at, ended_at) AS duration_mins,
  (SELECT AVG(TIMESTAMPDIFF(MINUTE, started_at, ended_at)) FROM tripdata) AS avg_duration
FROM tripdata;

WITH avg_duration_cte AS (
  SELECT AVG(TIMESTAMPDIFF(MINUTE, started_at, ended_at)) AS avg_duration FROM tripdata
)
SELECT 
  ride_id,
  TIMESTAMPDIFF(MINUTE, started_at, ended_at) AS duration_mins,
  (SELECT avg_duration FROM avg_duration_cte) AS avg_duration
FROM tripdata;


#Example : Rank top 5 longest rides per user type, Use a CTE

WITH ride_durations AS (
  SELECT 
    ride_id,
    member_casual,
    TIMESTAMPDIFF(MINUTE, started_at, ended_at) AS duration_mins
  FROM `202401-capitalbikeshare-tripdata`
),
ranked_rides AS (
  SELECT *,
         RANK() OVER (PARTITION BY member_casual ORDER BY duration_mins DESC) AS rnk
  FROM ride_durations
)
SELECT * 
FROM ranked_rides
WHERE rnk <= 5;


-- Calculate avg ride duration for each member/casual
-- compare each ride's duration to this avg
-- Show whether it's above or below average










