-- Q5 -> Calculate Parts Tier for each dealership: (Excluding Tires)
--          a. Tier 1: If Sales < 90% of Objective
--          b. Tier 2: If 90% of objective <= Sales < 100% of objective
--          c Tier 3: If 100% of objective <= Sales <= 125% of objective
--          d. Tier 4: If Monthly Sales > 125% of objective


SELECT
    s.dealernumber,
    CASE 
        WHEN SUM(s.val) < (0.9 * o.sales_obj) THEN 'Tier 1'
        WHEN SUM(s.val) >= (0.9 * o.sales_obj) AND (SUM(s.val) < o.sales_obj) THEN 'Tier 2'
        WHEN SUM(s.val) >= o.sales_obj AND SUM(s.val) < (1.25 * o.sales_obj) THEN 'Tier 3'
        ELSE 'Tier 4'  
    END AS tier_level
FROM
    sales s
INNER JOIN
    objectives o ON s.dealernumber = o.dealernumber
INNER JOIN
    parts p ON s.part_number = p.part_number
WHERE
    LOWER(p.description) NOT LIKE '%tire%'
GROUP BY
    s.dealernumber,
    o.sales_obj;   

-- with added datapoint for total_sales and objective of the dealer

SELECT
    s.dealernumber,
    SUM(s.val) AS total_sales,
    o.sales_obj,
    CASE 
        WHEN SUM(s.val) < (0.9 * o.sales_obj) THEN 'Tier 1'
        WHEN SUM(s.val) >= (0.9 * o.sales_obj) AND (SUM(s.val) < o.sales_obj) THEN 'Tier 2'
        WHEN SUM(s.val) >= o.sales_obj AND SUM(s.val) < (1.25 * o.sales_obj) THEN 'Tier 3'
        ELSE 'Tier 4'  
    END AS tier_level
FROM
    sales s
INNER JOIN
    objectives o ON s.dealernumber = o.dealernumber
INNER JOIN
    parts p ON s.part_number = p.part_number
WHERE
    LOWER(p.description) NOT LIKE '%tire%'
GROUP BY
    s.dealernumber,
    o.sales_obj; 
    


