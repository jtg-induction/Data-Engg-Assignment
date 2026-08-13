-- Q2 -> Units sold for each part for a dealership.

SELECT
    dealernumber,
    part_number,
    SUM(units) AS total_units
FROM
    sales
GROUP BY
    dealernumber,
    part_number;


-- query of dealers with atleast 1 sale with more data points for dealer 
SELECT
    e.dealernumber,
    e.dealername,
    e.division,
    e.region,
    sum(s.units) AS total_units
FROM
    entity e
INNER JOIN
    sales s ON e.dealernumber = s.dealernumber
GROUP BY
    e.dealernumber,
    s.part_number,
    e.dealername,
    e.division,
    e.region

-- with all the dealers whether they have done any sales or not 
SELECT
    e.dealernumber,
    e.dealername,
    e.division,
    e.region,
    sum(s.units) AS total_units
FROM
    entity e
LEFT JOIN
    sales s ON e.dealernumber = s.dealernumber
GROUP BY
    e.dealernumber,
    s.part_number,
    e.dealername,
    e.division,
    e.region

               
-- query for dealers with atleast 1 sale with extra datapoints for parts  

SELECT
    e.dealernumber,
    e.dealername,
    e.division,
    e.region,
    s.part_number,
    p.part_description,
    p.part_category_1,
    p.part_categry_2,
    sum(s.units) AS total_units
FROM
    entity e
INNER JOIN
    sales s ON e.dealernumber = s.dealernumber
INNER JOIN
    parts ON s.part_number = p.part_number     
GROUP BY
    e.dealernumber,
    e.dealername,
    e.division,
    e.region,
    s.part_number,
    p.part_description,
    p.part_category_1,
    p.part_categry_2

-- query for dealers whether they have done any sales or not with extra datapoints for parts  

SELECT
    e.dealernumber,
    e.dealername,
    e.division,
    e.region,
    s.part_number,
    p.part_description,
    p.part_category_1,
    p.part_categry_2,
    sum(s.units) AS total_units
FROM
    entity e
LEFT JOIN
    sales s ON e.dealernumber = s.dealernumber
LEFT JOIN
    parts p ON s.part_number = p.part_number     
GROUP BY
    e.dealernumber,
    e.dealername,
    e.division,
    e.region,
    s.part_number,
    p.part_description,
    p.part_category_1,
    p.part_categry_2
  
       