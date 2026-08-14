-- Q9 Top 10 Tires Bonus: Top 10 dealer of nation will get $3 per tire additional incentive

SELECT
    s.dealernumber,
    to_char(s.calendardate::date,'YYYY FMMonth') AS month_of_sale,
    Sum(s.units) * 3 AS ties_incentive
FROM
    sales s     
INNER JOIN
    parts p ON s.part_number = p.part_number
WHERE
    p.part_category_2 ILIKE '%tires%'
GROUP BY
    s.dealernumber,
    to_char(s.calendardate::date,'YYYY FMMonth')
ORDER BY
    SUM(s.units) DESC    
LIMIT 10    


