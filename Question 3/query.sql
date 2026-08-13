-- Q3 -> Total Sales for a dealership.
-- cost time = 2.2s

SELECT
    dealernumber,
    SUM(value) AS total_sales
FROM 
    sales
GROUP BY
    dealernumber; 


-- with monthly wise sales
-- cost time 8.4s
SELECT
    s.dealernumber,
    SUM(s.value) AS total_sales,
    c.yearmonth AS month_of_sale
FROM 
    sales s 
INNER JOIN
    calendar c ON s.calendardate = c.calendardate::date    
GROUP BY
    dealernumber,
    c.yearmonth;
    