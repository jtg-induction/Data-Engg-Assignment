-- Q9 Top 10 Tires Bonus: Top 10 dealer of nation will get $3 per tire additional incentive

SELECT
    s.dealernumber,
    c.yearmonth,
    Sum(s.units) * 3 AS ties_incentive
FROM
    sales s     
INNER JOIN
    calendar c ON s.calendardate = c.calendardate::date
INNER JOIN
    parts p ON s.part_number = p.part_number
WHERE
    LOWER(p.part_description) LIKE '%tire%'
GROUP BY
    s.dealernumber,
    c.yearmonth
ORDER BY
    SUM(s.units) DESC    
LIMIT 10    


