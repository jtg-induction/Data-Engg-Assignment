-- Q1 -> Total Sales for each part for a dealership.
-- cost time = 38.4s
SELECT
    s.dealernumber,
    s.part_number,
    Sum(s.value) AS total_sales,
    to_char(s.calendardate :: date, 'YYYY FMMonth') AS month_of_sale
FROM
    sales s
GROUP BY
    s.dealernumber,
    s.part_number,
    to_char(s.calendardate :: date, 'YYYY FMMonth');

-- query with format output
-- cost time = 295ms
SELECT
    'JOSH_CLEAN_AUTOMOBILES' AS nation,
    date_trunc('month', s.calendardate) :: date AS from_period,
    (
        date_trunc('month', s.calendardate) + INTERVAL '1 month' - INTERVAL '1 day'
    ) :: date AS to_period,
    1 AS compute_period,
    s.dealernumber AS dealer,
    s.part_number,
    Sum(s.value) AS total_sales,
    to_char(s.calendardate :: date, 'YYYY FMMonth') AS month_of_sale
FROM
    sales s
GROUP BY
    s.dealernumber,
    s.part_number,
    to_char(s.calendardate :: date, 'YYYY FMMonth'),
    date_trunc('month', s.calendardate);

-- QUERY EXECUTION PLAN
-- "Finalize GroupAggregate  (cost=4774400.76..6197690.34 rows=4653560 width=132) (actual time=65884.955..107372.613 rows=45257229 loops=1)"
-- "  Group Key: dealernumber, part_number, (to_char((calendardate)::timestamp with time zone, 'YYYY FMMonth'::text)), (date_trunc('month'::text, (calendardate)::timestamp with time zone))"
-- "  ->  Gather Merge  (cost=4774400.76..5860307.24 rows=9307120 width=92) (actual time=65884.844..81907.222 rows=45265748 loops=1)"
-- "        Workers Planned: 2"
-- "        Workers Launched: 2"
-- "        ->  Sort  (cost=4773400.74..4785034.64 rows=4653560 width=92) (actual time=61277.625..70432.710 rows=15088583 loops=3)"
-- "              Sort Key: dealernumber, part_number, (to_char((calendardate)::timestamp with time zone, 'YYYY FMMonth'::text)), (date_trunc('month'::text, (calendardate)::timestamp with time zone))"
-- "              Sort Method: external merge  Disk: 1806024kB"
-- "              Worker 0:  Sort Method: external merge  Disk: 1854488kB"
-- "              Worker 1:  Sort Method: external merge  Disk: 1611048kB"
-- "              ->  Partial HashAggregate  (cost=3221690.93..3780845.21 rows=4653560 width=92) (actual time=11479.359..21437.583 rows=15088583 loops=3)"
-- "                    Group Key: dealernumber, part_number, to_char((calendardate)::timestamp with time zone, 'YYYY FMMonth'::text), date_trunc('month'::text, (calendardate)::timestamp with time zone)"
-- "                    Planned Partitions: 256  Batches: 2185  Memory Usage: 8345kB  Disk Usage: 1293552kB"
-- "                    Worker 0:  Batches: 2173  Memory Usage: 8465kB  Disk Usage: 1293688kB"
-- "                    Worker 1:  Batches: 2061  Memory Usage: 8281kB  Disk Usage: 1031984kB"
-- "                    ->  Parallel Seq Scan on sales s  (cost=0.00..773724.64 rows=19389832 width=66) (actual time=155.387..6506.799 rows=15508066 loops=3)"
-- "Planning Time: 17.955 ms"
-- "JIT:"
-- "  Functions: 30"
-- "  Options: Inlining true, Optimization true, Expressions true, Deforming true"
-- "  Timing: Generation 4.636 ms, Inlining 181.743 ms, Optimization 199.691 ms, Emission 197.169 ms, Total 583.239 ms"
-- "Execution Time: 109021.455 ms"