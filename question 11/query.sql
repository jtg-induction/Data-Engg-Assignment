-- cost time = 3m 50s
WITH sales_base AS (
    SELECT
        s.dealernumber,
        s.part_number,
        s.value,
        s.units,
        e.region,
        e.dealername,
        p.part_category_2,
        p.part_description,
        s.calendardate,
        o.sales_obj :: NUMERIC AS sales_obj,
        o.tires_tier_1_obj :: NUMERIC AS tires_tier_1_obj,
        o.tires_tier_2_obj :: NUMERIC AS tires_tier_2_obj,
        o.tires_tier_3_obj :: NUMERIC AS tires_tier_3_obj,
        to_char(calendardate :: date, 'YYYY MM') AS month_of_sale
    FROM
        sales s
        INNER JOIN parts p ON s.part_number = p.part_number
        INNER JOIN objectives o ON s.dealernumber = o.dealer
        AND o.month = to_char(s.calendardate :: date, 'YYYYMM')
        INNER JOIN entity e ON s.dealernumber = e.dealernumber
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
        AND trim(pe.dealer) IS NOT NULL
),
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

-- Query with reduces joins 
-- cost time = 2m 18s
WITH sales_base AS (
    SELECT
        s.dealernumber,
        s.part_number,
        s.value,
        s.units,
        e.region,
        e.dealername,
        p.part_category_2,
        p.part_description,
        s.calendardate,
        o.sales_obj :: NUMERIC AS sales_obj,
        o.tires_tier_1_obj :: NUMERIC AS tires_tier_1_obj,
        o.tires_tier_2_obj :: NUMERIC AS tires_tier_2_obj,
        o.tires_tier_3_obj :: NUMERIC AS tires_tier_3_obj,
        to_char(calendardate :: date, 'YYYY FMMonth') AS month_of_sale
    FROM
        sales s
        INNER JOIN entity e ON s.dealernumber = e.dealernumber
        INNER JOIN parts p ON s.part_number = p.part_number
        INNER JOIN objectives o ON s.dealernumber = o.dealer
        AND o.month = to_char(s.calendardate :: date, 'YYYYMM')
),
parts_tires_sales AS (
    SELECT
        dealernumber,
        calendardate,
        sales_obj,
        tires_tier_1_obj,
        tires_tier_2_obj,
        tires_tier_3_obj,
        SUM(value) over(
            PARTITION BY dealernumber,
            to_char(calendardate :: date, 'YYYY FMMonth')
        ) AS total_sales,
        SUM(value) FILTER(
            WHERE
                part_category_2 NOT ILIKE '%tires%'
        ) OVER(
            PARTITION BY dealernumber,
            to_char(calendardate :: date, 'YYYY FMMonth')
        ) AS total_sales_without_tires,
        SUM(units) FILTER(
            WHERE
                part_category_2 ILIKE '%tires%'
        ) OVER(
            PARTITION BY dealernumber,
            to_char(calendardate :: date, 'YYYY FMMonth')
        ) AS total_sales_with_tires
    FROM
        sales_base
),
parts_tires_incenitves AS(
    SELECT
        DISTINCT dealernumber,
        to_char(calendardate :: date, 'YYYY FMMonth') AS month_of_incentive,
        CASE
            WHEN total_sales_without_tires < (0.9 * sales_obj :: numeric) THEN 0
            WHEN total_sales_without_tires >= (0.9 * sales_obj :: numeric)
            AND total_sales_without_tires < sales_obj :: numeric THEN 0.05 * total_sales_without_tires
            WHEN total_sales_without_tires >= sales_obj :: numeric
            AND total_sales_without_tires <= (1.25 * sales_obj :: numeric) THEN 0.05 * total_sales_without_tires + 0.06 * (total_sales_without_tires - sales_obj :: numeric)
            ELSE 0.05 * total_sales_without_tires + 0.06 * (total_sales_without_tires - sales_obj :: numeric) + 0.07 * (
                total_sales_without_tires - 1.25 * sales_obj :: numeric
            )
        END AS parts_incentive,
        CASE
            WHEN total_sales_with_tires >= tires_tier_3_obj :: numeric THEN 250
            WHEN total_sales_with_tires >= tires_tier_2_obj :: numeric THEN 150
            WHEN total_sales_with_tires >= tires_tier_1_obj :: numeric THEN 100
            ELSE 0
        END AS tires_incentive
    FROM
        parts_tires_sales
),
combined_dealer AS (
    SELECT
        region,
        dealernumber,
        dealername,
        month_of_sale,
        SUM(value) FILTER(
            WHERE
                part_category_2 NOT ILIKE '%tires%'
        ) AS total_sales,
        SUM(units) FILTER(
            WHERE
                part_category_2 ILIKE '%tires%'
        ) AS total_tire_units,
        DENSE_RANK() OVER(
            PARTITION BY region,
            month_of_sale
            ORDER BY
                SUM(value) FILTER(
                    WHERE
                        part_category_2 NOT ILIKE '%tires%'
                ) DESC
        ) AS sales_rank,
        ROW_NUMBER() OVER(
            PARTITION BY month_of_sale
            ORDER BY
                SUM(units) FILTER(
                    WHERE
                        part_category_2 ILIKE '%tires%'
                ) DESC
        ) AS tires_rank
    FROM
        sales_base
    GROUP BY
        region,
        dealernumber,
        dealername,
        month_of_sale
),
top_sellers_incentives AS (
    SELECT
        region,
        dealernumber,
        dealername,
        month_of_sale,
        total_sales,
        total_tire_units,
        CASE
            WHEN sales_rank <= 5 THEN 300
            ELSE 0
        END AS additional_incentive,
        CASE
            WHEN tires_rank <= 10 THEN total_tire_units * 3
            ELSE 0
        END AS additional_top_10_incentive
    FROM
        combined_dealer
    WHERE
        sales_rank <= 5
        OR tires_rank <= 10
    ORDER BY
        month_of_sale,
        region,
        total_sales DESC
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
        AND trim(pe.dealer) IS NOT NULL
)
SELECT
    ed.dealer,
    month_of_eligibility,
    tsi.region AS dealer_region,
    tsi.dealername AS dealer_name,
    date_trunc(
        'month',
        to_date(month_of_eligibility, 'YYYY Month')
    ) :: date AS from_period,
    (
        date_trunc(
            'month',
            to_date(month_of_eligibility, 'YYYY Month')
        ) + INTERVAL '1 month' - INTERVAL '1 day'
    ) :: date AS to_period,
    1 AS compute_period,
    COALESCE(pti.parts_incentive, 0) + COALESCE(pti.tires_incentive, 0) + COALESCE(tsi.additional_incentive, 0) + COALESCE(tsi.additional_top_10_incentive, 0) AS total_incentive
