
-- this is the BOM query with bugfix


WITH RECURSIVE bom(part, sub_part, quantity) AS (
    SELECT p.part, p.sub_part, p.quantity
    FROM   parts AS p
    WHERE  p.part = 'humanoid'
  UNION ALL
    SELECT p.part, p.sub_part, p.quantity * b.quantity
    FROM   bom AS b,
           parts AS p
    WHERE  p.part = b.sub_part
)
SELECT b.sub_part, b.quantity
FROM   bom AS b
;


