-- Q7 -> Top 5 Bonus: Top 5 (by Sales excluding tires) Dealers of each area will get additional $300 incentives.

--cost time = 1m 21s
WITH region_delear AS(
    SELECT
        e.region,
        s.dealernumber,
        e.dealername,
        to_char(s.calendardate::date,'YYYY FMMonth') AS month_of_sales,
        SUM(s.value) AS total_sales
    FROM
        sales s 
    INNER JOIN
        entity e ON s.dealernumber = e.dealernumber
    INNER JOIN
        parts p ON s.part_number = p.part_number
    WHERE
        p.part_category_2 NOT ILIKE '%tires%'
    GROUP BY
        e.region,
        s.dealernumber,
        e.dealername,
        to_char(s.calendardate::date,'YYYY FMMonth')
                 
)

SELECT
    d1.region,
    d1.dealernumber,
    d1.dealername,
    d1.month_of_sales,
    d1.total_sales
FROM
    region_delear d1
WHERE
    5 > (
        SELECT
            COUNT(*)
        FROM
            region_delear d2
        WHERE
            d2.region = d1.region AND d2.month_of_sales = d1.month_of_sales AND d2.total_sales > d1.total_sales
    )
ORDER BY
    d1.region,
    d1.total_sales
DESC;       