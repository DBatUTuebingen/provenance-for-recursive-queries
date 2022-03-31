

DROP TABLE IF EXISTS sequences CASCADE;
CREATE TABLE sequences (
    seq int     NOT NULL, --identifier, unique per sequence
    pos int     NOT NULL, --letter position, unique per sequence
    val char(1) NOT NULL  --a single letter
);
ALTER TABLE sequences ADD PRIMARY KEY (seq, pos);


-- insert two example sequences:
-- ABCD and ACBAD
-- longest common subsequence: ?
INSERT INTO sequences (
    SELECT 1, c.n, c.c
    FROM   regexp_split_to_table('ABCD', '') WITH ORDINALITY c(c,n)
);

INSERT INTO sequences (
    SELECT 2, c.n, c.c
    FROM   regexp_split_to_table('ACBAD', '') WITH ORDINALITY c(c,n)
);


--------------------------------------------------------------------------------
-- phase 1
DROP TABLE IF EXISTS sequences_1 CASCADE;
CREATE TABLE sequences_1 AS
    SELECT nextval('tuid_seq')::tuid_t tuid,
           s.*
    FROM sequences as s
;
ALTER TABLE sequences_1 ADD PRIMARY KEY (seq, pos);


-- phase 2
DROP TABLE IF EXISTS sequences_2 CASCADE;
CREATE TABLE sequences_2 AS
  SELECT s.tuid,
         ARRAY[nextval('annot_seq')]::pset_t AS seq,
         ARRAY[nextval('annot_seq')]::pset_t AS pos,
         ARRAY[nextval('annot_seq')]::pset_t AS val
    FROM sequences_1 as s
;
ALTER TABLE sequences_2 ADD PRIMARY KEY (tuid);





