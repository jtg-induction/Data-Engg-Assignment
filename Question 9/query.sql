-- Q9 Top 10 Tires Bonus: Top 10 dealer of nation will get $3 per tire additional incentive
-- cost time = 6.5s
WITH dealers_with_their_rank AS (
    SELECT
        s.dealernumber AS dealernumber,
        to_char(s.calendardate :: date, 'YYYY FMMonth') AS month_of_sale,
        SUM(s.units) AS total_units_sold,
        ROW_NUMBER() OVER(
            PARTITION BY to_char(s.calendardate :: date, 'YYYY FMMonth')
            ORDER BY
                SUM(s.units) DESC
        ) AS dealers_rank
    FROM
        sales s
        INNER JOIN parts p ON s.part_number = p.part_number
    WHERE
        p.part_category_2 ILIKE '%tires%'
    GROUP BY
        to_char(s.calendardate :: date, 'YYYY FMMonth'),
        s.dealernumber
)
SELECT
    month_of_sale,
    dealernumber,
    total_units_sold,
    total_units_sold * 3 AS addtional_top_10_incentive
FROM
    dealers_with_their_rank
WHERE
    dealers_rank <= 10
ORDER BY
    month_of_sale ASC,
    total_units_sold DESC;

-- query with format output
WITH dealers_with_their_rank AS (
    SELECT
        s.dealernumber AS dealernumber,
        to_char(s.calendardate :: date, 'YYYY FMMonth') AS month_of_sale,
        to_char(s.calendardate :: date, 'YYYY FMMonth') AS month_of_sales,
        date_trunc('month', s.calendardate) :: date AS from_period,
        (
            date_trunc('month', s.calendardate) + INTERVAL '1 month' - INTERVAL '1 day'
        ) :: date AS to_period,
        SUM(s.units) AS total_units_sold,
        ROW_NUMBER() OVER(
            PARTITION BY to_char(s.calendardate :: date, 'YYYY FMMonth')
            ORDER BY
                SUM(s.units) DESC
        ) AS dealers_rank
    FROM
        sales s
        INNER JOIN parts p ON s.part_number = p.part_number
    WHERE
        p.part_category_2 ILIKE '%tires%'
    GROUP BY
        to_char(s.calendardate :: date, 'YYYY FMMonth'),
        s.dealernumber,
        date_trunc('month', s.calendardate)
)
SELECT
    'JOSH_CLEAN_AUTOMOBILES' AS nation,
    from_period,
    to_period,
    1 AS compute_period,
    month_of_sale,
    dealernumber AS dealer,
    total_units_sold,
    total_units_sold * 3 AS addtional_top_10_incentive
FROM
    dealers_with_their_rank
WHERE
    dealers_rank <= 10
ORDER BY
    month_of_sale ASC,
    total_units_sold DESC --  QUERY EXECUTION PLAN 
    -- "Subquery Scan on dealers_with_their_rank  (cost=1131986.67..1180241.42 rows=112140 width=98) (actual time=7730.296..8300.086 rows=264 loops=1)"
    -- "  ->  WindowAgg  (cost=1131986.67..1178839.67 rows=112140 width=102) (actual time=7730.289..8300.043 rows=264 loops=1)"
    -- "        Run Condition: (row_number() OVER (?) <= 10)"
    -- "        ->  Incremental Sort  (cost=1131986.67..1173513.02 rows=112140 width=58) (actual time=7730.238..8299.556 rows=1899 loops=1)"
    -- "              Sort Key: (to_char((s.calendardate)::timestamp with time zone, 'YYYY FMMonth'::text)), (sum(s.units)) DESC"
    -- "              Presorted Key: (to_char((s.calendardate)::timestamp with time zone, 'YYYY FMMonth'::text))"
    -- "              Full-sort Groups: 24  Sort Method: quicksort  Average Memory: 29kB  Peak Memory: 29kB"
    -- "              Pre-sorted Groups: 15  Sort Method: quicksort  Average Memory: 34kB  Peak Memory: 34kB"
    -- "              ->  Finalize GroupAggregate  (cost=1131936.53..1168097.86 rows=112140 width=58) (actual time=7721.869..8297.855 rows=1899 loops=1)"
    -- "                    Group Key: (to_char((s.calendardate)::timestamp with time zone, 'YYYY FMMonth'::text)), s.dealernumber, (date_trunc('month'::text, (s.calendardate)::timestamp with time zone))"
    -- "                    ->  Gather Merge  (cost=1131936.53..1163612.26 rows=224280 width=58) (actual time=7721.621..8296.553 rows=5696 loops=1)"
    -- "                          Workers Planned: 2"
    -- "                          Workers Launched: 2"
    -- "                          ->  Partial GroupAggregate  (cost=1130936.51..1136724.76 rows=112140 width=58) (actual time=7648.883..7719.275 rows=1899 loops=3)"
    -- "                                Group Key: (to_char((s.calendardate)::timestamp with time zone, 'YYYY FMMonth'::text)), s.dealernumber, (date_trunc('month'::text, (s.calendardate)::timestamp with time zone))"
    -- "                                ->  Sort  (cost=1130936.51..1131645.60 rows=283636 width=54) (actual time=7648.779..7697.196 rows=169809 loops=3)"
    -- "                                      Sort Key: (to_char((s.calendardate)::timestamp with time zone, 'YYYY FMMonth'::text)), s.dealernumber, (date_trunc('month'::text, (s.calendardate)::timestamp with time zone))"
    -- "                                      Sort Method: external merge  Disk: 8984kB"
    -- "                                      Worker 0:  Sort Method: external merge  Disk: 8248kB"
    -- "                                      Worker 1:  Sort Method: external merge  Disk: 6472kB"
    -- "                                      ->  Parallel Hash Join  (cost=935812.22..1095553.05 rows=283636 width=54) (actual time=5808.955..7367.008 rows=169809 loops=3)"
    -- "                                            Hash Cond: (p.part_number = s.part_number)"
    -- "                                            ->  Parallel Seq Scan on parts p  (cost=0.00..9841.32 rows=2660 width=10) (actual time=44.675..106.200 rows=2090 loops=3)"
    -- "                                                  Filter: (part_category_2 ~~* '%tires%'::text)"
    -- "                                                  Rows Removed by Filter: 187947"
    -- "                                            ->  Parallel Hash  (cost=579826.32..579826.32 rows=19389832 width=24) (actual time=5589.227..5589.228 rows=15508066 loops=3)"
    -- "                                                  Buckets: 131072  Batches: 512  Memory Usage: 7552kB"
    -- "                                                  ->  Parallel Seq Scan on sales s  (cost=0.00..579826.32 rows=19389832 width=24) (actual time=458.254..2162.849 rows=15508066 loops=3)"
    -- "Planning Time: 0.655 ms"
    -- "JIT:"
    -- "  Functions: 60"
    -- "  Options: Inlining true, Optimization true, Expressions true, Deforming true"
    -- "  Timing: Generation 6.827 ms, Inlining 303.364 ms, Optimization 676.492 ms, Emission 395.586 ms, Total 1382.269 ms"
    -- "Execution Time: 8304.994 ms"