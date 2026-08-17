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
    e.terminationdate IS NULL