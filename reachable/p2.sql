
WITH RECURSIVE
hull_2(tuid, node) AS (

    SELECT v.tuid AS tuid,
           empty() --start node (see phase 1 for actual value)
    FROM   (VALUES (readOne(4))) AS v(tuid)

    UNION ALL

    SELECT l.tuid,
           t.node
    FROM (SELECT l.tuid AS tuid,
                 (e."to" || wh.y)::pset_t AS node
          FROM hull_2 AS h,
               edges_2 AS e,
               readLog(2, h.tuid, e.tuid) AS l(tuid),
               toY(h.node || e."from") AS wh(y)
          ) AS t,
         readLog(1, t.tuid) AS l(tuid)

)
SELECT l.tuid,
       dd(h.node || wh.y) AS node
FROM hull_2 AS h,
     readLog(3, h.tuid) AS l(tuid),
     toY(h.node) AS wh(y)
;
