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
    to_char(s.calendardate :: date, 'YYYY FMMonth') AS month_of_sale
FROM
    sales s
GROUP BY
    s.dealernumber,
    s.part_number,
    to_char(s.calendardate :: date, 'YYYY FMMonth');

-- query with format output 
SELECT
    'JOSH_CLEAN_AUTOMOBILES' AS nation,
    date_trunc('month', s.calendardate) :: date AS from_period,
    (
        date_trunc('month', s.calendardate) + INTERVAL '1 month' - INTERVAL '1 day'
    ) :: date AS to_period,
    1 AS compute_period,
    s.dealernumber AS dealer,
    s.part_number,
    Sum(s.units) AS total_units_sold,
    to_char(s.calendardate :: date, 'YYYY FMMonth') AS month_of_sale
FROM
    sales s
GROUP BY
    s.dealernumber,
    s.part_number,
    to_char(s.calendardate :: date, 'YYYY FMMonth'),
    date_trunc('month', s.calendardate);