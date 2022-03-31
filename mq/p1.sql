
WITH RECURSIVE
pixels_1(tuid,x,y,alt) AS (
  SELECT m.tuid,
         m.x, m.y, (m.alt > 700) AS alt
  FROM   map9x7_1 AS m
),
squares_1(tuid,x,y,ll,lr,ul,ur) AS (
  SELECT writelog(1, p0.tuid, p1.tuid, p2.tuid, p3.tuid) as tuid,
         p0.x, p0.y,
         p0.alt AS ll, p1.alt AS lr, p2.alt AS ul, p3.alt AS ur
  FROM   pixels_1 AS p0, pixels_1 AS p1, pixels_1 AS p2, pixels_1 AS p3
  WHERE  (p1.x,p1.y) = (p0.x+1,p0.y)
  AND    (p2.x,p2.y) = (p0.x  ,p0.y+1)
  AND    (p3.x,p3.y) = (p0.x+1,p0.y+1)
),
march_1(tuid,x,y) AS (
  SELECT v.tuid::same,
         v.x AS x, v.y AS y
  FROM (VALUES (1, 1, 1)) AS v(tuid, x, y)
    UNION DISTINCT
  SELECT writelog(2, t.tuid)::same AS tuid,
         t.x, t.y
  FROM   (SELECT writelog(3, m.tuid, s.tuid, d.tuid) as tuid,
                 m.x + (d.dir).x AS x, m.y + (d.dir).y AS y
          FROM   march_1 AS m, squares_1 AS s, directions_1 AS d
          WHERE  (m.x,m.y) = (s.x,s.y)
          AND    (s.ll,s.lr,s.ul,s.ur) = (d.ll,d.lr,d.ul,d.ur)) as t
)
SELECT writelog(4, m.tuid) as tuid,
       m.x + 0.5 AS x, m.y + 0.5 AS y
FROM   march_1 AS m;



