-- Q4 -> Total Units sold by a dealership.
-- with monthly wise sales
-- cost time 7.7s
SELECT
    s.dealernumber,
    SUM(s.units) AS total_units_sold,
    to_char(s.calendardate :: date, 'YYYY FMMonth') AS month_of_sale
FROM
    sales s
GROUP BY
    dealernumber,
    to_char(s.calendardate :: date, 'YYYY FMMonth');

-- query with format output
-- cost time = 2s
SELECT
    'JOSH_CLEAN_AUTOMOBILES' AS nation,
    date_trunc('month', s.calendardate) :: date AS from_period,
    (
        date_trunc('month', s.calendardate) + INTERVAL '1 month' - INTERVAL '1 day'
    ) :: date AS to_period,
    1 AS compute_period,
    s.dealernumber AS dealer,
    SUM(s.units) AS total_units_sold,
    to_char(s.calendardate :: date, 'YYYY FMMonth') AS month_of_sale
FROM
    sales s
GROUP BY
    dealernumber,
    to_char(s.calendardate :: date, 'YYYY FMMonth'),
    date_trunc('month', s.calendardate);

-- QUERY EXECUTION PLAN 
-- "Finalize GroupAggregate  (cost=3265823.91..3298720.14 rows=112140 width=98) (actual time=12671.028..12682.359 rows=1899 loops=1)"
-- "  Group Key: dealernumber, (to_char((calendardate)::timestamp with time zone, 'YYYY FMMonth'::text)), (date_trunc('month'::text, (calendardate)::timestamp with time zone))"
-- "  ->  Gather Merge  (cost=3265823.91..3291991.74 rows=224280 width=58) (actual time=12670.981..12681.111 rows=5697 loops=1)"
-- "        Workers Planned: 2"
-- "        Workers Launched: 2"
-- "        ->  Sort  (cost=3264823.89..3265104.24 rows=112140 width=58) (actual time=12639.976..12640.093 rows=1899 loops=3)"
-- "              Sort Key: dealernumber, (to_char((calendardate)::timestamp with time zone, 'YYYY FMMonth'::text)), (date_trunc('month'::text, (calendardate)::timestamp with time zone))"
-- "              Sort Method: quicksort  Memory: 177kB"
-- "              Worker 0:  Sort Method: quicksort  Memory: 177kB"
-- "              Worker 1:  Sort Method: quicksort  Memory: 177kB"
-- "              ->  Partial HashAggregate  (cost=2870250.22..3251200.68 rows=112140 width=58) (actual time=12636.958..12637.369 rows=1899 loops=3)"
-- "                    Group Key: dealernumber, to_char((calendardate)::timestamp with time zone, 'YYYY FMMonth'::text), date_trunc('month'::text, (calendardate)::timestamp with time zone)"
-- "                    Planned Partitions: 4  Batches: 1  Memory Usage: 1809kB"
-- "                    Worker 0:  Batches: 1  Memory Usage: 1809kB"
-- "                    Worker 1:  Batches: 1  Memory Usage: 1809kB"
-- "                    ->  Parallel Seq Scan on sales s  (cost=0.00..773724.64 rows=19389832 width=54) (actual time=284.027..9279.284 rows=15508066 loops=3)"
-- "Planning Time: 0.274 ms"
-- "JIT:"
-- "  Functions: 21"
-- "  Options: Inlining true, Optimization true, Expressions true, Deforming true"
-- "  Timing: Generation 4.411 ms, Inlining 357.501 ms, Optimization 297.139 ms, Emission 196.733 ms, Total 855.783 ms"
-- "Execution Time: 12685.275 ms"