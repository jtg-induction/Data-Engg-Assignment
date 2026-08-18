-- Q2 -> Units sold for each part for a dealership.
-- cost time = 32.7s
SELECT
    dealernumber,
    part_number,
    SUM(units) AS total_units_sold
FROM
    sales
GROUP BY
    dealernumber,
    part_number;

-- Monthly wise units sold
-- cost time = 26.8s
SELECT
    s.dealernumber,
    s.part_number,
    Sum(s.units) AS total_units_sold,
    to_char(s.calendardate :: date, 'YYYY FMMonth') AS month_of_sale
FROM
    sales s
GROUP BY
    s.dealernumber,
    s.part_number,
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
    s.part_number,
    Sum(s.units) AS total_units_sold,
    to_char(s.calendardate :: date, 'YYYY FMMonth') AS month_of_sale
FROM
    sales s
GROUP BY
    s.dealernumber,
    s.part_number,
    to_char(s.calendardate :: date, 'YYYY FMMonth'),
    date_trunc('month', s.calendardate);

-- Query Execution Plan
-- "Limit  (cost=4774400.76..4774406.88 rows=20 width=132) (actual time=106924.318..107250.240 rows=20 loops=1)"
-- "  ->  Finalize GroupAggregate  (cost=4774400.76..6197690.34 rows=4653560 width=132) (actual time=106732.108..107058.027 rows=20 loops=1)"
-- "        Group Key: dealernumber, part_number, (to_char((calendardate)::timestamp with time zone, 'YYYY FMMonth'::text)), (date_trunc('month'::text, (calendardate)::timestamp with time zone))"
-- "        ->  Gather Merge  (cost=4774400.76..5860307.24 rows=9307120 width=92) (actual time=106732.015..107057.898 rows=21 loops=1)"
-- "              Workers Planned: 2"
-- "              Workers Launched: 2"
-- "              ->  Sort  (cost=4773400.74..4785034.64 rows=4653560 width=92) (actual time=94590.814..94590.976 rows=300 loops=3)"
-- "                    Sort Key: dealernumber, part_number, (to_char((calendardate)::timestamp with time zone, 'YYYY FMMonth'::text)), (date_trunc('month'::text, (calendardate)::timestamp with time zone))"
-- "                    Sort Method: external merge  Disk: 2037792kB"
-- "                    Worker 0:  Sort Method: external merge  Disk: 1593968kB"
-- "                    Worker 1:  Sort Method: external merge  Disk: 1639552kB"
-- "                    ->  Partial HashAggregate  (cost=3221690.93..3780845.21 rows=4653560 width=92) (actual time=18025.956..34127.916 rows=15087816 loops=3)"
-- "                          Group Key: dealernumber, part_number, to_char((calendardate)::timestamp with time zone, 'YYYY FMMonth'::text), date_trunc('month'::text, (calendardate)::timestamp with time zone)"
-- "                          Planned Partitions: 256  Batches: 2253  Memory Usage: 8345kB  Disk Usage: 1294104kB"
-- "                          Worker 0:  Batches: 1921  Memory Usage: 8281kB  Disk Usage: 1031936kB"
-- "                          Worker 1:  Batches: 2069  Memory Usage: 8465kB  Disk Usage: 1032048kB"
-- "                          ->  Parallel Seq Scan on sales s  (cost=0.00..773724.64 rows=19389832 width=66) (actual time=199.683..10089.631 rows=15508066 loops=3)"
-- "Planning Time: 0.276 ms"
-- "JIT:"
-- "  Functions: 31"
-- "  Options: Inlining true, Optimization true, Expressions true, Deforming true"
-- "  Timing: Generation 7.939 ms, Inlining 413.727 ms, Optimization 316.403 ms, Emission 241.774 ms, Total 979.844 ms"
-- "Execution Time: 107615.891 ms"