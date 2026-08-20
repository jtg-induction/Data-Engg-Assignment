--cost time = 2m 15s
WITH eligible_dealers AS (
    SELECT
        e.dealernumber AS dealer,
        e.region,
        e.dealername,
        to_char(to_date(pe.month, 'MM YYYY'), 'YYYY FMMonth') AS month_of_eligibility,
        to_date(pe.month, 'MM YYYY') AS month_start,
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
sales_monthly AS (
    SELECT
        s.dealernumber,
        ed.month_of_eligibility,
        MAX(ed.region) AS region,
        MAX(ed.dealername) AS dealername,
        MAX(s.calendardate) AS calendardate,
        SUM(s.value) FILTER (
            WHERE
                p.part_category_2 NOT ILIKE '%tires%'
        ) AS dealer_sales_without_tires,
        SUM(s.units) FILTER (
            WHERE
                p.part_category_2 ILIKE '%tires%'
        ) AS dealer_sales_with_tires
    FROM
        eligible_dealers ed
        JOIN sales s ON trim(ed.dealer) = s.dealernumber
        AND s.calendardate >= ed.month_start
        AND s.calendardate < ed.month_start + INTERVAL '1 month'
        JOIN parts p ON s.part_number = p.part_number
    WHERE
        ed.eligibility = 'ELIGIBLE'
    GROUP BY
        s.dealernumber,
        ed.month_of_eligibility
),
eligible_dealers_data AS (
    SELECT
        sm.dealernumber,
        sm.dealer_sales_without_tires,
        sm.dealer_sales_with_tires,
        sm.region,
        sm.dealername,
        o.sales_obj :: NUMERIC AS sales_obj,
        o.tires_tier_1_obj :: NUMERIC AS tires_tier_1_obj,
        o.tires_tier_2_obj :: NUMERIC AS tires_tier_2_obj,
        o.tires_tier_3_obj :: NUMERIC AS tires_tier_3_obj,
        sm.month_of_eligibility
    FROM
        sales_monthly sm
        INNER JOIN objectives o ON sm.dealernumber = o.dealer
        AND o.month = to_char(sm.calendardate :: date, 'YYYYMM')
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
        eligible_dealers_data
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
),
total_incentive_for_dealers AS (
    SELECT
        da.dealernumber AS dealer_number,
        da.dealername AS dealer_name,
        month_of_eligibility,
        da.region AS dealer_region,
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
        1500
)
SELECT
    dealer_number,
    month_of_eligibility,
    dealer_region,
    dealer_name,
    from_period,
    to_period,
    compute_period,
    total_incentive AS total_incentive_for_dealers,
    SUM(total_incentive) OVER(PARTITION BY dealer_region) AS total_incentive_region_wise,
    SUM(total_incentive) OVER() AS total_incentive_for_nation
FROM
    total_incentive_for_dealers;

-- QUERY EXECUTION PLAN 
-- "Limit  (cost=13427924.43..13427926.43 rows=20 width=211) (actual time=474820.553..474842.473 rows=20 loops=1)"
-- "  CTE sales_base"
-- "    ->  Gather  (cost=16994.50..3294268.05 rows=8511133 width=245) (actual time=23994.580..41380.696 rows=53292278 loops=1)"
-- "          Workers Planned: 2"
-- "          Workers Launched: 2"
-- "          ->  Parallel Hash Join  (cost=15994.50..2442154.75 rows=3546305 width=245) (actual time=23959.175..61906.748 rows=17764093 loops=3)"
-- "                Hash Cond: (s.part_number = p.part_number)"
-- "                ->  Hash Join  (cost=1689.73..2049328.40 rows=2715140 width=91) (actual time=37.503..17698.810 rows=12787546 loops=3)"
-- "                      Hash Cond: ((s.dealernumber = e_1.dealernumber) AND (to_char((s.calendardate)::timestamp with time zone, 'YYYYMM'::text) = o.month))"
-- "                      ->  Parallel Seq Scan on sales s  (cost=0.00..579826.32 rows=19389832 width=30) (actual time=0.472..2108.024 rows=15508066 loops=3)"
-- "                      ->  Hash  (cost=1198.46..1198.46 rows=32751 width=80) (actual time=36.670..36.675 rows=32751 loops=3)"
-- "                            Buckets: 32768  Batches: 1  Memory Usage: 3901kB"
-- "                            ->  Hash Join  (cost=76.63..1198.46 rows=32751 width=80) (actual time=3.234..19.828 rows=32751 loops=3)"
-- "                                  Hash Cond: (o.dealer = e_1.dealernumber)"
-- "                                  ->  Seq Scan on objectives o  (cost=0.00..671.51 rows=32751 width=50) (actual time=0.616..5.873 rows=32751 loops=3)"
-- "                                  ->  Hash  (cost=47.39..47.39 rows=2339 width=30) (actual time=2.566..2.567 rows=2339 loops=3)"
-- "                                        Buckets: 4096  Batches: 1  Memory Usage: 176kB"
-- "                                        ->  Seq Scan on entity e_1  (cost=0.00..47.39 rows=2339 width=30) (actual time=0.564..1.646 rows=2339 loops=3)"
-- "                ->  Parallel Hash  (cost=9247.45..9247.45 rows=237545 width=41) (actual time=795.344..795.345 rows=190036 loops=3)"
-- "                      Buckets: 131072  Batches: 8  Memory Usage: 6592kB"
-- "                      ->  Parallel Seq Scan on parts p  (cost=0.00..9247.45 rows=237545 width=41) (actual time=496.918..527.833 rows=190036 loops=3)"
-- "  ->  WindowAgg  (cost=10133656.38..10135266.38 rows=16100 width=211) (actual time=473079.343..473079.381 rows=20 loops=1)"
-- "        ->  WindowAgg  (cost=10133656.38..10134179.63 rows=16100 width=183) (actual time=473078.992..473079.177 rows=438 loops=1)"
-- "              ->  Sort  (cost=10133656.38..10133696.63 rows=16100 width=151) (actual time=473078.906..473078.935 rows=438 loops=1)"
-- "                    Sort Key: combined_dealer.region"
-- "                    Sort Method: quicksort  Memory: 69kB"
-- "                    ->  Merge Join  (cost=7839810.20..10132531.41 rows=16100 width=151) (actual time=317792.666..473077.900 rows=438 loops=1)"
-- "                          Merge Cond: ((parts_tires_sales.dealernumber = combined_dealer.dealernumber) AND ((to_char((parts_tires_sales.calendardate)::timestamp with time zone, 'YYYY FMMonth'::text)) = ed.month_of_eligibility))"
-- "                          ->  Unique  (cost=4344752.18..6624424.83 rows=851113 width=100) (actual time=249877.999..405192.851 rows=1575 loops=1)"
-- "                                ->  Incremental Sort  (cost=4344752.18..6539313.50 rows=8511133 width=100) (actual time=249877.996..397885.509 rows=53162238 loops=1)"
-- "                                      Sort Key: parts_tires_sales.dealernumber, (to_char((parts_tires_sales.calendardate)::timestamp with time zone, 'YYYY FMMonth'::text)), (CASE WHEN (parts_tires_sales.total_sales_without_tires < (0.9 * parts_tires_sales.sales_obj)) THEN '0'::numeric WHEN ((parts_tires_sales.total_sales_without_tires >= (0.9 * parts_tires_sales.sales_obj)) AND (parts_tires_sales.total_sales_without_tires < parts_tires_sales.sales_obj)) THEN (0.05 * parts_tires_sales.total_sales_without_tires) WHEN ((parts_tires_sales.total_sales_without_tires >= parts_tires_sales.sales_obj) AND (parts_tires_sales.total_sales_without_tires <= (1.25 * parts_tires_sales.sales_obj))) THEN ((0.05 * parts_tires_sales.total_sales_without_tires) + (0.06 * (parts_tires_sales.total_sales_without_tires - parts_tires_sales.sales_obj))) ELSE (((0.05 * parts_tires_sales.total_sales_without_tires) + (0.06 * (parts_tires_sales.total_sales_without_tires - parts_tires_sales.sales_obj))) + (0.07 * (parts_tires_sales.total_sales_without_tires - (1.25 * parts_tires_sales.sales_obj)))) END), (CASE WHEN ((parts_tires_sales.total_sales_with_tires)::numeric >= parts_tires_sales.tires_tier_3_obj) THEN 250 WHEN ((parts_tires_sales.total_sales_with_tires)::numeric >= parts_tires_sales.tires_tier_2_obj) THEN 150 WHEN ((parts_tires_sales.total_sales_with_tires)::numeric >= parts_tires_sales.tires_tier_1_obj) THEN 100 ELSE 0 END)"
-- "                                      Presorted Key: parts_tires_sales.dealernumber"
-- "                                      Full-sort Groups: 138  Sort Method: quicksort  Average Memory: 29kB  Peak Memory: 29kB"
-- "                                      Pre-sorted Groups: 138  Sort Method: external merge  Average Disk: 27600kB  Peak Disk: 27904kB"
-- "                                      ->  Subquery Scan on parts_tires_sales  (cost=4334258.87..5313039.17 rows=8511133 width=100) (actual time=248395.822..374177.994 rows=53197168 loops=1)"
-- "                                            ->  WindowAgg  (cost=4334258.87..4610870.70 rows=8511133 width=268) (actual time=248395.783..311383.957 rows=53197168 loops=1)"
-- "                                                  ->  Sort  (cost=4334258.87..4355536.71 rows=8511133 width=264) (actual time=248339.283..264806.656 rows=53229631 loops=1)"
-- "                                                        Sort Key: sales_base.dealernumber, (to_char((sales_base.calendardate)::timestamp with time zone, 'YYYY FMMonth'::text))"
-- "                                                        Sort Method: external merge  Disk: 4517136kB"
-- "                                                        ->  CTE Scan on sales_base  (cost=0.00..212778.33 rows=8511133 width=264) (actual time=23994.600..79448.413 rows=53292278 loops=1)"
-- "                          ->  Sort  (cost=3495058.01..3495059.91 rows=757 width=179) (actual time=67880.122..67880.605 rows=438 loops=1)"
-- "                                Sort Key: combined_dealer.dealernumber, ed.month_of_eligibility"
-- "                                Sort Method: quicksort  Memory: 70kB"
-- "                                ->  Merge Join  (cost=3484903.02..3495021.81 rows=757 width=179) (actual time=67819.923..67879.814 rows=438 loops=1)"
-- "                                      Merge Cond: (combined_dealer.month_of_sale = ed.month_of_eligibility)"
-- "                                      Join Filter: (TRIM(BOTH FROM ed.dealer) = combined_dealer.dealernumber)"
-- "                                      Rows Removed by Join Filter: 496671"
-- "                                      ->  Sort  (cost=3482421.42..3483603.52 rows=472841 width=180) (actual time=67773.869..67773.906 rows=827 loops=1)"
-- "                                            Sort Key: combined_dealer.month_of_sale, combined_dealer.region, combined_dealer.total_sales DESC"
-- "                                            Sort Method: quicksort  Memory: 100kB"
-- "                                            ->  Subquery Scan on combined_dealer  (cost=3318348.76..3353811.80 rows=472841 width=180) (actual time=67772.556..67773.190 rows=827 loops=1)"
-- "                                                  Filter: ((combined_dealer.sales_rank <= 5) OR (combined_dealer.tires_rank <= 10))"
-- "                                                  Rows Removed by Filter: 751"
-- "                                                  ->  WindowAgg  (cost=3318348.76..3337498.80 rows=851113 width=184) (actual time=67772.549..67773.121 rows=1578 loops=1)"
-- "                                                        ->  Sort  (cost=3318348.76..3320476.54 rows=851113 width=176) (actual time=67772.520..67772.575 rows=1578 loops=1)"
-- "                                                              Sort Key: sales_base_1.region, sales_base_1.month_of_sale, (sum(sales_base_1.value) FILTER (WHERE (sales_base_1.part_category_2 !~~* '%tires%'::text))) DESC"
-- "                                                              Sort Method: quicksort  Memory: 198kB"
-- "                                                              ->  WindowAgg  (cost=3072036.16..3089058.42 rows=851113 width=176) (actual time=67770.377..67770.655 rows=1578 loops=1)"
-- "                                                                    ->  Sort  (cost=3072036.16..3074163.94 rows=851113 width=168) (actual time=67770.365..67770.408 rows=1578 loops=1)"
-- "                                                                          Sort Key: sales_base_1.month_of_sale, (sum(sales_base_1.units) FILTER (WHERE (sales_base_1.part_category_2 ~~* '%tires%'::text))) DESC"
-- "                                                                          Sort Method: quicksort  Memory: 185kB"
-- "                                                                          ->  HashAggregate  (cost=2372478.32..2848569.82 rows=851113 width=168) (actual time=67768.968..67769.235 rows=1578 loops=1)"
-- "                                                                                Group Key: sales_base_1.region, sales_base_1.dealernumber, sales_base_1.dealername, sales_base_1.month_of_sale"
-- "                                                                                Planned Partitions: 64  Batches: 1  Memory Usage: 1169kB"
-- "                                                                                ->  CTE Scan on sales_base sales_base_1  (cost=0.00..170222.66 rows=8511133 width=196) (actual time=1.936..10786.681 rows=53292278 loops=1)"
-- "                                      ->  Sort  (cost=2481.60..2481.76 rows=64 width=39) (actual time=46.008..56.754 rows=497100 loops=1)"
-- "                                            Sort Key: ed.month_of_eligibility"
-- "                                            Sort Method: quicksort  Memory: 1108kB"
-- "                                            ->  Subquery Scan on ed  (cost=1780.41..2479.68 rows=64 width=39) (actual time=24.020..43.524 rows=15740 loops=1)"
-- "                                                  Filter: (ed.eligibility = 'ELIGIBLE'::text)"
-- "                                                  Rows Removed by Filter: 11474"
-- "                                                  ->  WindowAgg  (cost=1780.41..2320.75 rows=12714 width=86) (actual time=24.015..42.365 rows=27214 loops=1)"
-- "                                                        ->  Sort  (cost=1780.41..1812.19 rows=12714 width=43) (actual time=23.901..24.851 rows=27214 loops=1)"
-- "                                                              Sort Key: e.region, pe.month"
-- "                                                              Sort Method: quicksort  Memory: 2682kB"
-- "                                                              ->  Hash Join  (cost=60.69..913.69 rows=12714 width=43) (actual time=1.032..11.509 rows=27214 loops=1)"
-- "                                                                    Hash Cond: (TRIM(BOTH FROM pe.dealer) = e.dealernumber)"
-- "                                                                    ->  Seq Scan on penetration pe  (cost=0.00..586.11 rows=27949 width=37) (actual time=0.764..5.263 rows=28085 loops=1)"
-- "                                                                          Filter: (TRIM(BOTH FROM dealer) IS NOT NULL)"
-- "                                                                          Rows Removed by Filter: 4"
-- "                                                                    ->  Hash  (cost=47.39..47.39 rows=1064 width=12) (actual time=0.243..0.244 rows=1064 loops=1)"
-- "                                                                          Buckets: 2048  Batches: 1  Memory Usage: 63kB"
-- "                                                                          ->  Seq Scan on entity e  (cost=0.00..47.39 rows=1064 width=12) (actual time=0.014..0.139 rows=1064 loops=1)"
-- "                                                                                Filter: (terminationdate IS NULL)"
-- "                                                                                Rows Removed by Filter: 1275"
-- "Planning Time: 2.868 ms"
-- "JIT:"
-- "  Functions: 177"
-- "  Options: Inlining true, Optimization true, Expressions true, Deforming true"
-- "  Timing: Generation 18.995 ms, Inlining 299.115 ms, Optimization 1623.486 ms, Emission 1309.566 ms, Total 3251.162 ms"
-- "Execution Time: 475069.210 ms"