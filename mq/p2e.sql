
WITH RECURSIVE
pixels_2(tuid,x,y,alt) AS (
  SELECT m.tuid,
         m.x, m.y, (m.alt || empty()) AS alt
  FROM   map9x7_2 AS m
),
squares_2(tuid,x,y,ll,lr,ul,ur) AS (
  SELECT log.tuid,
         p0.x AS x, p0.y AS y,
         p0.alt AS ll, p1.alt AS lr,
         p2.alt AS ul, p3.alt AS ur
  FROM   pixels_2 AS p0, pixels_2 AS p1, pixels_2 AS p2, pixels_2 AS p3,
         readlog(1, p0.tuid, p1.tuid, p2.tuid, p3.tuid) AS log(tuid)
),
march_2(tuid,x,y) AS (
  SELECT v.tuid::same,
         v.x AS x, v.y AS y
  FROM (VALUES (1, empty(), empty())) AS v(tuid, x, y)
    UNION ALL
  SELECT log.tuid::same,
         t.x::pset_t, t.y::pset_t
  FROM   (SELECT log.tuid,
                 m.x || (d.dir).x AS x, m.y || (d.dir).y AS y
          FROM   march_2 AS m, squares_2 AS s, directions_2 AS d,
                 readlog(3, m.tuid, s.tuid, d.tuid) AS log(tuid)
          ) AS t(tuid, x, y),
         readlog(2, t.tuid) AS log(tuid)
)
SELECT log.tuid,
       dd(m.x || empty()) AS x, dd(m.y || empty()) AS y
FROM   march_2 AS m,
       readlog(4, m.tuid) AS log(tuid);



