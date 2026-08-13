-- Q8 Dealer Tires Incentive: (Use Tire Units instead of Dollar Values in calculation)
--    If Tier 1 Obj achieved then $100
--    If Tier 2 Obj achieved then $150
--    If Tier 3 Obj achieved then $250

-- cost time = 10.59s
SELECT
    s.dealernumber,
    c.yearmonth as month_of_incentive,
    CASE 
        WHEN SUM(s.units) >= o.tires_tier_3_obj::numeric THEN '$250'
        WHEN SUM(s.units) >= o.tires_tier_2_obj::numeric THEN '$150'
        WHEN SUM(s.units) >= o.tires_tier_1_obj::numeric THEN '$100'
        ELSE '$0'
    END as tires_incentive
FROM
    sales s   
INNER JOIN
    calendar c ON s.calendardate = c.calendardate::date    
INNER JOIN
    objectives o on s.dealernumber = o.dealer AND o.month = c.yearmonthsort
INNER JOIN
    parts p ON s.part_number = p.part_number
WHERE
    Lower(p.part_description) LIKE '%tire%'
GROUP BY
    s.dealernumber,
    c.yearmonth,
    o.tires_tier_1_obj,
    o.tires_tier_2_obj,
    o.tires_tier_3_obj;                      