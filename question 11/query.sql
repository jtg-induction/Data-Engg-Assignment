WITH sales_base AS (
    SELECT
        s.dealernumber,
        s.part_number,
        s.value,
        s.units,
        p.part_category_2,
        p.part_description,
        s.calendardate,
        o.sales_obj :: NUMERIC AS sales_obj,
        o.tires_tier_1_obj :: NUMERIC AS tires_tier_1_obj,
        o.tires_tier_2_obj :: NUMERIC AS tires_tier_2_obj,
        o.tires_tier_3_obj :: NUMERIC AS tires_tier_3_obj
    FROM
        sales s
        INNER JOIN parts p ON s.part_number = p.part_number
        INNER JOIN objectives o ON s.dealernumber = o.dealer
        AND o.month = to_char(s.calendardate :: date, 'YYYYMM')
),
total_parts_incentive AS (
    SELECT
        dealernumber,
        to_char(calendardate :: date, 'YYYY FMMonth') AS month_of_incentive,
        CASE
            WHEN SUM(value) < (0.9 * sales_obj :: numeric) THEN 0
            WHEN SUM(value) >= (0.9 * sales_obj :: numeric)
            AND (SUM(value) < sales_obj :: numeric) THEN 0.05 * SUM(value)
            WHEN SUM(value) >= sales_obj :: numeric
            AND SUM(value) <= (1.25 * sales_obj :: numeric) THEN 0.05 * SUM(value) + 0.06 * (SUM(value) - sales_obj :: numeric)
            ELSE 0.05 * SUM(value) + 0.06 * (Sum(value) - sales_obj :: numeric) + 0.07 * (SUM(value) - 1.25 * sales_obj :: numeric)
        END AS parts_incentive
    FROM
        sales_base
    WHERE
        part_category_2 NOT ILIKE '%tires%'
    GROUP BY
        dealernumber,
        sales_obj,
        to_char(calendardate :: date, 'YYYY FMMonth')
),
additional_incentive_for_top_5 AS (
    WITH region_dealer AS(
        SELECT
            e.region,
            sb.dealernumber,
            e.dealername,
            to_char(sb.calendardate :: date, 'YYYY FMMonth') AS month_of_sales,
            SUM(sb.value) AS total_sales
        FROM
            sales_base sb
            INNER JOIN entity e ON sb.dealernumber = e.dealernumber
        WHERE
            sb.part_category_2 NOT ILIKE '%tires%'
        GROUP BY
            e.region,
            sb.dealernumber,
            e.dealername,
            to_char(sb.calendardate :: date, 'YYYY FMMonth')
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
        total_sales DESC
),
tires_incentive AS (
    SELECT
        dealernumber,
        to_char(calendardate :: date, 'YYYY FMMonth') AS month_of_incentive,
        CASE
            WHEN SUM(units) >= tires_tier_3_obj :: numeric THEN 250
            WHEN SUM(units) >= tires_tier_2_obj :: numeric THEN 150
            WHEN SUM(units) >= tires_tier_1_obj :: numeric THEN 100
            ELSE 0
        END AS tires_incentive
    FROM
        sales_base
    WHERE
        part_category_2 ILIKE '%tires%'
    GROUP BY
        dealernumber,
        to_char(calendardate :: date, 'YYYY FMMonth'),
        tires_tier_1_obj,
        tires_tier_2_obj,
        tires_tier_3_obj
),
additional_top_10_incentive AS (
    WITH dealers_with_their_rank AS (
        SELECT
            dealernumber AS dealernumber,
            to_char(calendardate :: date, 'YYYY FMMonth') AS month_of_sale,
            SUM(units) AS total_units_sold,
            ROW_NUMBER() OVER(
                PARTITION BY to_char(calendardate :: date, 'YYYY FMMonth')
                ORDER BY
                    SUM(units) DESC
            ) AS dealers_rank
        FROM
            sales_base
        WHERE
            part_category_2 ILIKE '%tires%'
        GROUP BY
            to_char(calendardate :: date, 'YYYY FMMonth'),
            dealernumber
    )
    SELECT
        month_of_sale,
        dealernumber,
        total_units_sold,
        total_units_sold * 3 AS additional_top_10_tires_incentive
    FROM
        dealers_with_their_rank
    WHERE
        dealers_rank <= 10
    ORDER BY
        month_of_sale ASC,
        total_units_sold DESC
),
eligible_dealers AS (
    SELECT
        pe.dealer AS dealer,
        to_char(to_date(pe.month, 'MM YYYY'), 'YYYY FMMonth') AS month_of_eligibility,
        CASE
            WHEN pe.penetration :: NUMERIC > 0.9 * AVG(pe.penetration :: NUMERIC) OVER(PARTITION BY e.region, pe.month) THEN 'ELIGIBLE'
            ELSE 'NOT ELIGIBLE'
        END AS ELIGIBILITY
    FROM
        penetration pe
        INNER JOIN entity e ON e.dealernumber = trim(pe.dealer)
    WHERE
        e.terminationdate IS NULL
)
SELECT
    ed.dealer,
    ed.month_of_eligibility,
    COALESCE(pa.parts_incentive, 0) + COALESCE(t5.additional_incentive, 0) + COALESCE(ti.tires_incentive, 0) + COALESCE(t10.additional_top_10_tires_incentive, 0) AS total_incentive
FROM
    eligible_dealers ed
    LEFT JOIN total_parts_incentive pa ON trim(ed.dealer) = trim(pa.dealernumber)
    AND ed.month_of_eligibility = pa.month_of_incentive
    LEFT JOIN additional_incentive_for_top_5 t5 ON trim(ed.dealer) = trim(t5.dealernumber)
    AND ed.month_of_eligibility = t5.month_of_sales
    LEFT JOIN tires_incentive ti ON trim(ed.dealer) = trim(ti.dealernumber)
    AND ed.month_of_eligibility = ti.month_of_incentive
    LEFT JOIN additional_top_10_incentive t10 ON trim(ed.dealer) = trim(t10.dealernumber)
    AND ed.month_of_eligibility = t10.month_of_sale
WHERE
    ed.eligibility = 'ELIGIBLE';