-- Q5 -> Calculate Parts Tier for each dealership: (Excluding Tires)
--          a. Tier 1: If Sales < 90% of Objective
--          b. Tier 2: If 90% of objective <= Sales < 100% of objective
--          c Tier 3: If 100% of objective <= Sales <= 125% of objective
--          d. Tier 4: If Monthly Sales > 125% of objective


SELECT
    dealernumber,
    CASE 
        WHEN SUM(val) < (0.9 * o.sales_obj) THEN 'Tier 1'
        WHEN SUM(val) >= (0.9 * o.sales_obj) AND (SUM(val) < o.sales_obj) THEN 'Tier 2'
        WHEN SUM(val) >= o.sales_obj AND SUM(val) < (1.25 * o.sales_obj) THEN 'Tier 3'
        ELSE 'Tier 4'  
    END AS tier_level
FROM
    sales 
INNER JOIN
    objectives o ON s.dealernumber = o.dealernumber
INNER JOIN
    parts p ON s.part_number = p.part_number
WHERE
    LOWER(p.description) NOT LIKE '%tire%'
GROUP BY
    dealernumber                     