FROM
    eligible_dealers ed
    JOIN parts_tires_incenitves pti ON trim(ed.dealer) = pti.dealernumber
    AND ed.month_of_eligibility = pti.month_of_incentive
    JOIN top_sellers_incentives tsi ON trim(ed.dealer) = tsi.dealernumber
    AND ed.month_of_eligibility = tsi.month_of_sale
WHERE
    ed.ELIGIBILITY = 'ELIGIBLE';

WITH eligible_dealers AS (
    SELECT
        e.dealernumber AS dealer,
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
        AND trim(pe.dealer) IS NOT NULL
),
eligible_dealers_data AS (
    SELECT
        s.dealernumber,
        s.part_number,
        s.value,
        s.units,
        e.region,
        e.dealername,
        p.part_category_2,
        s.calendardate,
        o.sales_obj :: NUMERIC AS sales_obj,
        o.tires_tier_1_obj :: NUMERIC AS tires_tier_1_obj,
        o.tires_tier_2_obj :: NUMERIC AS tires_tier_2_obj,
        o.tires_tier_3_obj :: NUMERIC AS tires_tier_3_obj,
        ed.month_of_eligibility,
        ed.eligibility
    FROM
        eligible_dealers ed
        JOIN sales s ON trim(ed.dealer) = s.dealernumber
        AND ed.month_of_eligibility = to_char(s.calendardate :: date, 'YYYY FMMonth')
        INNER JOIN parts p ON s.part_number = p.part_number
        INNER JOIN objectives o ON s.dealernumber = o.dealer
        AND o.month = to_char(s.calendardate :: date, 'YYYYMM')
        INNER JOIN entity e ON s.dealernumber = e.dealernumber
    WHERE
        ed.eligibility = 'ELIGIBLE'
),
dealers_sales_data AS(
    SELECT
        dealernumber,
        MAX(region) AS region,
        Max(dealername) AS dealername,
        month_of_eligibility,
        MAX(sales_obj) AS sales_obj,
        MAX(tires_tier_1_obj) AS tires_tier_1_obj,
        MAX(tires_tier_2_obj) AS tires_tier_2_obj,
        MAX(tires_tier_3_obj) AS tires_tier_3_obj,
        SUM(value) FILTER(
            WHERE
                part_category_2 NOT ILIKE '%tires%'
        ) AS dealer_sales_without_tires,
        SUM(units) FILTER(
            WHERE
                part_category_2 ILIKE '%tires%'
        ) AS dealer_sales_with_tires
    FROM
        eligible_dealers_data
    GROUP BY
        dealernumber,
        month_of_eligibility
),
dealers_ranks AS (
    SELECT
        dealernumber,
        dealername,
        region,
        month_of_eligibility,
        dealer_sales_without_tires,
        dealer_sales_with_tires,
        sales_obj,
        tires_tier_1_obj,
        tires_tier_2_obj,
        tires_tier_3_obj,
        DENSE_RANK() OVER(
            PARTITION BY region,
            month_of_eligibility
            ORDER BY
                dealer_sales_without_tires DESC
        ) AS sales_rank,
        ROW_NUMBER() OVER(
            PARTITION BY month_of_eligibility
            ORDER BY
                dealer_sales_with_tires DESC
        ) AS tires_rank
    FROM
        dealers_sales_data
),
dealers_incentives AS (
    SELECT
        dealernumber,
        dealername,
        month_of_eligibility,
        dealer_sales_without_tires,
        dealer_sales_with_tires,
        region,
        sales_obj,
        tires_tier_1_obj,
        tires_tier_2_obj,
        tires_tier_3_obj,
        sales_rank,
        tires_rank,
        CASE
            WHEN dealer_sales_without_tires < (0.9 * sales_obj :: numeric) THEN 0
            WHEN dealer_sales_without_tires >= (0.9 * sales_obj :: numeric)
            AND dealer_sales_without_tires < sales_obj :: numeric THEN 0.05 * dealer_sales_without_tires
            WHEN dealer_sales_without_tires >= sales_obj :: numeric
            AND dealer_sales_without_tires <= (1.25 * sales_obj :: numeric) THEN 0.05 * dealer_sales_without_tires + 0.06 * (
                dealer_sales_without_tires - sales_obj :: numeric
            )
            ELSE 0.05 * dealer_sales_without_tires + 0.06 * (
                dealer_sales_without_tires - sales_obj :: numeric
            ) + 0.07 * (
                dealer_sales_without_tires - 1.25 * sales_obj :: numeric
            )
        END AS parts_incentive,
        CASE
            WHEN dealer_sales_with_tires >= tires_tier_3_obj :: numeric THEN 250
            WHEN dealer_sales_with_tires >= tires_tier_2_obj :: numeric THEN 150
            WHEN dealer_sales_with_tires >= tires_tier_1_obj :: numeric THEN 100
            ELSE 0
        END AS tires_incentive
    FROM
        dealers_ranks
),
dealers_with_additional_incentives AS (
    SELECT
        dealernumber,
        dealername,
        month_of_eligibility,
        region,
        dealer_sales_with_tires,
        parts_incentive,
        tires_incentive,
        sales_rank,
        tires_rank,
        CASE
            WHEN sales_rank <= 5 THEN 300
            ELSE 0
        END AS additional_incentive,
        CASE
            WHEN tires_rank <= 10 THEN dealer_sales_with_tires * 3
            ELSE 0
        END AS additional_top_10_incentive
    FROM
        dealers_incentives
)
SELECT
    da.dealernumber AS dealer_number,
    da.dealername AS dealer_name,
    month_of_eligibility,
    region AS dealer_region,
    date_trunc(
        'month',
        to_date(month_of_eligibility, 'YYYY Month')
    ) :: date AS from_period,
    (
        date_trunc(
            'month',
            to_date(month_of_eligibility, 'YYYY Month')
        ) + INTERVAL '1 month' - INTERVAL '1 day'
    ) :: date AS to_period,
    1 AS compute_period,
    (
        parts_incentive + tires_incentive + additional_incentive + additional_top_10_incentive
    ) AS total_incentive
