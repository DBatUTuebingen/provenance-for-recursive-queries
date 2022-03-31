

DROP DOMAIN IF EXISTS state CASCADE;
CREATE DOMAIN state AS integer;

-- transitions
DROP TABLE IF EXISTS fsm CASCADE;
CREATE TABLE fsm (
  source  state   NOT NULL, -- source state of transition
  label   char(1) NOT NULL, -- transition label (input)
  target  state  NOT NULL, -- target state of transition
  final   boolean NOT NULL  -- is source a final state?
);
ALTER TABLE fsm ADD PRIMARY KEY (source, label);
-- fsm has the functional dependency: source -> final (not enforced by DBMS)


-- create DFA transition table for regular expression
-- ([A-Za-z]+[₀-₉]*([⁰-⁹]*[⁺⁻])?)+
INSERT INTO fsm(source, label, target, final)
SELECT trans.source, labels.c, trans.target, trans.final
FROM (VALUES
  (0, 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz',           1, false ),
  (1, 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz₀₁₂₃₄₅₆₇₈₉', 1, true ),
  (1, '⁰¹²³⁴⁵⁶⁷⁸⁹',                                                     2, true),
  (1, '⁺⁻',                                                             3, true ),
  (2, '⁰¹²³⁴⁵⁶⁷⁸⁹',                                                     2, false),
  (2, '⁺⁻',                                                             3, false ),
  (3, 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz',           1, true )
  ) AS trans(source, labels, target, final),
regexp_split_to_table(trans.labels, '') WITH ORDINALITY labels(c,n);



-- chemical compounds
DROP TABLE IF EXISTS compounds CASCADE;
CREATE TABLE compounds (
  nr       serial,
  compound text,
  formula  text
);
ALTER TABLE compounds ADD PRIMARY KEY (nr);

INSERT INTO compounds (compound, formula) VALUES
-- ('Water', 'H₂O');
('Glucose', 'C₆H₁₂O₆');


--------------------------------------------------------------------------------
-- phase 1


DROP TABLE IF EXISTS fsm_1 CASCADE;
CREATE TABLE fsm_1 AS
    SELECT nextval('tuid_seq')::INT tuid,
           f.*
    FROM fsm as f
;
ALTER TABLE fsm_1 ADD PRIMARY KEY (source, label);


DROP TABLE IF EXISTS compounds_1 CASCADE;
CREATE TABLE compounds_1 AS
    SELECT nextval('tuid_seq')::tuid_t AS tuid,
           f.*
    FROM compounds as f
;
ALTER TABLE compounds_1 ADD PRIMARY KEY (nr);


-- phase 2
DROP TABLE IF EXISTS fsm_2 CASCADE;
CREATE TABLE fsm_2 AS
    SELECT f.tuid,
           ARRAY[nextval('annot_seq')]::pset_t AS source,
           ARRAY[nextval('annot_seq')]::pset_t AS label,
           ARRAY[nextval('annot_seq')]::pset_t AS target,
           ARRAY[nextval('annot_seq')]::pset_t AS final
    FROM fsm_1 as f
;
ALTER TABLE fsm_2 ADD PRIMARY KEY (tuid);


DROP TABLE IF EXISTS compounds_2 CASCADE;
CREATE TABLE compounds_2 AS
    SELECT c.tuid,
           ARRAY[nextval('annot_seq')]::pset_t AS nr,
           ARRAY[nextval('annot_seq')]::pset_t AS compound,
           ARRAY[nextval('annot_seq')]::pset_t AS formula
    FROM compounds_1 as c
;
ALTER TABLE compounds_2 ADD PRIMARY KEY (tuid);


