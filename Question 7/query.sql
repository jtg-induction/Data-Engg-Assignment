-- Q7 -> Top 5 Bonus: Top 5 (by Sales excluding tires) Dealers of each area will get additional $300 incentives.
--cost time = 47s
WITH region_dealer AS(
    SELECT
        e.region,
        s.dealernumber,
        e.dealername,
        to_char(s.calendardate :: date, 'YYYY FMMonth') AS month_of_sales,
        SUM(s.value) AS total_sales
    FROM
        sales s
        INNER JOIN entity e ON s.dealernumber = e.dealernumber
        INNER JOIN parts p ON s.part_number = p.part_number
    WHERE
        p.part_category_2 NOT ILIKE '%tires%'
    GROUP BY
        e.region,
        s.dealernumber,
        e.dealername,
        to_char(s.calendardate :: date, 'YYYY FMMonth')
),
dealer_rank AS (
    SELECT
        *,
        DENSE_RANK() OVER(
            PARTITION BY region,
            month_of_sales
            ORDER BY
                total_sales DESC
        ) AS rn
    FROM
        region_dealer
)
SELECT
    region,
    dealernumber,
    dealername,
    month_of_sales,
    total_sales,
    300 AS additional_incentive
FROM
    dealer_rank
WHERE
    rn <= 5
ORDER BY
    region,
    total_sales DESC;