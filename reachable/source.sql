WITH RECURSIVE
hull(node) AS (

    SELECT 'B'::char --start node

    UNION DISTINCT

    SELECT e."to"
    FROM hull AS h,
         edges AS e
    WHERE h.node=e."from"

)
SELECT *
FROM hull as h
;
