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

-- query with format output
WITH region_dealer AS(
    SELECT
        e.region,
        s.dealernumber,
        e.dealername,
        to_char(s.calendardate :: date, 'YYYY FMMonth') AS month_of_sales,
        date_trunc('month', s.calendardate) :: date AS from_period,
        (
            date_trunc('month', s.calendardate) + INTERVAL '1 month' - INTERVAL '1 day'
        ) :: date AS to_period,
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
        to_char(s.calendardate :: date, 'YYYY FMMonth'),
        date_trunc('month', s.calendardate)
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
    'JOSH_CLEAN_AUTOMOBILES' AS nation,
    from_period,
    to_period,
    1 AS compute_period,
    region AS dealer_region,
    dealernumber AS dealer_number,
    dealername AS dealer_name,
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

--  QUERY EXECUTION PLAN 
-- "Incremental Sort  (cost=9561523.47..41730889.06 rows=59683064 width=142) (actual time=84678.907..92403.548 rows=703 loops=1)"
-- "  Sort Key: dealer_rank.region, dealer_rank.total_sales DESC"
-- "  Presorted Key: dealer_rank.region"
-- "  Full-sort Groups: 6  Sort Method: quicksort  Average Memory: 32kB  Peak Memory: 32kB"
-- "  Pre-sorted Groups: 6  Sort Method: quicksort  Average Memory: 38kB  Peak Memory: 38kB"
-- "  ->  Subquery Scan on dealer_rank  (cost=9403617.32..31273578.65 rows=59683064 width=142) (actual time=80694.918..92402.478 rows=703 loops=1)"
-- "        ->  WindowAgg  (cost=9403617.32..30676748.01 rows=59683064 width=110) (actual time=80694.913..92402.415 rows=703 loops=1)"
-- "              Run Condition: (dense_rank() OVER (?) <= 5)"
-- "              ->  Incremental Sort  (cost=9403617.32..29483086.73 rows=59683064 width=102) (actual time=80694.854..92401.717 rows=1899 loops=1)"
-- "                    Sort Key: region_dealer.region, region_dealer.month_of_sales, region_dealer.total_sales DESC"
-- "                    Presorted Key: region_dealer.region"
-- "                    Full-sort Groups: 6  Sort Method: quicksort  Average Memory: 30kB  Peak Memory: 30kB"
-- "                    Pre-sorted Groups: 6  Sort Method: quicksort  Average Memory: 49kB  Peak Memory: 49kB"
-- "                    ->  Subquery Scan on region_dealer  (cost=9306464.42..20045676.32 rows=59683064 width=102) (actual time=78782.061..92397.018 rows=1899 loops=1)"
-- "                          ->  Finalize GroupAggregate  (cost=9306464.42..19448845.68 rows=59683064 width=110) (actual time=78782.053..92396.249 rows=1899 loops=1)"
-- "                                Group Key: e.region, s.dealernumber, e.dealername, (to_char((s.calendardate)::timestamp with time zone, 'YYYY FMMonth'::text)), (date_trunc('month'::text, (s.calendardate)::timestamp with time zone))"
-- "                                ->  Gather Merge  (cost=9306464.42..16041937.45 rows=49735886 width=106) (actual time=78766.113..92387.325 rows=5697 loops=1)"
-- "                                      Workers Planned: 2"
-- "                                      Workers Launched: 2"
-- "                                      ->  Partial GroupAggregate  (cost=9305464.39..10300182.11 rows=24867943 width=106) (actual time=77881.580..90822.979 rows=1899 loops=3)"
-- "                                            Group Key: e.region, s.dealernumber, e.dealername, (to_char((s.calendardate)::timestamp with time zone, 'YYYY FMMonth'::text)), (date_trunc('month'::text, (s.calendardate)::timestamp with time zone))"
-- "                                            ->  Sort  (cost=9305464.39..9367634.25 rows=24867943 width=80) (actual time=77874.065..87166.601 rows=21266210 loops=3)"
-- "                                                  Sort Key: e.region, s.dealernumber, e.dealername, (to_char((s.calendardate)::timestamp with time zone, 'YYYY FMMonth'::text)), (date_trunc('month'::text, (s.calendardate)::timestamp with time zone))"
-- "                                                  Sort Method: external merge  Disk: 1567600kB"
-- "                                                  Worker 0:  Sort Method: external merge  Disk: 1622128kB"
-- "                                                  Worker 1:  Sort Method: external merge  Disk: 1586632kB"
-- "                                                  ->  Hash Join  (cost=13972.62..2935789.65 rows=24867943 width=80) (actual time=5252.634..21436.518 rows=21266210 loops=3)"
-- "                                                        Hash Cond: (s.dealernumber = e.dealernumber)"
-- "                                                        ->  Parallel Hash Join  (cost=13895.99..2345099.38 rows=24867943 width=16) (actual time=4760.065..7963.330 rows=21266210 loops=3)"
-- "                                                              Hash Cond: (s.part_number = p.part_number)"
-- "                                                              ->  Parallel Seq Scan on sales s  (cost=0.00..579826.32 rows=19389832 width=26) (actual time=0.108..1583.470 rows=15508066 loops=3)"
-- "                                                              ->  Parallel Hash  (cost=9841.32..9841.32 rows=233254 width=10) (actual time=228.988..228.990 rows=186659 loops=3)"
-- "                                                                    Buckets: 262144  Batches: 8  Memory Usage: 5376kB"
-- "                                                                    ->  Parallel Seq Scan on parts p  (cost=0.00..9841.32 rows=233254 width=10) (actual time=0.135..172.615 rows=186659 loops=3)"
-- "                                                                          Filter: (part_category_2 !~~* '%tires%'::text)"
-- "                                                                          Rows Removed by Filter: 3378"
-- "                                                        ->  Hash  (cost=47.39..47.39 rows=2339 width=30) (actual time=492.438..492.439 rows=2339 loops=3)"
-- "                                                              Buckets: 4096  Batches: 1  Memory Usage: 176kB"
-- "                                                              ->  Seq Scan on entity e  (cost=0.00..47.39 rows=2339 width=30) (actual time=491.107..491.708 rows=2339 loops=3)"
-- "Planning Time: 1.373 ms"
-- "JIT:"
-- "  Functions: 82"
-- "  Options: Inlining true, Optimization true, Expressions true, Deforming true"
-- "  Timing: Generation 8.967 ms, Inlining 350.129 ms, Optimization 658.710 ms, Emission 464.710 ms, Total 1482.515 ms"
-- "Execution Time: 92572.195 ms"