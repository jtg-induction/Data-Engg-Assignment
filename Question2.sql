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
    to_char(s.calendardate::date,'YYYY FMMonth') as month_of_sale
FROM
    sales s
GROUP BY
    s.dealernumber,
    s.part_number,
    month_of_sale;
    