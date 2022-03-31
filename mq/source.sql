
-- Marching Squares in UNION DISTINCT -version

WITH RECURSIVE
-- (1) Threshold height map based on given iso value (here: 700)
pixels(x,y,alt) AS (
  SELECT x, y, alt > 700 AS alt
  FROM   map9x7
),
-- (2) Establish 2×2 squares on the pixel-fied map,
--     (x,y) designates lower-left corner: ul  ur
--                                           ⬜︎
--                                         ll  lr
squares(x,y,ll,lr,ul,ur) AS (
  SELECT p0.x, p0.y,
         p0.alt AS ll, p1.alt AS lr, p2.alt AS ul, p3.alt AS ur
  FROM   pixels p0, pixels p1, pixels p2, pixels p3
  WHERE  (p1.x,p1.y) = (p0.x+1,p0.y)
  AND    (p2.x,p2.y) = (p0.x  ,p0.y+1)
  AND    (p3.x,p3.y) = (p0.x+1,p0.y+1)
),
-- (3) Perform the march, starting at point (1,1)
march(x,y) AS (
  SELECT 1 AS x, 1 AS y
    UNION DISTINCT
  SELECT m.x + (d.dir).x AS x, m.y + (d.dir).y AS y
  FROM   march m, squares s, directions d
  WHERE  (m.x,m.y) = (s.x,s.y)
  AND    (s.ll,s.lr,s.ul,s.ur) = (d.ll,d.lr,d.ul,d.ur)
)
-- square coord was lower left, relocate to grid intersection point in middle of square
--       ↓             ↓
SELECT x + 0.5 AS x, y + 0.5 AS y
FROM   march;


