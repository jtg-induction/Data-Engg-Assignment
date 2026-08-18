-- Q8 Dealer Tires Incentive: (Use Tire Units instead of Dollar Values in calculation)
--    If Tier 1 Obj achieved then $100
--    If Tier 2 Obj achieved then $150
--    If Tier 3 Obj achieved then $250
-- cost time = 10.59s
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
    o.tires_tier_3_obj;

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
    o.tires_tier_3_obj,
    date_trunc('month', s.calendardate);

-- QUERY EXECUTION PLAN 
-- "Finalize GroupAggregate  (cost=1127435.82..1153051.95 rows=95321 width=112) (actual time=7909.465..8733.086 rows=1578 loops=1)"
-- "  Group Key: s.dealernumber, (to_char((s.calendardate)::timestamp with time zone, 'YYYY FMMonth'::text)), o.tires_tier_1_obj, o.tires_tier_2_obj, o.tires_tier_3_obj, (date_trunc('month'::text, (s.calendardate)::timestamp with time zone))"
-- "  ->  Gather Merge  (cost=1127435.82..1144989.38 rows=79434 width=76) (actual time=7909.324..8729.589 rows=4732 loops=1)"
-- "        Workers Planned: 2"
-- "        Workers Launched: 2"
-- "        ->  Partial GroupAggregate  (cost=1126435.79..1134820.70 rows=39717 width=76) (actual time=7829.608..8133.730 rows=1577 loops=3)"
-- "              Group Key: s.dealernumber, (to_char((s.calendardate)::timestamp with time zone, 'YYYY FMMonth'::text)), o.tires_tier_1_obj, o.tires_tier_2_obj, o.tires_tier_3_obj, (date_trunc('month'::text, (s.calendardate)::timestamp with time zone))"
-- "              ->  Incremental Sort  (cost=1126435.79..1133331.32 rows=39717 width=72) (actual time=7829.568..8111.121 rows=139881 loops=3)"
-- "                    Sort Key: s.dealernumber, (to_char((s.calendardate)::timestamp with time zone, 'YYYY FMMonth'::text)), o.tires_tier_1_obj, o.tires_tier_2_obj, o.tires_tier_3_obj, (date_trunc('month'::text, (s.calendardate)::timestamp with time zone))"
-- "                    Presorted Key: s.dealernumber"
-- "                    Full-sort Groups: 135  Sort Method: quicksort  Average Memory: 30kB  Peak Memory: 30kB"
-- "                    Pre-sorted Groups: 139  Sort Method: quicksort  Average Memory: 143kB  Peak Memory: 146kB"
-- "                    Worker 0:  Full-sort Groups: 136  Sort Method: quicksort  Average Memory: 30kB  Peak Memory: 30kB"
-- "                      Pre-sorted Groups: 138  Sort Method: quicksort  Average Memory: 188kB  Peak Memory: 190kB"
-- "                    Worker 1:  Full-sort Groups: 136  Sort Method: quicksort  Average Memory: 30kB  Peak Memory: 30kB"
-- "                      Pre-sorted Groups: 138  Sort Method: quicksort  Average Memory: 168kB  Peak Memory: 171kB"
-- "                    ->  Merge Join  (cost=1126389.78..1131213.95 rows=39717 width=72) (actual time=7827.292..7997.505 rows=139881 loops=3)"
-- "                          Merge Cond: ((s.dealernumber = o.dealer) AND ((to_char((s.calendardate)::timestamp with time zone, 'YYYYMM'::text)) = o.month))"
-- "                          ->  Sort  (cost=1123252.65..1123961.74 rows=283636 width=14) (actual time=7760.098..7803.701 rows=169809 loops=3)"
-- "                                Sort Key: s.dealernumber, (to_char((s.calendardate)::timestamp with time zone, 'YYYYMM'::text))"
-- "                                Sort Method: external merge  Disk: 4432kB"
-- "                                Worker 0:  Sort Method: external merge  Disk: 6488kB"
-- "                                Worker 1:  Sort Method: external merge  Disk: 5568kB"
-- "                                ->  Parallel Hash Join  (cost=935812.22..1092716.69 rows=283636 width=14) (actual time=6241.550..7525.528 rows=169809 loops=3)"
-- "                                      Hash Cond: (p.part_number = s.part_number)"
-- "                                      ->  Parallel Seq Scan on parts p  (cost=0.00..9841.32 rows=2660 width=10) (actual time=45.126..104.076 rows=2090 loops=3)"
-- "                                            Filter: (part_category_2 ~~* '%tires%'::text)"
-- "                                            Rows Removed by Filter: 187947"
-- "                                      ->  Parallel Hash  (cost=579826.32..579826.32 rows=19389832 width=24) (actual time=6063.194..6063.196 rows=15508066 loops=3)"
-- "                                            Buckets: 131072  Batches: 512  Memory Usage: 7552kB"
-- "                                            ->  Parallel Seq Scan on sales s  (cost=0.00..579826.32 rows=19389832 width=24) (actual time=592.756..2419.250 rows=15508066 loops=3)"
-- "                          ->  Sort  (cost=3127.71..3209.59 rows=32751 width=31) (actual time=66.978..82.041 rows=170836 loops=3)"
-- "                                Sort Key: o.dealer, o.month"
-- "                                Sort Method: quicksort  Memory: 2560kB"
-- "                                Worker 0:  Sort Method: quicksort  Memory: 2560kB"
-- "                                Worker 1:  Sort Method: quicksort  Memory: 2560kB"
-- "                                ->  Seq Scan on objectives o  (cost=0.00..671.51 rows=32751 width=31) (actual time=0.046..3.620 rows=32751 loops=3)"
-- "Planning Time: 1.024 ms"
-- "JIT:"
-- "  Functions: 93"
-- "  Options: Inlining true, Optimization true, Expressions true, Deforming true"
-- "  Timing: Generation 11.006 ms, Inlining 321.302 ms, Optimization 877.318 ms, Emission 580.474 ms, Total 1790.100 ms"
-- "Execution Time: 8737.981 ms"