-- Q6 Parts Incentive: Calculate Parts Incentives for each dealership: (Excluding Tires)
--                     Tier 1: $0
--                     Tier 2: 5% of Sales
--                     Tier 3: Tier 2 Incentive + 6% additional incentive on sales above 100% of objectives
--                     Tier 4: Tier 3 Incentive + 7 % additional incentive on sales above 125% of objectives
-- cost time = 1m 4s
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
    to_char(s.calendardate :: date, 'YYYY FMMonth');

-- query with format output 
SELECT
    'JOSH_CLEAN_AUTOMOBILES' AS nation,
    date_trunc('month', s.calendardate) :: date AS from_period,
    (
        date_trunc('month', s.calendardate) + INTERVAL '1 month' - INTERVAL '1 day'
    ) :: date AS to_period,
    1 AS compute_period,
    s.dealernumber AS dealer,
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
    to_char(s.calendardate :: date, 'YYYY FMMonth'),
    date_trunc('month', s.calendardate);

-- EXPLAIN ANALYSE QUERY PLAN 
-- "Finalize HashAggregate  (cost=2113262.11..3197907.73 rows=8034412 width=141) (actual time=22216.279..22242.860 rows=1578 loops=1)"
-- "  Group Key: s.dealernumber, o.sales_obj, (to_char((s.calendardate)::timestamp with time zone, 'YYYY FMMonth'::text)), (date_trunc('month'::text, (s.calendardate)::timestamp with time zone))"
-- "  Batches: 1  Memory Usage: 394257kB"
-- "  ->  Gather  (cost=1267974.93..2012831.95 rows=6695344 width=101) (actual time=22196.880..22212.573 rows=4734 loops=1)"
-- "        Workers Planned: 2"
-- "        Workers Launched: 2"
-- "        ->  Partial HashAggregate  (cost=1266974.93..1342297.55 rows=3347672 width=101) (actual time=22150.233..22161.878 rows=1578 loops=3)"
-- "              Group Key: s.dealernumber, o.sales_obj, to_char((s.calendardate)::timestamp with time zone, 'YYYY FMMonth'::text), date_trunc('month'::text, (s.calendardate)::timestamp with time zone)"
-- "              Batches: 1  Memory Usage: 99345kB"
-- "              Worker 0:  Batches: 1  Memory Usage: 99345kB"
-- "              Worker 1:  Batches: 1  Memory Usage: 99345kB"
-- "              ->  Nested Loop  (cost=0.74..1225129.03 rows=3347672 width=75) (actual time=242.086..17723.225 rows=17536387 loops=3)"
-- "                    ->  Nested Loop  (cost=0.30..1098874.71 rows=2715382 width=46) (actual time=241.966..8911.928 rows=12787546 loops=3)"
-- "                          ->  Parallel Seq Scan on sales s  (cost=0.00..579778.82 rows=19385082 width=27) (actual time=0.017..1008.076 rows=15508066 loops=3)"
-- "                          ->  Memoize  (cost=0.30..0.32 rows=1 width=32) (actual time=0.000..0.000 rows=1 loops=46524197)"
-- "                                Cache Key: s.dealernumber, to_char((s.calendardate)::timestamp with time zone, 'YYYYMM'::text)"
-- "                                Cache Mode: logical"
-- "                                Hits: 17659362  Misses: 1899  Evictions: 0  Overflows: 0  Memory Usage: 243kB"
-- "                                Worker 0:  Hits: 14821441  Misses: 1899  Evictions: 0  Overflows: 0  Memory Usage: 243kB"
-- "                                Worker 1:  Hits: 14037697  Misses: 1899  Evictions: 0  Overflows: 0  Memory Usage: 243kB"
-- "                                ->  Index Scan using idx_objectives_dealer_month on objectives o  (cost=0.29..0.31 rows=1 width=32) (actual time=0.004..0.004 rows=1 loops=5697)"
-- "                                      Index Cond: ((dealer = s.dealernumber) AND (month = to_char((s.calendardate)::timestamp with time zone, 'YYYYMM'::text)))"
-- "                    ->  Memoize  (cost=0.43..0.46 rows=1 width=10) (actual time=0.000..0.000 rows=1 loops=38362638)"
-- "                          Cache Key: s.part_number"
-- "                          Cache Mode: logical"
-- "                          Hits: 14352026  Misses: 213181  Evictions: 0  Overflows: 0  Memory Usage: 24586kB"
-- "                          Worker 0:  Hits: 12045125  Misses: 177018  Evictions: 0  Overflows: 0  Memory Usage: 20516kB"
-- "                          Worker 1:  Hits: 11406013  Misses: 169275  Evictions: 0  Overflows: 0  Memory Usage: 19524kB"
-- "                          ->  Index Only Scan using idx_parts_cover on parts p  (cost=0.42..0.45 rows=1 width=10) (actual time=0.003..0.003 rows=1 loops=559474)"
-- "                                Index Cond: (part_number = s.part_number)"
-- "                                Filter: (part_category_2 !~~* '%tires%'::text)"
-- "                                Rows Removed by Filter: 0"
-- "                                Heap Fetches: 0"
-- "Planning Time: 1.117 ms"
-- "JIT:"
-- "  Functions: 79"
-- "  Options: Inlining true, Optimization true, Expressions true, Deforming true"
-- "  Timing: Generation 6.042 ms, Inlining 167.849 ms, Optimization 289.631 ms, Emission 267.957 ms, Total 731.478 ms"
-- "Execution Time: 22452.263 ms"