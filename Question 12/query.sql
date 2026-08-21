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
    'JOSH_CLEAN_AUTOMOBILES' AS nation,
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
-- "WindowAgg  (cost=265907.39..265939.16 rows=1059 width=210) (actual time=76412.290..76412.546 rows=830 loops=1)"
-- "  ->  WindowAgg  (cost=265907.39..265925.93 rows=1059 width=178) (actual time=76410.594..76411.588 rows=830 loops=1)"
-- "        ->  Sort  (cost=265907.39..265910.04 rows=1059 width=146) (actual time=76410.390..76410.492 rows=830 loops=1)"
-- "              Sort Key: total_incentive_for_dealers.dealer_region"
-- "              Sort Method: quicksort  Memory: 107kB"
-- "              ->  Subquery Scan on total_incentive_for_dealers  (cost=265666.22..265854.19 rows=1059 width=146) (actual time=76400.611..76409.799 rows=830 loops=1)"
-- "                    ->  Limit  (cost=265666.22..265843.60 rows=1059 width=146) (actual time=76400.597..76409.562 rows=830 loops=1)"
-- "                          ->  Subquery Scan on dealers_ranks  (cost=265666.22..265843.60 rows=1059 width=146) (actual time=76338.421..76347.268 rows=830 loops=1)"
-- "                                ->  WindowAgg  (cost=265666.22..265711.22 rows=1059 width=286) (actual time=76338.327..76340.741 rows=830 loops=1)"
-- "                                      ->  Sort  (cost=265666.22..265668.86 rows=1059 width=187) (actual time=76338.279..76338.458 rows=830 loops=1)"
-- "                                            Sort Key: (max(ed.region)), ed.month_of_eligibility, (sum(s.value) FILTER (WHERE (p.part_category_2 !~~* '%tires%'::text))) DESC"
-- "                                            Sort Method: quicksort  Memory: 137kB"
-- "                                            ->  WindowAgg  (cost=265591.83..265613.01 rows=1059 width=187) (actual time=76333.837..76334.707 rows=830 loops=1)"
-- "                                                  ->  Sort  (cost=265591.83..265594.48 rows=1059 width=179) (actual time=76333.751..76333.871 rows=830 loops=1)"
-- "                                                        Sort Key: ed.month_of_eligibility, (sum(s.units) FILTER (WHERE (p.part_category_2 ~~* '%tires%'::text))) DESC"
-- "                                                        Sort Method: quicksort  Memory: 130kB"
-- "                                                        ->  Nested Loop  (cost=261051.34..265538.62 rows=1059 width=179) (actual time=76299.199..76330.777 rows=830 loops=1)"
-- "                                                              ->  HashAggregate  (cost=261051.05..261145.23 rows=7535 width=146) (actual time=76298.544..76300.342 rows=830 loops=1)"
-- "                                                                    Group Key: s.dealernumber, ed.month_of_eligibility"
-- "                                                                    Batches: 1  Memory Usage: 913kB"
-- "                                                                    ->  Nested Loop  (cost=1781.41..214320.71 rows=2076904 width=87) (actual time=73.600..37312.325 rows=28095649 loops=1)"
-- "                                                                          ->  Nested Loop  (cost=1780.98..148212.58 rows=1654194 width=87) (actual time=73.065..8814.581 rows=20242353 loops=1)"
-- "                                                                                ->  Subquery Scan on ed  (cost=1780.41..2511.46 rows=64 width=66) (actual time=68.639..166.350 rows=15740 loops=1)"
-- "                                                                                      Filter: (ed.eligibility = 'ELIGIBLE'::text)"
-- "                                                                                      Rows Removed by Filter: 11474"
-- "                                                                                      ->  WindowAgg  (cost=1780.41..2352.54 rows=12714 width=107) (actual time=68.630..161.339 rows=27214 loops=1)"
-- "                                                                                            ->  Sort  (cost=1780.41..1812.19 rows=12714 width=60) (actual time=68.262..74.341 rows=27214 loops=1)"
-- "                                                                                                  Sort Key: e.region, pe.month"
-- "                                                                                                  Sort Method: quicksort  Memory: 3147kB"
-- "                                                                                                  ->  Hash Join  (cost=60.69..913.69 rows=12714 width=60) (actual time=3.555..29.541 rows=27214 loops=1)"
-- "                                                                                                        Hash Cond: (TRIM(BOTH FROM pe.dealer) = e.dealernumber)"
-- "                                                                                                        ->  Seq Scan on penetration pe  (cost=0.00..586.11 rows=27949 width=37) (actual time=1.298..11.391 rows=28085 loops=1)"
-- "                                                                                                              Filter: (TRIM(BOTH FROM dealer) IS NOT NULL)"
-- "                                                                                                              Rows Removed by Filter: 4"
-- "                                                                                                        ->  Hash  (cost=47.39..47.39 rows=1064 width=30) (actual time=2.203..2.206 rows=1064 loops=1)"
-- "                                                                                                              Buckets: 2048  Batches: 1  Memory Usage: 82kB"
-- "                                                                                                              ->  Seq Scan on entity e  (cost=0.00..47.39 rows=1064 width=30) (actual time=0.332..1.783 rows=1064 loops=1)"
-- "                                                                                                                    Filter: (terminationdate IS NULL)"
-- "                                                                                                                    Rows Removed by Filter: 1275"
-- "                                                                                ->  Index Only Scan using idx_sales_cover on sales s  (cost=0.57..1899.25 rows=37733 width=31) (actual time=0.024..0.412 rows=1286 loops=15740)"
-- "                                                                                      Index Cond: ((dealernumber = TRIM(BOTH FROM ed.dealer)) AND (calendardate >= ed.month_start) AND (calendardate < (ed.month_start + '1 mon'::interval)))"
-- "                                                                                      Heap Fetches: 0"
-- "                                                                          ->  Memoize  (cost=0.43..0.45 rows=1 width=21) (actual time=0.001..0.001 rows=1 loops=20242353)"
-- "                                                                                Cache Key: s.part_number"
-- "                                                                                Cache Mode: logical"
-- "                                                                                Hits: 19684716  Misses: 557637  Evictions: 0  Overflows: 0  Memory Usage: 71192kB"
-- "                                                                                ->  Index Only Scan using idx_parts_cover on parts p  (cost=0.42..0.44 rows=1 width=21) (actual time=0.008..0.008 rows=1 loops=557637)"
-- "                                                                                      Index Cond: (part_number = s.part_number)"
-- "                                                                                      Heap Fetches: 0"
-- "                                                              ->  Index Scan using idx_objectives_dealer_month on objectives o  (cost=0.29..0.56 rows=1 width=50) (actual time=0.033..0.034 rows=1 loops=830)"
-- "                                                                    Index Cond: ((dealer = s.dealernumber) AND (month = to_char(((max(s.calendardate)))::timestamp with time zone, 'YYYYMM'::text)))"
-- "Planning Time: 12.466 ms"
-- "JIT:"
-- "  Functions: 64"
-- "  Options: Inlining false, Optimization false, Expressions true, Deforming true"
-- "  Timing: Generation 8.246 ms, Inlining 0.000 ms, Optimization 4.314 ms, Emission 58.356 ms, Total 70.916 ms"
-- "Execution Time: 76468.194 ms"