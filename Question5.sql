-- Q5 -> Calculate Parts Tier for each dealership: (Excluding Tires)
--          a. Tier 1: If Sales < 90% of Objective
--          b. Tier 2: If 90% of objective <= Sales < 100% of objective
--          c.  Tier 3: If 100% of objective <= Sales <= 125% of objective
--          d. Tier 4: If Monthly Sales > 125% of objective


SELECT
    s.dealernumber,
    c.yearmonth,
    CASE 
        WHEN SUM(s.value) < (0.9 * o.sales_obj::numeric) THEN 'Tier 1'
        WHEN SUM(s.value) >= (0.9 * o.sales_obj::numeric) AND (SUM(s.value) < o.sales_obj::numeric) THEN 'Tier 2'
        WHEN SUM(s.value) >= o.sales_obj::numeric AND SUM(s.value) <= (1.25 * o.sales_obj::numeric) THEN 'Tier 3'
        ELSE 'Tier 4'  
    END AS tier_level
FROM
    sales s
INNER JOIN
    calendar c ON s.calendardate = c.calendardate::date    
INNER JOIN
    objectives o ON s.dealernumber = o.dealer AND c.yearmonthsort = o.month
INNER JOIN
    parts p ON s.part_number = p.part_number
WHERE
    LOWER(p.part_description) NOT LIKE '%tire%'
GROUP BY
    s.dealernumber,
    o.sales_obj,
    c.yearmonth;
    