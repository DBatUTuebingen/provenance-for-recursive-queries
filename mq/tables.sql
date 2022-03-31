

DROP TYPE IF EXISTS direction CASCADE;
CREATE TYPE direction AS (
  x int,
  y int
);


DROP TABLE IF EXISTS directions CASCADE;
CREATE TABLE directions (ll bool, lr bool, ul bool, ur bool, dir direction);
INSERT INTO directions VALUES
  (false,false,false,false, ( 1, 0)), -- | | ︎: →
  (false,false,false,true , ( 1, 0)), -- |▝| : →
  (false,false,true ,false, ( 0, 1)), -- |▘| : ↑
  (false,false,true ,true , ( 1, 0)), -- |▀| : →
  (false,true ,false,false, ( 0,-1)), -- |▗| : ↓
  (false,true ,false,true , ( 0,-1)), -- |▐| : ↓
  (false,true ,true ,false, ( 0, 1)), -- |▚| : ↑
  (false,true ,true ,true , ( 0,-1)), -- |▜| : ↓
  (true ,false,false,false, (-1, 0)), -- |▖| : ←
  (true ,false,false,true , (-1, 0)), -- |▞| : ←
  (true ,false,true ,false, ( 0, 1)), -- |▌| : ↑
  (true ,false,true ,true , ( 1, 0)), -- |▛| : →
  (true ,true ,false,false, (-1, 0)), -- |▄| : ←
  (true ,true ,false,true , (-1, 0)), -- |▟| : ←
  (true ,true ,true ,false, ( 0, 1)), -- |▛| : →
  (true ,true ,true ,true , NULL   ); -- |█| : x
ALTER TABLE directions ADD PRIMARY KEY (ll, lr, ul, ur);


DROP TABLE IF EXISTS map9x7 CASCADE;
CREATE TABLE map9x7(x int, y int, alt int);
ALTER TABLE map9x7 ADD PRIMARY KEY (x, y);
INSERT INTO map9x7 VALUES (0, 6, 400),
(1, 6, 400),
(2, 6, 400),
(3, 6, 400),
(4, 6, 400),
(5, 6, 500),
(6, 6, 500),
(7, 6, 400),
(8, 6, 400),
(0, 5, 400),
(1, 5, 400),
(2, 5, 400),
(3, 5, 500),
(4, 5, 500),
(5, 5, 700),
(6, 5, 700),
(7, 5, 500),
(8, 5, 400),
(0, 4, 400),
(1, 4, 400),
(2, 4, 500),
(3, 4, 500),
(4, 4, 700),
(5, 4, 800),
(6, 4, 700),
(7, 4, 700),
(8, 4, 500),
(0, 3, 400),
(1, 3, 500),
(2, 3, 700),
(3, 3, 700),
(4, 3, 800),
(5, 3, 800),
(6, 3, 800),
(7, 3, 800),
(8, 3, 700),
(0, 2, 400),
(1, 2, 700),
(2, 2, 800),
(3, 2, 800),
(4, 2, 900),
(5, 2, 900),
(6, 2, 900),
(7, 2, 800),
(8, 2, 700),
(0, 1, 400),
(1, 1, 700),
(2, 1, 700),
(3, 1, 800),
(4, 1, 900),
(5, 1, 900),
(6, 1, 800),
(7, 1, 700),
(8, 1, 700),
(0, 0, 400),
(1, 0, 400),
(2, 0, 500),
(3, 0, 700),
(4, 0, 700),
(5, 0, 700),
(6, 0, 700),
(7, 0, 500),
(8, 0, 500);


--------------------------------------------------------------------------------
-- phase 1

DROP TABLE IF EXISTS directions_1 CASCADE;
CREATE TABLE directions_1 (tuid tuid_t, ll bool, lr bool, ul bool, ur bool, dir direction);
INSERT INTO directions_1
    SELECT nextval('tuid_seq')::tuid_t AS tuid,
           d.ll, d.lr, d.ul, d.ur, d.dir
    FROM directions as d
;
ALTER TABLE directions_1 ADD PRIMARY KEY (ll, lr, ul, ur);

DROP TABLE IF EXISTS map9x7_1 CASCADE;
CREATE TABLE map9x7_1 (tuid tuid_t, x int, y int, alt int);
INSERT INTO map9x7_1
    SELECT nextval('tuid_seq')::tuid_t AS tuid,
           m.x, m.y, m.alt
    FROM map9x7 as m
;
ALTER TABLE map9x7_1 ADD PRIMARY KEY (x, y);


-- phase 2
DROP TYPE IF EXISTS direction_2 CASCADE;
CREATE TYPE direction_2 AS (
  x int[],
  y int[]
);

DROP TABLE IF EXISTS directions_2 CASCADE;
CREATE TABLE directions_2 (tuid tuid_t, ll pset_t, lr pset_t, ul pset_t, ur pset_t, dir direction_2);
INSERT INTO directions_2
    SELECT d.tuid,
           ARRAY[nextval('annot_seq')]::pset_t AS ll,
           ARRAY[nextval('annot_seq')]::pset_t AS lr,
           ARRAY[nextval('annot_seq')]::pset_t AS ul,
           ARRAY[nextval('annot_seq')]::pset_t AS ur,
           (ARRAY[nextval('annot_seq')]::pset_t,
            ARRAY[nextval('annot_seq')]::pset_t)::direction_2 AS dir
    FROM directions_1 as d
;
ALTER TABLE directions_2 ADD PRIMARY KEY (tuid);

DROP TABLE IF EXISTS map9x7_2 CASCADE;
CREATE TABLE map9x7_2 (tuid tuid_t, x pset_t, y pset_t, alt pset_t);
INSERT INTO map9x7_2
    SELECT m.tuid,
           ARRAY[nextval('annot_seq')]::pset_t AS x,
           ARRAY[nextval('annot_seq')]::pset_t AS y,
           ARRAY[nextval('annot_seq')]::pset_t AS alt
    FROM map9x7_1 as m
;
ALTER TABLE map9x7_2 ADD PRIMARY KEY (tuid);



