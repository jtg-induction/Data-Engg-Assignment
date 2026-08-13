-- Q3 -> Total Sales for a dealership.

SELECT
    dealernumber,
    SUM(val) AS total_sales
FROM 
    sales
GROUP BY
    dealernumber; 

  
-- with more data points for dealer 
SELECT
    e.dealernumber,
    e.dealername,
    e.division,
    e.region,
    SUM(s.val) AS total_sales
FROM
    entity e
INNER JOIN
    sales s ON e.dealernumber = s.dealernumber
GROUP BY
    e.dealernumber,
    e.dealername,
    e.division,
    e.region

-- with all the dealers whether they have done any sales or not 
SELECT
    e.dealernumber,
    e.dealername,
    e.division,
    e.region,
    SUM(s.val) AS total_sales
FROM
    entity e
LEFT JOIN
    sales s ON e.dealernumber = s.dealernumber
GROUP BY
    e.dealernumber,
    e.dealername,
    e.division,
    e.region
     
