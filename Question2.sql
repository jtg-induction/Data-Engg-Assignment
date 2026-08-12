-- Q2 -> Units sold for each part for a dealership.

SELECT
    dealernumber,
    part_number,
    SUM(units) AS total_units
FROM
    sales
GROUP BY
    dealernumber,
    part_number;