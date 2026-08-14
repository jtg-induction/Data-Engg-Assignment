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
    to_char(s.calendardate::date,'YYYY FMMonth') as month_of_sale
FROM 
    sales s   
GROUP BY
    dealernumber,
    to_char(s.calendardate::date,'YYYY FMMonth');
    