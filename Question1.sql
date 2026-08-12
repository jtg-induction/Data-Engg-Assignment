-- Q1 -> Total Sales for each part for a dealership.
SELECT
    dealernumber,
    part_number,
    SUM(val) AS total_sales
FROM
    sales
GROUP BY
    dealernumber,
    part_number;
