
WITH RECURSIVE bom_1(tuid, part, sub_part, quantity) AS (
    SELECT writeLog(1, p.tuid) AS tuid,
           p.part, p.sub_part, p.quantity
    FROM   parts_1 AS p
    WHERE  p.part = 'humanoid'
  UNION ALL
    SELECT writeLog(2, b.tuid, p.tuid) AS tuid,
           p.part, p.sub_part, p.quantity * b.quantity AS quantity
    FROM   bom_1 AS b,
           parts_1 AS p
    WHERE  p.part = b.sub_part
)
SELECT b.tuid, b.sub_part, b.quantity
FROM   bom_1 AS b
;

