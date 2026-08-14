-- Q5 -> Calculate Parts Tier for each dealership: (Excluding Tires)
--          a. Tier 1: If Sales < 90% of Objective
--          b. Tier 2: If 90% of objective <= Sales < 100% of objective
--          c.  Tier 3: If 100% of objective <= Sales <= 125% of objective
--          d. Tier 4: If Monthly Sales > 125% of objective


--cost time = 54.5s

SELECT
    s.dealernumber,
    to_char(s.calendardate::date,'YYYY FMMonth') as month_of_sale,
    CASE 
        WHEN SUM(s.value) < (0.9 * o.sales_obj::numeric) THEN 'Tier 1'
        WHEN SUM(s.value) >= (0.9 * o.sales_obj::numeric) AND (SUM(s.value) < o.sales_obj::numeric) THEN 'Tier 2'
        WHEN SUM(s.value) >= o.sales_obj::numeric AND SUM(s.value) <= (1.25 * o.sales_obj::numeric) THEN 'Tier 3'
        ELSE 'Tier 4'  
    END AS tier_level
FROM
    sales s    
INNER JOIN
    objectives o ON s.dealernumber = o.dealer AND to_char(s.calendardate::date,'YYYYMM') = o.month
INNER JOIN
    parts p ON s.part_number = p.part_number
WHERE
    p.part_category_2 NOT ILIKE '%tires%'
GROUP BY
    s.dealernumber,
    o.sales_obj,
    to_char(s.calendardate::date,'YYYY FMMonth')
    