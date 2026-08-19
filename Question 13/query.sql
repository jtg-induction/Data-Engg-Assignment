-- Q13 Calculate RSD (Relative Standard Deviation) Metric for all the dealers.
-- RSD = YoY % Growth of Dealer / YoY % Growth of Area
-- YoY % Growth = (Current Month Sales (in $) - Last Year Same Month Sales (in $)) / Last Year Same Month Sales (in $)
-- For Area YoY % Growth use only active dealers.
-- cost time = 35s
WITH dealer_sales AS (
    SELECT
        s.dealernumber,
        to_char(s.calendardate :: date, 'YYYY FMMonth') AS month_of_sale,
        e.region AS region,
        SUM(s.value) AS total_sales
    FROM
        sales s
        INNER JOIN entity e ON s.dealernumber = e.dealernumber
    WHERE
        terminationdate IS NULL
    GROUP BY
        s.dealernumber,
        e.region,
        to_char(s.calendardate :: date, 'YYYY FMMonth')
),
dealeryoy AS (
    SELECT
        ds1.dealernumber,
        ds1.month_of_sale,
        ds1.region,
        ds1.total_sales,
        ds2.total_sales AS last_year_sales,
        CASE
            WHEN ds2.total_sales IS NULL
            OR ds2.total_sales = 0 THEN 0
            ELSE (ds1.total_sales - ds2.total_sales) / ds2.total_sales
        END AS dealer_yoy
    FROM
        dealer_sales ds1
        LEFT JOIN dealer_sales ds2 ON ds1.dealernumber = ds2.dealernumber
        AND to_date(ds1.month_of_sale, 'YYYY Month') = to_date(ds2.month_of_sale, 'YYYY Month') + INTERVAL '1 Year'
),
regionyoy AS(
    SELECT
        ds1.region,
        ds1.month_of_sale,
        SUM(ds1.total_sales) AS current_region_sales,
        SUM(ds2.total_sales) AS last_year_region_sales,
        CASE
            WHEN SUM(ds2.total_Sales) IS NULL
            OR SUM(ds2.total_sales) = 0 THEN 0
            ELSE (SUM(ds1.total_sales) - SUM(ds2.total_sales)) / SUM(ds2.total_sales)
        END AS region_yoy
    FROM
        dealer_sales ds1
        LEFT JOIN dealer_sales ds2 ON ds1.dealernumber = ds2.dealernumber
        AND to_date(ds1.month_of_sale, 'YYYY Month') = to_date(ds2.month_of_sale, 'YYYY Month') + INTERVAL '1 Year'
    GROUP BY
        ds1.region,
        ds1.month_of_sale
)
SELECT
    d.dealernumber AS dealer,
    d.region,
    d.month_of_sale,
    d.dealer_yoy,
    r.region_yoy,
    CASE
        WHEN r.region_yoy IS NULL
        OR r.region_yoy = 0 THEN 0
        ELSE d.dealer_yoy / r.region_yoy
    END AS rsd
FROM
    dealeryoy d
    LEFT JOIN regionyoy r ON d.region = r.region
    AND d.month_of_sale = r.month_of_sale;

-- query with format output
WITH dealer_sales AS (
    SELECT
        s.dealernumber,
        to_char(s.calendardate :: date, 'YYYY FMMonth') AS month_of_sale,
        date_trunc('month', s.calendardate) :: date AS from_period,
        (
            date_trunc('month', s.calendardate) + INTERVAL '1 month' - INTERVAL '1 day'
        ) :: date AS to_period,
        e.region AS region,
        SUM(s.value) AS total_sales
    FROM
        sales s
        JOIN entity e ON s.dealernumber = e.dealernumber
    WHERE
        terminationdate IS NULL
    GROUP BY
        s.dealernumber,
        e.region,
        to_char(s.calendardate :: date, 'YYYY FMMonth'),
        date_trunc('month', s.calendardate)
),
dealeryoy AS (
    SELECT
        ds1.dealernumber,
        ds1.month_of_sale,
        ds1.from_period,
        ds1.to_period,
        ds1.region,
        ds1.total_sales,
        ds2.total_sales AS last_year_sales,
        CASE
            WHEN ds2.total_sales IS NULL
            OR ds2.total_sales = 0 THEN 0
            ELSE (ds1.total_sales - ds2.total_sales) / ds2.total_sales
        END AS dealer_yoy
    FROM
        dealer_sales ds1
        JOIN dealer_sales ds2 ON ds1.dealernumber = ds2.dealernumber
        AND to_date(ds1.month_of_sale, 'YYYY Month') = to_date(ds2.month_of_sale, 'YYYY Month') + INTERVAL '1 Year'
),
regionyoy AS(
    SELECT
        ds1.region,
        ds1.month_of_sale,
        SUM(ds1.total_sales) AS current_region_sales,
        SUM(ds2.total_sales) AS last_year_region_sales,
        CASE
            WHEN SUM(ds2.total_Sales) IS NULL
            OR SUM(ds2.total_sales) = 0 THEN 0
            ELSE (SUM(ds1.total_sales) - SUM(ds2.total_sales)) / SUM(ds2.total_sales)
        END AS region_yoy
    FROM
        dealer_sales ds1
        JOIN dealer_sales ds2 ON ds1.dealernumber = ds2.dealernumber
        AND to_date(ds1.month_of_sale, 'YYYY Month') = to_date(ds2.month_of_sale, 'YYYY Month') + INTERVAL '1 Year'
    GROUP BY
        ds1.region,
        ds1.month_of_sale
)
SELECT
    'JOSH_CLEAN_AUTOMOBILES' AS nation,
    d.from_period,
    d.to_period,
    1 AS compute_period,
    d.dealernumber AS dealer,
    d.region AS dealer_region,
    d.month_of_sale,
    d.dealer_yoy,
    r.region_yoy,
    CASE
        WHEN r.region_yoy IS NULL
        OR r.region_yoy = 0 THEN 0
        ELSE d.dealer_yoy / r.region_yoy
    END AS rsd
