-- Q8 Dealer Tires Incentive: (Use Tire Units instead of Dollar Values in calculation)
--    If Tier 1 Obj achieved then $100
--    If Tier 2 Obj achieved then $150
--    If Tier 3 Obj achieved then $250
-- cost time = 10.59s
SELECT
    s.dealernumber,
    to_char(s.calendardate :: date, 'YYYY FMMonth') AS month_of_incentive,
    CASE
        WHEN SUM(s.units) >= o.tires_tier_3_obj :: numeric THEN 250
        WHEN SUM(s.units) >= o.tires_tier_2_obj :: numeric THEN 150
        WHEN SUM(s.units) >= o.tires_tier_1_obj :: numeric THEN 100
        ELSE 0
    END AS tires_incentive
FROM
    sales s
    INNER JOIN objectives o ON s.dealernumber = o.dealer
    AND o.month = to_char(s.calendardate :: date, 'YYYYMM')
    INNER JOIN parts p ON s.part_number = p.part_number
WHERE
    p.part_category_2 ILIKE '%tires%'
GROUP BY
    s.dealernumber,
    to_char(s.calendardate :: date, 'YYYY FMMonth'),
    o.tires_tier_1_obj,
    o.tires_tier_2_obj,
    o.tires_tier_3_obj;

-- query with format output
SELECT
    'JOSH_CLEAN_AUTOMOBILES' AS nation,
    date_trunc('month', s.calendardate) :: date AS from_period,
    (
        date_trunc('month', s.calendardate) + INTERVAL '1 month' - INTERVAL '1 day'
    ) :: date AS to_period,
    1 AS compute_period,
    s.dealernumber AS dealer,
    to_char(s.calendardate :: date, 'YYYY FMMonth') AS month_of_incentive,
    CASE
        WHEN SUM(s.units) >= o.tires_tier_3_obj :: numeric THEN 250
        WHEN SUM(s.units) >= o.tires_tier_2_obj :: numeric THEN 150
        WHEN SUM(s.units) >= o.tires_tier_1_obj :: numeric THEN 100
        ELSE 0
    END AS tires_incentive
FROM
    sales s
    INNER JOIN objectives o ON s.dealernumber = o.dealer
    AND o.month = to_char(s.calendardate :: date, 'YYYYMM')
    INNER JOIN parts p ON s.part_number = p.part_number
WHERE
    p.part_category_2 ILIKE '%tires%'
GROUP BY
    s.dealernumber,
    to_char(s.calendardate :: date, 'YYYY FMMonth'),
    o.tires_tier_1_obj,
    o.tires_tier_2_obj,
    o.tires_tier_3_obj,
    date_trunc('month', s.calendardate);