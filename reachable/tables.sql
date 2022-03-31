
DROP TABLE IF EXISTS edges CASCADE;
CREATE TABLE edges ("from" char, "to" char);
INSERT INTO edges VALUES
    ('A', 'B'),
    ('B', 'C'),
    ('C', 'D'),
    ('D', 'B'),
    ('C', 'E')
;
ALTER TABLE edges ADD PRIMARY KEY ("from", "to");



--------------------------------------------------------------------------------


-- phase 1
DROP TABLE IF EXISTS edges_1 CASCADE;
CREATE TABLE edges_1 AS
    SELECT nextval('tuid_seq')::tuid_t AS tuid,
           e.*
    FROM edges as e
;
ALTER TABLE edges_1 ADD PRIMARY KEY ("from", "to");


-- phase 2
DROP TABLE IF EXISTS edges_2 CASCADE;
CREATE TABLE edges_2 AS
  SELECT e.tuid,
         ARRAY[nextval('annot_seq')]::pset_t AS "from",
         ARRAY[nextval('annot_seq')]::pset_t AS "to"
    FROM edges_1 as e
;
ALTER TABLE edges_2 ADD PRIMARY KEY (tuid);