FROM
    dealeryoy d
    JOIN regionyoy r ON d.region = r.region
    AND d.month_of_sale = r.month_of_sale;

--  QUERY EXECUTION PLAN 
-- "Merge Left Join  (cost=5804426.29..6325503.88 rows=11317842 width=236) (actual time=16675.251..16677.390 rows=1898 loops=1)"
-- "  Merge Cond: ((ds1.dealernumber = ds2.dealernumber) AND ((to_date(ds1.month_of_sale, 'YYYY Month'::text)) = ((to_date(ds2.month_of_sale, 'YYYY Month'::text) + '1 year'::interval))))"
-- "  CTE dealer_sales"
-- "    ->  Finalize GroupAggregate  (cost=2208827.03..2414614.89 rows=672840 width=92) (actual time=16654.838..16661.885 rows=1898 loops=1)"
-- "          Group Key: s.dealernumber, e.region, (to_char((s.calendardate)::timestamp with time zone, 'YYYY FMMonth'::text)), (date_trunc('month'::text, (s.calendardate)::timestamp with time zone))"
-- "          ->  Gather Merge  (cost=2208827.03..2365833.99 rows=1345680 width=88) (actual time=16654.783..16657.463 rows=5694 loops=1)"
-- "                Workers Planned: 2"
-- "                Workers Launched: 2"
-- "                ->  Sort  (cost=2207827.01..2209509.11 rows=672840 width=88) (actual time=16629.213..16629.390 rows=1898 loops=3)"
-- "                      Sort Key: s.dealernumber, e.region, (to_char((s.calendardate)::timestamp with time zone, 'YYYY FMMonth'::text)), (date_trunc('month'::text, (s.calendardate)::timestamp with time zone))"
-- "                      Sort Method: quicksort  Memory: 293kB"
-- "                      Worker 0:  Sort Method: quicksort  Memory: 293kB"
-- "                      Worker 1:  Sort Method: quicksort  Memory: 293kB"
-- "                      ->  Partial HashAggregate  (cost=1873664.98..2078303.42 rows=672840 width=88) (actual time=16625.623..16626.247 rows=1898 loops=3)"
-- "                            Group Key: s.dealernumber, e.region, to_char((s.calendardate)::timestamp with time zone, 'YYYY FMMonth'::text), date_trunc('month'::text, (s.calendardate)::timestamp with time zone)"
-- "                            Planned Partitions: 32  Batches: 1  Memory Usage: 1553kB"
-- "                            Worker 0:  Batches: 1  Memory Usage: 1553kB"
-- "                            Worker 1:  Batches: 1  Memory Usage: 1553kB"
-- "                            ->  Hash Join  (cost=60.69..829005.73 rows=8820342 width=62) (actual time=717.282..11680.545 rows=15507790 loops=3)"
-- "                                  Hash Cond: (s.dealernumber = e.dealernumber)"
-- "                                  ->  Parallel Seq Scan on sales s  (cost=0.00..579826.32 rows=19389832 width=16) (actual time=0.063..1301.505 rows=15508066 loops=3)"
-- "                                  ->  Hash  (cost=47.39..47.39 rows=1064 width=12) (actual time=717.059..717.061 rows=1064 loops=3)"
-- "                                        Buckets: 2048  Batches: 1  Memory Usage: 63kB"
-- "                                        ->  Seq Scan on entity e  (cost=0.00..47.39 rows=1064 width=12) (actual time=716.145..716.571 rows=1064 loops=3)"
-- "                                              Filter: (terminationdate IS NULL)"
-- "                                              Rows Removed by Filter: 1275"
-- "  ->  Sort  (cost=3242225.01..3243907.11 rows=672840 width=168) (actual time=16672.765..16672.883 rows=1898 loops=1)"
-- "        Sort Key: ds1.dealernumber, (to_date(ds1.month_of_sale, 'YYYY Month'::text))"
-- "        Sort Method: quicksort  Memory: 195kB"
-- "        ->  Hash Left Join  (cost=3049715.00..3066704.42 rows=672840 width=168) (actual time=16669.567..16670.781 rows=1898 loops=1)"
-- "              Hash Cond: ((ds1.region = r.region) AND (ds1.month_of_sale = r.month_of_sale))"
-- "              ->  CTE Scan on dealer_sales ds1  (cost=0.00..13456.80 rows=672840 width=136) (actual time=16654.849..16655.099 rows=1898 loops=1)"
-- "              ->  Hash  (cost=3049115.00..3049115.00 rows=40000 width=96) (actual time=14.600..14.607 rows=157 loops=1)"
-- "                    Buckets: 65536  Batches: 1  Memory Usage: 522kB"
-- "                    ->  Subquery Scan on r  (cost=2627816.96..3049115.00 rows=40000 width=96) (actual time=14.354..14.522 rows=157 loops=1)"
-- "                          ->  HashAggregate  (cost=2627816.96..3048715.00 rows=40000 width=160) (actual time=14.348..14.501 rows=157 loops=1)"
-- "                                Group Key: ds1_1.region, ds1_1.month_of_sale"
-- "                                Planned Partitions: 4  Batches: 1  Memory Usage: 529kB"
-- "                                ->  Merge Left Join  (cost=313568.78..608289.53 rows=11317842 width=128) (actual time=12.577..13.604 rows=1898 loops=1)"
-- "                                      Merge Cond: ((ds1_1.dealernumber = ds2_1.dealernumber) AND ((to_date(ds1_1.month_of_sale, 'YYYY Month'::text)) = ((to_date(ds2_1.month_of_sale, 'YYYY Month'::text) + '1 year'::interval))))"
-- "                                      ->  Sort  (cost=165982.39..167664.49 rows=672840 width=128) (actual time=10.130..10.233 rows=1898 loops=1)"
-- "                                            Sort Key: ds1_1.dealernumber, (to_date(ds1_1.month_of_sale, 'YYYY Month'::text))"
-- "                                            Sort Method: quicksort  Memory: 169kB"
-- "                                            ->  CTE Scan on dealer_sales ds1_1  (cost=0.00..13456.80 rows=672840 width=128) (actual time=0.023..8.491 rows=1898 loops=1)"
-- "                                      ->  Materialize  (cost=147586.39..150950.59 rows=672840 width=96) (actual time=2.389..2.713 rows=1897 loops=1)"
-- "                                            ->  Sort  (cost=147586.39..149268.49 rows=672840 width=96) (actual time=2.384..2.485 rows=1897 loops=1)"
-- "                                                  Sort Key: ds2_1.dealernumber, ((to_date(ds2_1.month_of_sale, 'YYYY Month'::text) + '1 year'::interval))"
-- "                                                  Sort Method: quicksort  Memory: 165kB"
-- "                                                  ->  CTE Scan on dealer_sales ds2_1  (cost=0.00..13456.80 rows=672840 width=96) (actual time=0.012..0.843 rows=1898 loops=1)"
-- "  ->  Materialize  (cost=147586.39..150950.59 rows=672840 width=96) (actual time=2.423..2.738 rows=1897 loops=1)"
-- "        ->  Sort  (cost=147586.39..149268.49 rows=672840 width=96) (actual time=2.417..2.530 rows=1897 loops=1)"
-- "              Sort Key: ds2.dealernumber, ((to_date(ds2.month_of_sale, 'YYYY Month'::text) + '1 year'::interval))"
-- "              Sort Method: quicksort  Memory: 165kB"
-- "              ->  CTE Scan on dealer_sales ds2  (cost=0.00..13456.80 rows=672840 width=96) (actual time=0.010..0.867 rows=1898 loops=1)"
-- "Planning Time: 1.569 ms"
-- "JIT:"
-- "  Functions: 97"
-- "  Options: Inlining true, Optimization true, Expressions true, Deforming true"
-- "  Timing: Generation 10.648 ms, Inlining 293.220 ms, Optimization 1224.095 ms, Emission 631.286 ms, Total 2159.249 ms"
-- "Execution Time: 16685.261 ms"