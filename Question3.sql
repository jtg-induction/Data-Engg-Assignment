-- Q3 -> Total Sales for a dealership.

SELECT
    dealernumber,
    SUM(val) AS total_sales
FROM 
    sales
GROUP BY
    dealernumber;        