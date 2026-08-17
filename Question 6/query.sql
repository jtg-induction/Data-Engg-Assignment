-- Q6 Parts Incentive: Calculate Parts Incentives for each dealership: (Excluding Tires)
--                     Tier 1: $0
--                     Tier 2: 5% of Sales
--                     Tier 3: Tier 2 Incentive + 6% additional incentive on sales above 100% of objectives
--                     Tier 4: Tier 3 Incentive + 7 % additional incentive on sales above 125% of objectives
-- cost time = 1m 4s
SELECT
    s.dealernumber,
    to_char(s.calendardate :: date, 'YYYY FMMonth') AS month_of_incentive,
    CASE
        WHEN SUM(s.value) < (0.9 * o.sales_obj :: numeric) THEN 0
        WHEN SUM(s.value) >= (0.9 * o.sales_obj :: numeric)
        AND (SUM(s.value) < o.sales_obj :: numeric) THEN 0.05 * SUM(s.value)
        WHEN SUM(s.value) >= o.sales_obj :: numeric
        AND SUM(s.value) <= (1.25 * o.sales_obj :: numeric) THEN 0.05 * SUM(s.value) + 0.06 * (SUM(s.value) - o.sales_obj :: numeric)
        ELSE 0.05 * SUM(s.value) + 0.06 * (Sum(s.value) - o.sales_obj :: numeric) + 0.07 * (SUM(s.value) - 1.25 * o.sales_obj :: numeric)
    END AS parts_incentive
FROM
    sales s
    INNER JOIN objectives o ON s.dealernumber = o.dealer
    AND o.month = to_char(s.calendardate :: date, 'YYYYMM')
    INNER JOIN parts p ON s.part_number = p.part_number
WHERE
    p.part_category_2 NOT ILIKE '%tires%'
GROUP BY
    s.dealernumber,
    o.sales_obj,
    to_char(s.calendardate :: date, 'YYYY FMMonth')