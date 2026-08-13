-- Q7 -> Top 5 Bonus: Top 5 (by Sales excluding tires) Dealers of each area will get additional $300 incentives.

--cost time = 1m 21s
WITH region_delear AS(
    SELECT
        e.region,
        s.dealernumber,
        e.dealername,
        c.yearmonth,
        SUM(s.value) AS total_sales
    FROM
        sales s 
    INNER JOIN
        calendar c ON s.calendardate = c.calendardate::date
    INNER JOIN
        entity e ON s.dealernumber = e.dealernumber
    INNER JOIN
        parts p ON s.part_number = p.part_number
    WHERE
        p.part_description NOT LIKE '%tire%'
    GROUP BY
        e.region,
        s.dealernumber,
        e.dealername,
        c.yearmonth          
)

SELECT
    d1.region,
    d1.dealernumber,
    d1.dealername,
    d1.yearmonth,
    d1.total_sales,
FROM
    region_delear d1
WHERE
    5 > (
        SELECT
            COUNT(*)
        FROM
            region_delear d2
        WHERE
            d2.region = d1.region AND d2.yearmonth = d1.yearmonth AND d2.total_sales > d1.total_sales
    )
ORDER BY
    d1.region,
    d1.total_sales
DESC;       