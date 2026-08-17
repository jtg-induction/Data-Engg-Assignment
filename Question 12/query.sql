WITH total_parts_incentive AS (
    SELECT
        s.dealernumber,
        to_char(s.calendardate :: date, 'YYYY FMMonth') AS month_of_incentive,
        CASE
            WHEN SUM(s.value) < (0.9 * o.sales_obj :: numeric) THEN 0
            WHEN SUM(s.value) >= (0.9 * o.sales_obj :: numeric)
            AND (SUM(s.value) < o.sales_obj :: numeric) THEN 0.05 * SUM(s.value)
            WHEN SUM(s.value) >= o.sales_obj :: numeric
            AND SUM(s.value) <= (1.25 * o.sales_obj :: numeric) THEN 0.05 * SUM(s.value) + 0.06 * (SUM(s.value) - o.sales_obj :: numeric)
            ELSE 0.05 * SUM(s.value) + 0.06 * (Sum(s.value) - o.sales_obj :: numeric) + 0.07 * (SUM(s.value) - 1.25 * o.sales_obj :: numeric)
        END AS parts_incentive
    FROM
        sales s
        INNER JOIN objectives o ON s.dealernumber = o.dealer
        AND o.month = to_char(s.calendardate :: date, 'YYYYMM')
        INNER JOIN parts p ON s.part_number = p.part_number
    WHERE
        p.part_category_2 NOT ILIKE '%tires%'
    GROUP BY
        s.dealernumber,
        o.sales_obj,
        to_char(s.calendardate :: date, 'YYYY FMMonth')
),
additional_incentive_for_top_5 AS (
    WITH region_delear AS(
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
    )
    SELECT
        d1.region,
        d1.dealernumber,
        d1.dealername,
        d1.month_of_sales,
        d1.total_sales,
        300 AS additional_incentive
    FROM
        region_delear d1
    WHERE
        5 > (
            SELECT
                COUNT(*)
            FROM
                region_delear d2
            WHERE
                d2.region = d1.region
                AND d2.month_of_sales = d1.month_of_sales
                AND d2.total_sales > d1.total_sales
        )
    ORDER BY
        d1.region,
        d1.total_sales DESC
),
tires_incentive AS (
    SELECT
        s.dealernumber,
        to_char(s.calendardate :: date, 'YYYY FMMonth') AS month_of_incentive,
        CASE
            WHEN SUM(s.units) >= o.tires_tier_3_obj :: numeric THEN 250
            WHEN SUM(s.units) >= o.tires_tier_2_obj :: numeric THEN 150
            WHEN SUM(s.units) >= o.tires_tier_1_obj :: numeric THEN 100
            ELSE 0
        END AS tires_incentive
    FROM
        sales s
        INNER JOIN objectives o ON s.dealernumber = o.dealer
        AND o.month = to_char(s.calendardate :: date, 'YYYYMM')
        INNER JOIN parts p ON s.part_number = p.part_number
    WHERE
        p.part_category_2 ILIKE '%tires%'
    GROUP BY
        s.dealernumber,
        to_char(s.calendardate :: date, 'YYYY FMMonth'),
        o.tires_tier_1_obj,
        o.tires_tier_2_obj,
        o.tires_tier_3_obj
),
additional_top_10_incentive AS (
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
            p.part_description ILIKE '%Tires%'
        GROUP BY
            to_char(s.calendardate :: date, 'YYYY FMMonth'),
            s.dealernumber
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
    WITH avg_penetration AS (
        SELECT
            e.region AS region_of_penetration,
            to_char(to_date(pe.month, 'MM YYYY'), 'YYYY FMMonth') AS month_of_penetration,
            AVG(pe.penetration :: numeric) AS avg_penetration_of_the_region
        FROM
            entity e
            INNER JOIN penetration pe ON e.dealernumber = trim(pe.dealer)
        WHERE
            e.terminationdate IS NULL
        GROUP BY
            e.region,
            pe.month
        ORDER BY
            region ASC,
            pe.month ASC
    )
    SELECT
        pe.dealer,
        e.region,
        to_char(to_date(pe.month, 'MM YYYY'), 'YYYY FMMonth') AS month_of_eligibility,
        pe.penetration,
        CASE
            WHEN pe.penetration :: numeric > 0.9 * ap.avg_penetration_of_the_region THEN 'ELIGIBLE'
            ELSE 'NOT ELIGIBLE'
        END AS ELIGIBIILITY
    FROM
        penetration pe
        INNER JOIN entity e ON trim(pe.dealer) = e.dealernumber
        INNER JOIN avg_penetration ap ON to_char(to_date(pe.month, 'MM YYYY'), 'YYYY FMMonth') = ap.month_of_penetration
        AND e.region = ap.region_of_penetration
    WHERE
        e.terminationdate IS NULL
),
total_incentive_for_dealers AS (
    SELECT
        ed.dealer,
        ed.month_of_eligibility,
        ed.region,
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
        ed.ELIGIBIILITY = 'ELIGIBLE'
)
SELECT
    td.dealer,
    td.month_of_eligibility,
    td.region,
    td.total_incentive AS total_incentive_for_dealers,
    SUM(td.total_incentive) OVER(PARTITION BY td.region) AS total_incentive_region_wise,
    SUM(td.total_incentive) OVER() AS total_incentive_for_nation
FROM
    total_incentive_for_dealers td