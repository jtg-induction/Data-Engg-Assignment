-- Q4 -> Total Units sold by a dealership.
-- cost time = 1.6s
SELECT
    dealernumber,
    SUM(units) AS total_units_sold
FROM 
    sales
GROUP BY
    dealernumber; 

-- with monthly wise sales
-- cost time 7.7s
SELECT
    s.dealernumber,
    SUM(s.units) AS total_units_sold,
    c.yearmonth AS month_of_sale
FROM 
    sales s 
INNER JOIN
    calendar c ON s.calendardate = c.calendardate::date    
GROUP BY
    dealernumber,
    c.yearmonth;
    