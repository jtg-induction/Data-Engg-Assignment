-- Q9 Top 10 Tires Bonus: Top 10 dealer of nation will get $3 per tire additional incentive
-- cost time = 6.5s
WITH dealers_with_their_rank AS (
    SELECT
        s.dealernumber AS dealernumber,
        to_char(s.calendardate :: date, 'YYYY FMMonth') AS month_of_sale,
        SUM(s.units) AS total_units_sold,
        ROW_NUMBER() OVER(
            PARTITION BY to_char(s.calendardate :: date, 'YYYY FMMonth')
            ORDER BY
                SUM(s.units) DESC
        ) AS dealers_rank
    FROM
        sales s
        INNER JOIN parts p ON s.part_number = p.part_number
    WHERE
        p.part_category_2 ILIKE '%tires%'
    GROUP BY
        to_char(s.calendardate :: date, 'YYYY FMMonth'),
        s.dealernumber
)
SELECT
    month_of_sale,
    dealernumber,
    total_units_sold,
    total_units_sold * 3 AS addtional_top_10_incentive
FROM
    dealers_with_their_rank
WHERE
    dealers_rank <= 10
ORDER BY
    month_of_sale ASC,
    total_units_sold DESC;

-- query with format output
WITH dealers_with_their_rank AS (
    SELECT
        s.dealernumber AS dealernumber,
        to_char(s.calendardate :: date, 'YYYY FMMonth') AS month_of_sale,
        to_char(s.calendardate :: date, 'YYYY FMMonth') AS month_of_sales,
        date_trunc('month', s.calendardate) :: date AS from_period,
        (
            date_trunc('month', s.calendardate) + INTERVAL '1 month' - INTERVAL '1 day'
        ) :: date AS to_period,
        SUM(s.units) AS total_units_sold,
        ROW_NUMBER() OVER(
            PARTITION BY to_char(s.calendardate :: date, 'YYYY FMMonth')
            ORDER BY
                SUM(s.units) DESC
        ) AS dealers_rank
    FROM
        sales s
        INNER JOIN parts p ON s.part_number = p.part_number
    WHERE
        p.part_category_2 ILIKE '%tires%'
    GROUP BY
        to_char(s.calendardate :: date, 'YYYY FMMonth'),
        s.dealernumber,
        date_trunc('month', s.calendardate)
)
SELECT
    'JOSH_CLEAN_AUTOMOBILES' AS nation,
    from_period,
    to_period,
    1 AS compute_period,
    month_of_sale,
    dealernumber AS dealer,
    total_units_sold,
    total_units_sold * 3 AS addtional_top_10_incentive
FROM
    dealers_with_their_rank
WHERE
    dealers_rank <= 10
ORDER BY
    month_of_sale ASC,
    total_units_sold DESC