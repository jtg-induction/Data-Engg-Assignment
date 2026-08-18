-- Q10 Only those dealers are eligible for incentives whose penetration is more than 90% of area penetration.
--     Area Penetration is average of all active dealers penetration.
-- cost time = 58s
WITH avg_penetration AS (
    SELECT
        e.region AS region_of_penetration,
        to_char(to_date(pe.month, 'MM YYYY'), 'YYYY FMMonth') AS month_of_penetration,
        AVG(pe.penetration :: numeric) AS avg_penetration_of_the_region
    FROM
        entity e
        INNER JOIN penetration pe ON e.dealernumber = trim(pe.dealer)
    WHERE
        e.terminationdate IS NULL
    GROUP BY
        e.region,
        pe.month
    ORDER BY
        region ASC,
        pe.month ASC
)
SELECT
    pe.dealer,
    e.region,
    to_char(to_date(pe.month, 'MM YYYY'), 'YYYY FMMonth'),
    pe.penetration,
    CASE
        WHEN pe.penetration :: numeric > 0.9 * ap.avg_penetration_of_the_region THEN 'ELIGIBLE'
        ELSE 'NOT ELIGIBLE'
    END AS ELIGIBILTY
FROM
    penetration pe
    INNER JOIN entity e ON trim(pe.dealer) = e.dealernumber
    INNER JOIN avg_penetration ap ON to_char(to_date(pe.month, 'MM YYYY'), 'YYYY FMMonth') = ap.month_of_penetration
    AND e.region = ap.region_of_penetration
WHERE
    e.terminationdate IS NULL
LIMIT
    10;

-- more optmised using window functions 
-- cost time = 2s
SELECT
    pe.dealer AS dealer,
    to_char(to_date(pe.month, 'MM YYYY'), 'YYYY FMMonth') AS month_of_penetration,
    CASE
        WHEN pe.penetration :: NUMERIC > 0.9 * AVG(pe.penetration :: NUMERIC) OVER(PARTITION BY e.region, pe.month) THEN 'ELIGIBLE'
        ELSE 'NOT ELIGIBLE'
    END AS ELIGIBILITY
FROM
    penetration pe
    INNER JOIN entity e ON e.dealernumber = trim(pe.dealer)
WHERE
    e.terminationdate IS NULL;

-- query with format output    
SELECT
    'JOSH_CLEAN_AUTOMOBILES' AS nation,
    pe.dealer AS dealer,
    to_char(to_date(pe.month, 'MM YYYY'), 'YYYY FMMonth') AS month_of_penetration,
    date_trunc('month', to_date(pe.month, 'MM YYYY')) :: date AS from_period,
    (
        date_trunc('month', to_date(pe.month, 'MM YYYY')) + INTERVAL '1 month' - INTERVAL '1 day'
    ) :: date AS to_period,
    1 AS compute_period,
    CASE
        WHEN pe.penetration :: NUMERIC > 0.9 * AVG(pe.penetration :: NUMERIC) OVER(PARTITION BY e.region, pe.month) THEN 'ELIGIBLE'
        ELSE 'NOT ELIGIBLE'
    END AS ELIGIBILITY
FROM
    penetration pe
    INNER JOIN entity e ON e.dealernumber = trim(pe.dealer)
WHERE
    e.terminationdate IS NULL -- QUERY EXECUTION PLAN 
    -- "WindowAgg  (cost=1716.35..2578.87 rows=12778 width=130) (actual time=57.320..137.188 rows=27214 loops=1)"
    -- "  ->  Sort  (cost=1716.35..1748.30 rows=12778 width=43) (actual time=57.149..60.104 rows=27214 loops=1)"
    -- "        Sort Key: e.region, pe.month"
    -- "        Sort Method: quicksort  Memory: 2682kB"
    -- "        ->  Hash Join  (cost=60.69..844.80 rows=12778 width=43) (actual time=1.467..29.565 rows=27214 loops=1)"
    -- "              Hash Cond: (TRIM(BOTH FROM pe.dealer) = e.dealernumber)"
    -- "              ->  Seq Scan on penetration pe  (cost=0.00..515.89 rows=28089 width=37) (actual time=0.635..6.886 rows=28089 loops=1)"
    -- "              ->  Hash  (cost=47.39..47.39 rows=1064 width=12) (actual time=0.802..0.803 rows=1064 loops=1)"
    -- "                    Buckets: 2048  Batches: 1  Memory Usage: 63kB"
    -- "                    ->  Seq Scan on entity e  (cost=0.00..47.39 rows=1064 width=12) (actual time=0.021..0.510 rows=1064 loops=1)"
    -- "                          Filter: (terminationdate IS NULL)"
    -- "                          Rows Removed by Filter: 1275"
    -- "Planning Time: 0.440 ms"
    -- "Execution Time: 138.782 ms"