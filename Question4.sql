-- Q4 -> Total Units sold by a dealership.

SELECT
    dealernumber,
    SUM(units) AS total_units
FROM 
    sales
GROUP BY
    dealernumber; 
