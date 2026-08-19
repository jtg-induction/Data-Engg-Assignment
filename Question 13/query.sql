-- Q13 Calculate RSD (Relative Standard Deviation) Metric for all the dealers.
-- RSD = YoY % Growth of Dealer / YoY % Growth of Area
-- YoY % Growth = (Current Month Sales (in $) - Last Year Same Month Sales (in $)) / Last Year Same Month Sales (in $)
-- For Area YoY % Growth use only active dealers.
WITH dealer_sales AS (
    SELECT
        s.dealernumber,
        to_char(s.calendardate :: date, 'YYYY FMMonth') AS month_of_sale,
        e.region AS region,
        SUM(s.value) AS total_sales
    FROM
        sales s
        INNER JOIN entity e ON s.dealernumber = e.dealernumber
    WHERE
        terminationdate IS NULL
    GROUP BY
        s.dealernumber,
        e.region,
        to_char(s.calendardate :: date, 'YYYY FMMonth')
),
dealeryoy AS (
    SELECT
        ds1.dealernumber,
        ds1.month_of_sale,
        ds1.region,
        ds1.total_sales,
        ds2.total_sales AS last_year_sales,
        CASE
            WHEN ds2.total_sales IS NULL
            OR ds2.total_sales = 0 THEN 0
            ELSE (ds1.total_sales - ds2.total_sales) / ds2.total_sales
        END AS dealer_yoy
    FROM
        dealer_sales ds1
        LEFT JOIN dealer_sales ds2 ON ds1.dealernumber = ds2.dealernumber
        AND to_date(ds1.month_of_sale, 'YYYY Month') = to_date(ds2.month_of_sale, 'YYYY Month') + INTERVAL '1 Year'
),
regionyoy AS(
    SELECT
        ds1.region,
        ds1.month_of_sale,
        SUM(ds1.total_sales) AS current_region_sales,
        SUM(ds2.total_sales) AS last_year_region_sales,
        CASE
            WHEN SUM(ds2.total_Sales) IS NULL
            OR SUM(ds2.total_sales) = 0 THEN 0
            ELSE (SUM(ds1.total_sales) - SUM(ds2.total_sales)) / SUM(ds2.total_sales)
        END AS region_yoy
    FROM
        dealer_sales ds1
        LEFT JOIN dealer_sales ds2 ON ds1.dealernumber = ds2.dealernumber
        AND to_date(ds1.month_of_sale, 'YYYY Month') = to_date(ds2.month_of_sale, 'YYYY Month') + INTERVAL '1 Year'
    GROUP BY
        ds1.region,
        ds1.month_of_sale
)
SELECT
    d.dealernumber AS dealer,
    d.region,
    d.month_of_sale,
    d.dealer_yoy,
    r.region_yoy,
    CASE
        WHEN r.region_yoy IS NULL
        OR r.region_yoy = 0 THEN 0
        ELSE d.dealer_yoy / r.region_yoy
    END AS rsd
FROM
    dealeryoy d
    LEFT JOIN regionyoy r ON d.region = r.region
    AND d.month_of_sale = r.month_of_sale