
-- bom data for "normal" (non-provenance) query evaluation

DROP TABLE IF EXISTS parts CASCADE;
CREATE TABLE parts (
    part        VARCHAR NOT NULL,
    sub_part    VARCHAR NOT NULL,
    quantity    INT     NOT NULL
);
ALTER TABLE parts ADD PRIMARY KEY (part, sub_part);

INSERT INTO parts (part, sub_part, quantity) VALUES
    ('humanoid', 'head'  , 1),
    ('humanoid', 'body'  , 1),
    ('body'    , 'arm'   , 2),
    ('body'    , 'leg'   , 2),
    ('arm'     , 'finger', 5),
    ('leg'     , 'foot'  , 1),
    ('chassis' , 'wheel' , 4);


--------------------------------------------------------------------------------
-- produce the two additional base tables for provenance analysis


-- phase 1
DROP TABLE IF EXISTS parts_1 CASCADE;
CREATE TABLE parts_1 AS
    SELECT nextval('tuid_seq')::tuid_t AS tuid, --create unique identifier per row
           p.* --keep all data from original table
    FROM parts as p
;
-- keep the key definition from original table (see above)
-- the tuid column is not relevant since it is never used in any predicate
ALTER TABLE parts_1 ADD PRIMARY KEY (part, sub_part);


-- phase 2
DROP TABLE IF EXISTS parts_2 CASCADE;
CREATE TABLE parts_2 AS
  SELECT p.tuid, --copy the tuids from phase 1
         --below: turn data into singleton provenance sets, i.e.
         --       array with single unique identifier
         ARRAY[nextval('annot_seq')]::pset_t AS part,
         ARRAY[nextval('annot_seq')]::pset_t AS sub_part,
         ARRAY[nextval('annot_seq')]::pset_t AS quantity
    FROM parts_1 as p
;
-- the key (part, sub_part) is dropped because values (and original predicates)
--   are gone
-- instead, the tuid becomes the new key: through log inspection, it will be
--   referenced in predicates
ALTER TABLE parts_2 ADD PRIMARY KEY (tuid);



