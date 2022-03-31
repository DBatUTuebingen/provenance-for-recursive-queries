
WITH RECURSIVE bom_2(tuid, part, sub_part, quantity) AS (
    SELECT l.tuid,
           p.part, p.sub_part, p.quantity
    FROM   parts_2 AS p,
           readLog(1, p.tuid) as l(tuid)
  UNION ALL
    SELECT l.tuid,
           p.part as part,
           p.sub_part as sub_part,
           (p.quantity || b.quantity)::pset_t AS quantity
    FROM   bom_2 AS b,
           parts_2 AS p,
           readLog(2, b.tuid, p.tuid) AS l(tuid)
)
SELECT b.tuid, dd(b.sub_part) AS sub_part, dd(b.quantity) AS quantity
FROM   bom_2 AS b
;

