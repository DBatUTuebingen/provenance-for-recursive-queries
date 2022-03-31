
-- time series 'x'
DROP TABLE IF EXISTS tx CASCADE;
CREATE TABLE tx (
    pos int,
    v float
);

INSERT INTO tx(pos, v)
SELECT pos,
       pos % 2 AS v
FROM   generate_series(1, :scalefac) AS pos;


-- INSERT INTO tx(pos, v) VALUES
--     (1, 0),
--     (2, 0),
--     (3, 1),
--     (4, 0),
--     (5, 0),
--     (6, 0)
-- ;


ALTER TABLE tx ADD PRIMARY KEY (pos);


-- time series 'y'
DROP TABLE IF EXISTS ty CASCADE;
CREATE TABLE ty (
  pos int,
  v float
);

INSERT INTO ty(pos, v)
SELECT pos,
       (pos+1) % 2 AS v --add offset +1 (between series tx and ty)
FROM   generate_series(1, :scalefac) AS pos;


-- INSERT INTO ty(pos, v) VALUES
--     (1, 0),
--     (2, 0),
--     (3, 1),
--     (4, 1),
--     (5, 1),
--     (6, 0)
-- ;

ALTER TABLE ty ADD PRIMARY KEY (pos);



-- delta table
DROP TABLE IF EXISTS delta CASCADE;
CREATE TABLE delta AS (
    SELECT  x.pos AS x, Y.pos AS y, ABS(x.v - y.v) AS delta
    FROM    tx AS x,
            ty AS y
);

ALTER TABLE delta ALTER x SET NOT NULL;
ALTER TABLE delta ALTER y SET NOT NULL;
ALTER TABLE delta ALTER delta SET NOT NULL;
ALTER TABLE delta ADD PRIMARY KEY (x, y);


--------------------------------------------------------------------------------
-- data provenance


-- phase 1
DROP TABLE IF EXISTS delta_1 CASCADE;
CREATE TABLE delta_1 AS
    SELECT nextval('tuid_seq')::tuid_t AS tuid,
           d.*
    FROM delta as d
;
ALTER TABLE delta_1 ADD PRIMARY KEY (x, y);


-- phase 2
DROP TABLE IF EXISTS delta_2 CASCADE;
CREATE TABLE delta_2 AS
  SELECT d.tuid,
         ARRAY[nextval('annot_seq')]::int[] AS x,
         ARRAY[nextval('annot_seq')]::int[] AS y,
         ARRAY[nextval('annot_seq')]::int[] AS delta
    FROM delta_1 as d
;
ALTER TABLE delta_2 ADD PRIMARY KEY (tuid);



VACUUM (FULL, ANALYZE) delta, delta_1, delta_2;