FROM
    dealers_with_additional_incentives da
LIMIT
    5;

--  QUERY EXECUTION PLAN 
-- "Limit  (cost=11134078.25..11136926.65 rows=20 width=71) (actual time=155883.331..162326.372 rows=20 loops=1)"
-- "  CTE sales_base"
-- "    ->  Gather  (cost=16994.50..3294268.05 rows=8511133 width=245) (actual time=20434.619..24483.601 rows=53292278 loops=1)"
-- "          Workers Planned: 2"
-- "          Workers Launched: 2"
-- "          ->  Parallel Hash Join  (cost=15994.50..2442154.75 rows=3546305 width=245) (actual time=20412.253..36891.920 rows=17764093 loops=3)"
-- "                Hash Cond: (s.part_number = p.part_number)"
-- "                ->  Hash Join  (cost=1689.73..2049328.40 rows=2715140 width=91) (actual time=17.454..15392.526 rows=12787546 loops=3)"
-- "                      Hash Cond: ((s.dealernumber = e_1.dealernumber) AND (to_char((s.calendardate)::timestamp with time zone, 'YYYYMM'::text) = o.month))"
-- "                      ->  Parallel Seq Scan on sales s  (cost=0.00..579826.32 rows=19389832 width=30) (actual time=0.303..2092.795 rows=15508066 loops=3)"
-- "                      ->  Hash  (cost=1198.46..1198.46 rows=32751 width=80) (actual time=16.900..16.905 rows=32751 loops=3)"
-- "                            Buckets: 32768  Batches: 1  Memory Usage: 3901kB"
-- "                            ->  Hash Join  (cost=76.63..1198.46 rows=32751 width=80) (actual time=0.622..8.124 rows=32751 loops=3)"
-- "                                  Hash Cond: (o.dealer = e_1.dealernumber)"
-- "                                  ->  Seq Scan on objectives o  (cost=0.00..671.51 rows=32751 width=50) (actual time=0.023..1.741 rows=32751 loops=3)"
-- "                                  ->  Hash  (cost=47.39..47.39 rows=2339 width=30) (actual time=0.578..0.579 rows=2339 loops=3)"
-- "                                        Buckets: 4096  Batches: 1  Memory Usage: 176kB"
-- "                                        ->  Seq Scan on entity e_1  (cost=0.00..47.39 rows=2339 width=30) (actual time=0.042..0.241 rows=2339 loops=3)"
-- "                ->  Parallel Hash  (cost=9247.45..9247.45 rows=237545 width=41) (actual time=471.225..471.226 rows=190036 loops=3)"
-- "                      Buckets: 131072  Batches: 8  Memory Usage: 6592kB"
-- "                      ->  Parallel Seq Scan on parts p  (cost=0.00..9247.45 rows=237545 width=41) (actual time=261.306..285.255 rows=190036 loops=3)"
-- "  ->  Merge Join  (cost=7839810.20..10132772.91 rows=16100 width=71) (actual time=154871.624..161277.992 rows=20 loops=1)"
-- "        Merge Cond: ((parts_tires_sales.dealernumber = combined_dealer.dealernumber) AND ((to_char((parts_tires_sales.calendardate)::timestamp with time zone, 'YYYY FMMonth'::text)) = ed.month_of_eligibility))"
-- "        ->  Unique  (cost=4344752.18..6624424.83 rows=851113 width=100) (actual time=107760.029..114203.317 rows=74 loops=1)"
-- "              ->  Incremental Sort  (cost=4344752.18..6539313.50 rows=8511133 width=100) (actual time=107760.026..113851.407 rows=2518351 loops=1)"
-- "                    Sort Key: parts_tires_sales.dealernumber, (to_char((parts_tires_sales.calendardate)::timestamp with time zone, 'YYYY FMMonth'::text)), (CASE WHEN (parts_tires_sales.total_sales_without_tires < (0.9 * parts_tires_sales.sales_obj)) THEN '0'::numeric WHEN ((parts_tires_sales.total_sales_without_tires >= (0.9 * parts_tires_sales.sales_obj)) AND (parts_tires_sales.total_sales_without_tires < parts_tires_sales.sales_obj)) THEN (0.05 * parts_tires_sales.total_sales_without_tires) WHEN ((parts_tires_sales.total_sales_without_tires >= parts_tires_sales.sales_obj) AND (parts_tires_sales.total_sales_without_tires <= (1.25 * parts_tires_sales.sales_obj))) THEN ((0.05 * parts_tires_sales.total_sales_without_tires) + (0.06 * (parts_tires_sales.total_sales_without_tires - parts_tires_sales.sales_obj))) ELSE (((0.05 * parts_tires_sales.total_sales_without_tires) + (0.06 * (parts_tires_sales.total_sales_without_tires - parts_tires_sales.sales_obj))) + (0.07 * (parts_tires_sales.total_sales_without_tires - (1.25 * parts_tires_sales.sales_obj)))) END), (CASE WHEN ((parts_tires_sales.total_sales_with_tires)::numeric >= parts_tires_sales.tires_tier_3_obj) THEN 250 WHEN ((parts_tires_sales.total_sales_with_tires)::numeric >= parts_tires_sales.tires_tier_2_obj) THEN 150 WHEN ((parts_tires_sales.total_sales_with_tires)::numeric >= parts_tires_sales.tires_tier_1_obj) THEN 100 ELSE 0 END)"
-- "                    Presorted Key: parts_tires_sales.dealernumber"
-- "                    Full-sort Groups: 7  Sort Method: quicksort  Average Memory: 29kB  Peak Memory: 29kB"
-- "                    Pre-sorted Groups: 7  Sort Method: external merge  Average Disk: 25985kB  Peak Disk: 26840kB"
-- "                    ->  Subquery Scan on parts_tires_sales  (cost=4334258.87..5313039.17 rows=8511133 width=100) (actual time=106304.250..112621.640 rows=2737788 loops=1)"
-- "                          ->  WindowAgg  (cost=4334258.87..4610870.70 rows=8511133 width=268) (actual time=106304.231..109082.720 rows=2737788 loops=1)"
-- "                                ->  Sort  (cost=4334258.87..4355536.71 rows=8511133 width=264) (actual time=106268.401..106682.941 rows=2772902 loops=1)"
-- "                                      Sort Key: sales_base.dealernumber, (to_char((sales_base.calendardate)::timestamp with time zone, 'YYYY FMMonth'::text))"
-- "                                      Sort Method: external merge  Disk: 4517136kB"
-- "                                      ->  CTE Scan on sales_base  (cost=0.00..212778.33 rows=8511133 width=264) (actual time=20434.633..46930.291 rows=53292278 loops=1)"
-- "        ->  Sort  (cost=3495058.01..3495059.91 rows=757 width=115) (actual time=47074.367..47074.403 rows=20 loops=1)"
-- "              Sort Key: combined_dealer.dealernumber, ed.month_of_eligibility"
-- "              Sort Method: quicksort  Memory: 59kB"
-- "              ->  Merge Join  (cost=3484903.02..3495021.81 rows=757 width=115) (actual time=47001.151..47074.032 rows=439 loops=1)"
-- "                    Merge Cond: (combined_dealer.month_of_sale = ed.month_of_eligibility)"
-- "                    Join Filter: (TRIM(BOTH FROM ed.dealer) = combined_dealer.dealernumber)"
-- "                    Rows Removed by Join Filter: 497289"
-- "                    ->  Sort  (cost=3482421.42..3483603.52 rows=472841 width=180) (actual time=46946.028..46946.065 rows=828 loops=1)"
-- "                          Sort Key: combined_dealer.month_of_sale, combined_dealer.region, combined_dealer.total_sales DESC"
-- "                          Sort Method: quicksort  Memory: 84kB"
-- "                          ->  Subquery Scan on combined_dealer  (cost=3318348.76..3353811.80 rows=472841 width=180) (actual time=46944.490..46945.225 rows=828 loops=1)"
-- "                                Filter: ((combined_dealer.sales_rank <= 5) OR (combined_dealer.tires_rank <= 10))"
-- "                                Rows Removed by Filter: 750"
-- "                                ->  WindowAgg  (cost=3318348.76..3337498.80 rows=851113 width=184) (actual time=46944.484..46945.143 rows=1578 loops=1)"
-- "                                      ->  Sort  (cost=3318348.76..3320476.54 rows=851113 width=176) (actual time=46944.476..46944.528 rows=1578 loops=1)"
-- "                                            Sort Key: sales_base_1.region, sales_base_1.month_of_sale, (sum(sales_base_1.value) FILTER (WHERE (sales_base_1.part_category_2 !~~* '%tires%'::text))) DESC"
-- "                                            Sort Method: quicksort  Memory: 198kB"
-- "                                            ->  WindowAgg  (cost=3072036.16..3089058.42 rows=851113 width=176) (actual time=46941.917..46942.248 rows=1578 loops=1)"
-- "                                                  ->  Sort  (cost=3072036.16..3074163.94 rows=851113 width=168) (actual time=46941.903..46941.954 rows=1578 loops=1)"
-- "                                                        Sort Key: sales_base_1.month_of_sale, (sum(sales_base_1.units) FILTER (WHERE (sales_base_1.part_category_2 ~~* '%tires%'::text))) DESC"
-- "                                                        Sort Method: quicksort  Memory: 185kB"
-- "                                                        ->  HashAggregate  (cost=2372478.32..2848569.82 rows=851113 width=168) (actual time=46940.297..46940.594 rows=1578 loops=1)"
-- "                                                              Group Key: sales_base_1.region, sales_base_1.dealernumber, sales_base_1.dealername, sales_base_1.month_of_sale"
-- "                                                              Planned Partitions: 64  Batches: 1  Memory Usage: 1169kB"
-- "                                                              ->  CTE Scan on sales_base sales_base_1  (cost=0.00..170222.66 rows=8511133 width=196) (actual time=0.022..4560.633 rows=53292278 loops=1)"
-- "                    ->  Sort  (cost=2481.60..2481.76 rows=64 width=39) (actual time=55.060..68.162 rows=497719 loops=1)"
-- "                          Sort Key: ed.month_of_eligibility"
-- "                          Sort Method: quicksort  Memory: 1108kB"
-- "                          ->  Subquery Scan on ed  (cost=1780.41..2479.68 rows=64 width=39) (actual time=25.150..52.037 rows=15740 loops=1)"
-- "                                Filter: (ed.eligibility = 'ELIGIBLE'::text)"
-- "                                Rows Removed by Filter: 11474"
-- "                                ->  WindowAgg  (cost=1780.41..2320.75 rows=12714 width=86) (actual time=25.144..50.629 rows=27214 loops=1)"
-- "                                      ->  Sort  (cost=1780.41..1812.19 rows=12714 width=43) (actual time=25.032..27.245 rows=27214 loops=1)"
-- "                                            Sort Key: e.region, pe.month"
-- "                                            Sort Method: quicksort  Memory: 2682kB"
-- "                                            ->  Hash Join  (cost=60.69..913.69 rows=12714 width=43) (actual time=0.303..10.590 rows=27214 loops=1)"
-- "                                                  Hash Cond: (TRIM(BOTH FROM pe.dealer) = e.dealernumber)"
-- "                                                  ->  Seq Scan on penetration pe  (cost=0.00..586.11 rows=27949 width=37) (actual time=0.024..3.542 rows=28085 loops=1)"
-- "                                                        Filter: (TRIM(BOTH FROM dealer) IS NOT NULL)"
-- "                                                        Rows Removed by Filter: 4"
-- "                                                  ->  Hash  (cost=47.39..47.39 rows=1064 width=12) (actual time=0.261..0.264 rows=1064 loops=1)"
-- "                                                        Buckets: 2048  Batches: 1  Memory Usage: 63kB"
-- "                                                        ->  Seq Scan on entity e  (cost=0.00..47.39 rows=1064 width=12) (actual time=0.008..0.147 rows=1064 loops=1)"
-- "                                                              Filter: (terminationdate IS NULL)"
-- "                                                              Rows Removed by Filter: 1275"
-- "Planning Time: 2.442 ms"
-- "JIT:"
-- "  Functions: 168"
-- "  Options: Inlining true, Optimization true, Expressions true, Deforming true"
-- "  Timing: Generation 14.130 ms, Inlining 133.169 ms, Optimization 897.671 ms, Emission 764.887 ms, Total 1809.858 ms"
-- "Execution Time: 162716.635 ms"