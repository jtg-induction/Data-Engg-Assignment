-- Q3 -> Total Sales for a dealership.
-- cost time 8.4s
SELECT
    s.dealernumber,
    SUM(s.value) AS total_sales,
    to_char(s.calendardate :: date, 'YYYY FMMonth') AS month_of_sale
FROM
    sales s
GROUP BY
    dealernumber,
    to_char(s.calendardate :: date, 'YYYY FMMonth');

--query with format output 
-- cost time = 15s
SELECT
    'JOSH_CLEAN_AUTOMOBILES' AS nation,
    date_trunc('month', s.calendardate) :: date AS from_period,
    (
        date_trunc('month', s.calendardate) + INTERVAL '1 month' - INTERVAL '1 day'
    ) :: date AS to_period,
    1 AS compute_period,
    s.dealernumber AS dealer,
    SUM(s.value) AS total_sales,
    to_char(s.calendardate :: date, 'YYYY FMMonth') AS month_of_sale
FROM
    sales s
GROUP BY
    dealernumber,
    to_char(s.calendardate :: date, 'YYYY FMMonth'),
    date_trunc('month', s.calendardate);

-- QUERY EXECUTION PLAN
-- "Limit  (cost=3267255.76..3267261.78 rows=20 width=122) (actual time=13334.765..13345.517 rows=20 loops=1)"
-- "  ->  Finalize GroupAggregate  (cost=3267255.76..3300993.04 rows=112140 width=122) (actual time=13093.592..13104.340 rows=20 loops=1)"
-- "        Group Key: dealernumber, (to_char((calendardate)::timestamp with time zone, 'YYYY FMMonth'::text)), (date_trunc('month'::text, (calendardate)::timestamp with time zone))"
-- "        ->  Gather Merge  (cost=3267255.76..3293423.59 rows=224280 width=82) (actual time=13093.511..13104.217 rows=61 loops=1)"
-- "              Workers Planned: 2"
-- "              Workers Launched: 2"
-- "              ->  Sort  (cost=3266255.74..3266536.09 rows=112140 width=82) (actual time=13062.027..13062.068 rows=355 loops=3)"
-- "                    Sort Key: dealernumber, (to_char((calendardate)::timestamp with time zone, 'YYYY FMMonth'::text)), (date_trunc('month'::text, (calendardate)::timestamp with time zone))"
-- "                    Sort Method: quicksort  Memory: 281kB"
-- "                    Worker 0:  Sort Method: quicksort  Memory: 281kB"
-- "                    Worker 1:  Sort Method: quicksort  Memory: 281kB"
-- "                    ->  Partial HashAggregate  (cost=2870250.22..3251481.03 rows=112140 width=82) (actual time=13058.261..13058.998 rows=1899 loops=3)"
-- "                          Group Key: dealernumber, to_char((calendardate)::timestamp with time zone, 'YYYY FMMonth'::text), date_trunc('month'::text, (calendardate)::timestamp with time zone)"
-- "                          Planned Partitions: 8  Batches: 1  Memory Usage: 1553kB"
-- "                          Worker 0:  Batches: 1  Memory Usage: 1553kB"
-- "                          Worker 1:  Batches: 1  Memory Usage: 1553kB"
-- "                          ->  Parallel Seq Scan on sales s  (cost=0.00..773724.64 rows=19389832 width=56) (actual time=202.599..8692.198 rows=15508066 loops=3)"
-- "Planning Time: 0.226 ms"
-- "JIT:"
-- "  Functions: 22"
-- "  Options: Inlining true, Optimization true, Expressions true, Deforming true"
-- "  Timing: Generation 4.385 ms, Inlining 360.134 ms, Optimization 294.001 ms, Emission 194.434 ms, Total 852.955 ms"
-- "Execution Time: 13348.339 ms"