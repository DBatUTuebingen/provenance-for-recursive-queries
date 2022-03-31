
WITH RECURSIVE bom_2(tuid, part, sub_part, quantity) AS (
    SELECT l.tuid,
           p.part || wh.y, p.sub_part || wh.y, p.quantity || wh.y
    FROM   parts_2 AS p,
           readLog(1, p.tuid) as l(tuid),
           toY(p.part) as wh(y)
  UNION ALL
    SELECT l.tuid,
           p.part || wh.y as part,
           p.sub_part || wh.y as sub_part,
           p.quantity || b.quantity || wh.y AS quantity
    FROM   bom_2 AS b,
           parts_2 AS p,
           readLog(2, b.tuid, p.tuid) AS l(tuid),
           toY(p.part || b.sub_part) as wh(y)
)
SELECT b.tuid, dd(b.sub_part) AS sub_part, dd(b.quantity) AS quantity
FROM   bom_2 AS b
;

