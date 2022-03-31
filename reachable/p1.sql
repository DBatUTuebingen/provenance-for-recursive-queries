
WITH RECURSIVE
hull_1(tuid, node) AS (

    SELECT v.tuid::same AS tuid,
           'B'::char --start node
    FROM   (VALUES (writeLog(4))) AS v(tuid)

    UNION DISTINCT

    SELECT writeLog(1, t.tuid)::same AS tuid,
           t.node
    FROM   (SELECT writeLog(2, h.tuid, e.tuid) AS tuid,
                   e."to" AS node
            FROM hull_1 AS h,
                 edges_1 AS e
            WHERE h.node=e."from") AS t

)
SELECT writeLog(3, h.tuid) AS tuid,
       h.node
FROM   hull_1 AS h
;

