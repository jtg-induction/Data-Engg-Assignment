-- Q4 -> Total Units sold by a dealership.
-- cost time = 1.6s
SELECT
    dealernumber,
    SUM(units) AS total_units_sold
FROM
    sales
GROUP BY
    dealernumber;

-- with monthly wise sales
-- cost time 7.7s
SELECT
    s.dealernumber,
    SUM(s.units) AS total_units_sold,
    to_char(s.calendardate :: date, 'YYYY FMMonth') AS month_of_sale
FROM
    sales s
GROUP BY
    dealernumber,
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
    SUM(s.units) AS total_units_sold,
    to_char(s.calendardate :: date, 'YYYY FMMonth') AS month_of_sale
FROM
    sales s
GROUP BY
    dealernumber,
    to_char(s.calendardate :: date, 'YYYY FMMonth'),
    date_trunc('month', s.calendardate);