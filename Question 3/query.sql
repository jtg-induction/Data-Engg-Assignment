-- Q3 -> Total Sales for a dealership.
-- cost time = 2.2s
SELECT
    dealernumber,
    SUM(value) AS total_sales
FROM
    sales
GROUP BY
    dealernumber;

-- with monthly wise sales
-- cost time 8.4s
SELECT
    s.dealernumber,
    SUM(s.value) AS total_sales,
    to_char(s.calendardate :: date, 'YYYY FMMonth') AS month_of_sale
FROM
    sales s
GROUP BY
    dealernumber,
    to_char(s.calendardate :: date, 'YYYY FMMonth');

--query with format output 
SELECT
    'JOSH_CLEAN_AUTOMOBILES' AS nation,
    date_trunc('month', s.calendardate) :: date AS from_period,
    (
        date_trunc('month', s.calendardate) + INTERVAL '1 month' - INTERVAL '1 day'
    ) :: date AS to_period,
    1 AS compute_period,
    s.dealernumber AS dealer,
    SUM(s.value) AS total_sales,
    to_char(s.calendardate :: date, 'YYYY FMMonth') AS month_of_sale
FROM
    sales s
GROUP BY
    dealernumber,
    to_char(s.calendardate :: date, 'YYYY FMMonth'),
    date_trunc('month', s.calendardate);