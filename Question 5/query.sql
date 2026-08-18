-- Q5 -> Calculate Parts Tier for each dealership: (Excluding Tires)
--          a. Tier 1: If Sales < 90% of Objective
--          b. Tier 2: If 90% of objective <= Sales < 100% of objective
--          c.  Tier 3: If 100% of objective <= Sales <= 125% of objective
--          d. Tier 4: If Monthly Sales > 125% of objective
--cost time = 54.5s
SELECT
    s.dealernumber,
    to_char(s.calendardate :: date, 'YYYY FMMonth') AS month_of_sale,
    CASE
        WHEN SUM(s.value) < (0.9 * o.sales_obj :: numeric) THEN 'Tier 1'
        WHEN SUM(s.value) >= (0.9 * o.sales_obj :: numeric)
        AND (SUM(s.value) < o.sales_obj :: numeric) THEN 'Tier 2'
        WHEN SUM(s.value) >= o.sales_obj :: numeric
        AND SUM(s.value) <= (1.25 * o.sales_obj :: numeric) THEN 'Tier 3'
        ELSE 'Tier 4'
    END AS tier_level
FROM
    sales s
    INNER JOIN objectives o ON s.dealernumber = o.dealer
    AND to_char(s.calendardate :: date, 'YYYYMM') = o.month
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
    to_char(s.calendardate :: date, 'YYYY FMMonth') AS month_of_sale,
    CASE
        WHEN SUM(s.value) < (0.9 * o.sales_obj :: numeric) THEN 'Tier 1'
        WHEN SUM(s.value) >= (0.9 * o.sales_obj :: numeric)
        AND (SUM(s.value) < o.sales_obj :: numeric) THEN 'Tier 2'
        WHEN SUM(s.value) >= o.sales_obj :: numeric
        AND SUM(s.value) <= (1.25 * o.sales_obj :: numeric) THEN 'Tier 3'
        ELSE 'Tier 4'
    END AS tier_level
FROM
    sales s
    INNER JOIN objectives o ON s.dealernumber = o.dealer
    AND to_char(s.calendardate :: date, 'YYYYMM') = o.month
    INNER JOIN parts p ON s.part_number = p.part_number
WHERE
    p.part_category_2 NOT ILIKE '%tires%'
GROUP BY
    s.dealernumber,
    o.sales_obj,
    to_char(s.calendardate :: date, 'YYYY FMMonth'),
    date_trunc('month', s.calendardate);

-- QUERY EXECUTION PLAN 
-- "Finalize GroupAggregate  (cost=4898795.73..6668988.68 rows=8357365 width=141) (actual time=61411.618..70618.939 rows=1578 loops=1)"
-- "  Group Key: s.dealernumber, o.sales_obj, (to_char((s.calendardate)::timestamp with time zone, 'YYYY FMMonth'::text)), (date_trunc('month'::text, (s.calendardate)::timestamp with time zone))"
-- "  ->  Gather Merge  (cost=4898795.73..5833252.19 rows=6964470 width=101) (actual time=61404.618..70602.128 rows=4734 loops=1)"
-- "        Workers Planned: 2"
-- "        Workers Launched: 2"
-- "        ->  Partial GroupAggregate  (cost=4897795.71..5028379.52 rows=3482235 width=101) (actual time=60348.107..68312.621 rows=1578 loops=3)"
-- "              Group Key: s.dealernumber, o.sales_obj, (to_char((s.calendardate)::timestamp with time zone, 'YYYY FMMonth'::text)), (date_trunc('month'::text, (s.calendardate)::timestamp with time zone))"
-- "              ->  Sort  (cost=4897795.71..4906501.30 rows=3482235 width=75) (actual time=60343.452..65345.088 rows=17536387 loops=3)"
-- "                    Sort Key: s.dealernumber, o.sales_obj, (to_char((s.calendardate)::timestamp with time zone, 'YYYY FMMonth'::text)), (date_trunc('month'::text, (s.calendardate)::timestamp with time zone))"
-- "                    Sort Method: external merge  Disk: 1057824kB"
-- "                    Worker 0:  Sort Method: external merge  Disk: 1234256kB"
-- "                    Worker 1:  Sort Method: external merge  Disk: 1285240kB"
-- "                    ->  Parallel Hash Join  (cost=15058.77..4209960.33 rows=3482235 width=75) (actual time=17598.587..28160.816 rows=17536387 loops=3)"
-- "                          Hash Cond: (s.part_number = p.part_number)"
-- "                          ->  Hash Join  (cost=1162.78..3904411.93 rows=2715140 width=45) (actual time=16.911..13419.158 rows=12787546 loops=3)"
-- "                                Hash Cond: ((s.dealernumber = o.dealer) AND (to_char((s.calendardate)::timestamp with time zone, 'YYYYMM'::text) = o.month))"
-- "                                ->  Parallel Seq Scan on sales s  (cost=0.00..579826.32 rows=19389832 width=26) (actual time=0.073..1346.755 rows=15508066 loops=3)"
-- "                                ->  Hash  (cost=671.51..671.51 rows=32751 width=32) (actual time=16.461..16.463 rows=32751 loops=3)"
-- "                                      Buckets: 32768  Batches: 1  Memory Usage: 2332kB"
-- "                                      ->  Seq Scan on objectives o  (cost=0.00..671.51 rows=32751 width=32) (actual time=0.074..4.951 rows=32751 loops=3)"
-- "                          ->  Parallel Hash  (cost=9841.32..9841.32 rows=233254 width=10) (actual time=695.527..695.529 rows=186659 loops=3)"
-- "                                Buckets: 262144  Batches: 8  Memory Usage: 5376kB"
-- "                                ->  Parallel Seq Scan on parts p  (cost=0.00..9841.32 rows=233254 width=10) (actual time=491.388..609.278 rows=186659 loops=3)"
-- "                                      Filter: (part_category_2 !~~* '%tires%'::text)"
-- "                                      Rows Removed by Filter: 3378"
-- "Planning Time: 1.018 ms"
-- "JIT:"
-- "  Functions: 87"
-- "  Options: Inlining true, Optimization true, Expressions true, Deforming true"
-- "  Timing: Generation 9.280 ms, Inlining 312.595 ms, Optimization 715.212 ms, Emission 446.499 ms, Total 1483.586 ms"
-- "Execution Time: 70737.206 ms"