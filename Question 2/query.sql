-- Q2 -> Units sold for each part for a dealership.
-- cost time = 32.7s
SELECT
    dealernumber,
    part_number,
    SUM(units) AS total_units_sold
FROM
    sales
GROUP BY
    dealernumber,
    part_number;

-- Monthly wise units sold
-- cost time = 26.8s
SELECT
    s.dealernumber,
    s.part_number,
    Sum(s.units) AS total_units_sold,
    c.yearmonth AS month_of_sale
FROM
    sales s
INNER JOIN 
    calendar c ON s.calendardate = c.calendardate::date
GROUP BY
    s.dealernumber,
    s.part_number,
    c.yearmonth
    