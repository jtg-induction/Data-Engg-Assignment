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
-- "Finalize GroupAggregate  (cost=4833770.56..6748476.28 rows=8357365 width=89) (actual time=55480.649..61897.163 rows=1578 loops=1)"
-- "  Group Key: s.dealernumber, o.sales_obj, (to_char((s.calendardate)::timestamp with time zone, 'YYYY FMMonth'::text))"
-- "  ->  Gather Merge  (cost=4833770.56..5742110.25 rows=6964470 width=89) (actual time=55477.383..61883.646 rows=4734 loops=1)"
-- "        Workers Planned: 2"
-- "        Workers Launched: 2"
-- "        ->  Partial GroupAggregate  (cost=4832770.53..4937237.58 rows=3482235 width=89) (actual time=54586.473..60373.233 rows=1578 loops=3)"
-- "              Group Key: s.dealernumber, o.sales_obj, (to_char((s.calendardate)::timestamp with time zone, 'YYYY FMMonth'::text))"
-- "              ->  Sort  (cost=4832770.53..4841476.12 rows=3482235 width=63) (actual time=54583.440..57573.093 rows=17536387 loops=3)"
-- "                    Sort Key: s.dealernumber, o.sales_obj, (to_char((s.calendardate)::timestamp with time zone, 'YYYY FMMonth'::text))"
-- "                    Sort Method: external merge  Disk: 985976kB"
-- "                    Worker 0:  Sort Method: external merge  Disk: 1008632kB"
-- "                    Worker 1:  Sort Method: external merge  Disk: 824976kB"
-- "                    ->  Parallel Hash Join  (cost=15058.77..4192549.15 rows=3482235 width=63) (actual time=18592.383..26721.906 rows=17536387 loops=3)"
-- "                          Hash Cond: (s.part_number = p.part_number)"
-- "                          ->  Hash Join  (cost=1162.78..3904411.93 rows=2715140 width=45) (actual time=10.751..14468.546 rows=12787546 loops=3)"
-- "                                Hash Cond: ((s.dealernumber = o.dealer) AND (to_char((s.calendardate)::timestamp with time zone, 'YYYYMM'::text) = o.month))"
-- "                                ->  Parallel Seq Scan on sales s  (cost=0.00..579826.32 rows=19389832 width=26) (actual time=0.116..1472.461 rows=15508066 loops=3)"
-- "                                ->  Hash  (cost=671.51..671.51 rows=32751 width=32) (actual time=10.351..10.353 rows=32751 loops=3)"
-- "                                      Buckets: 32768  Batches: 1  Memory Usage: 2332kB"
-- "                                      ->  Seq Scan on objectives o  (cost=0.00..671.51 rows=32751 width=32) (actual time=0.056..3.031 rows=32751 loops=3)"
-- "                          ->  Parallel Hash  (cost=9841.32..9841.32 rows=233254 width=10) (actual time=614.184..614.186 rows=186659 loops=3)"
-- "                                Buckets: 262144  Batches: 8  Memory Usage: 5376kB"
-- "                                ->  Parallel Seq Scan on parts p  (cost=0.00..9841.32 rows=233254 width=10) (actual time=478.002..576.175 rows=186659 loops=3)"
-- "                                      Filter: (part_category_2 !~~* '%tires%'::text)"
-- "                                      Rows Removed by Filter: 3378"
-- "Planning Time: 2.797 ms"
-- "JIT:"
-- "  Functions: 87"
-- "  Options: Inlining true, Optimization true, Expressions true, Deforming true"
-- "  Timing: Generation 7.676 ms, Inlining 342.151 ms, Optimization 643.597 ms, Emission 448.319 ms, Total 1441.742 ms"
-- "Execution Time: 62013.711 ms"