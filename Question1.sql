-- Q1 -> Total Sales for each part for a dealership.
-- cost time = 38.4s
SELECT
    dealernumber,
    part_number,
    SUM(value) AS total_sales
FROM
    sales
-- GROUP BY
--     dealernumber,
--     part_number;
    

-- Monthly wise sales
-- cost time = 26.6s
SELECT
    s.dealernumber,
    s.part_number,
    Sum(s.value) AS total_sales,
    to_char(s.calendardate::date,'YYYY FMMonth') as month_of_sale
FROM
    sales s
GROUP BY
    s.dealernumber,
    s.part_number,
    to_char(s.calendardate::date,'YYYY FMMonth');

               