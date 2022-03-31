-- Longest common subsequence
--
-- For example, consider the sequences (ABCD) and (ACBAD).
-- They have 5 length-2 common subsequences: (AB), (AC), (AD), (BD), and (CD);
-- 2 length-3 common subsequences: (ABD) and (ACD); and no longer common subsequences.
-- So (ABD) and (ACD) are their longest common subsequences.
--
-- Example source: https://en.wikipedia.org/wiki/Longest_common_subsequence_problem



-- there exists a builtin COALESCE() but we do not use it here
-- this handcrafted version improves the provenance accuracy
DROP FUNCTION IF EXISTS coalesce2(anyelement, anyelement) CASCADE;
CREATE FUNCTION coalesce2(v1 anyelement, v2 anyelement) RETURNS anyelement AS
$$
SELECT
  CASE
    WHEN v1 IS NOT NULL THEN v1
    ELSE v2
  END
$$ LANGUAGE SQL;



DROP FUNCTION IF EXISTS greatest2(int, int) CASCADE;
CREATE FUNCTION greatest2(v1 int, v2 int)
RETURNS int AS $$
SELECT
  CASE
    WHEN v1 >= v2 THEN v1
    ELSE v2
  END
$$ LANGUAGE SQL;



-- arguments:
-- l_seq: id of the left sequence
-- r_seq: id of the right sequence
-- l_pos: position in the left sequence
-- r_pos: position in the right sequence
DROP FUNCTION IF EXISTS lcs(int, int, int, int) CASCADE;
CREATE OR REPLACE FUNCTION lcs(l_seq int, r_seq int, l_pos int, r_pos int)
RETURNS int AS $$
SELECT coalesce2 (
  (SELECT CASE
            WHEN l.val <> r.val
            THEN greatest2(lcs(l_seq, r_seq, l_pos+1, r_pos),
                           lcs(l_seq, r_seq, l_pos, r_pos+1))
            ELSE 1 + lcs(l_seq, r_seq, l_pos+1, r_pos+1)
          END
     FROM sequences AS l,
          sequences AS r
    WHERE (l.seq,l.pos) = (l_seq,l_pos)
      AND (r.seq,r.pos) = (r_seq,r_pos)),
  0)
$$ LANGUAGE SQL;


--------------------------------------------------------------------------------
-- phase 1


DROP FUNCTION IF EXISTS coalesce2_1(tuid_t, anyelement, anyelement) CASCADE;
CREATE FUNCTION coalesce2_1(tuid tuid_t, v1 anyelement, v2 anyelement)
RETURNS int AS $$
SELECT
  CASE writeCase(1, coalesce2_1.tuid,
                 CASE
                   WHEN v1 IS NOT NULL THEN 1
                   ELSE 0
                 END)
    WHEN 1 THEN v1
    ELSE v2
  END
$$ LANGUAGE SQL;



DROP FUNCTION IF EXISTS greatest2_1(tuid_t, int, int) CASCADE;
CREATE FUNCTION greatest2_1(tuid tuid_t, v1 int, v2 int)
RETURNS int AS $$
SELECT
  CASE writeCase(2, greatest2_1.tuid,
                 CASE
                   WHEN v1 >= v2 THEN 1
                   ELSE 0
                 END)
    WHEN 1 THEN v1
    ELSE v2
  END
$$ LANGUAGE SQL;



DROP FUNCTION IF EXISTS lcs_1(tuid_t, int, int, int, int) CASCADE;
CREATE OR REPLACE FUNCTION lcs_1(tuid tuid_t, l_seq int, r_seq int, l_pos int, r_pos int)
RETURNS int AS $$
SELECT coalesce2_1(writeLog(3, lcs_1.tuid), (
  SELECT t.val
  FROM
    (SELECT writelog(4, l.tuid, r.tuid, lcs_1.tuid) AS tuid,
            CASE writeCase(5, l.tuid, r.tuid,
                    CASE
                      WHEN l.val <> r.val THEN 1
                      ELSE 0
                    END)
              WHEN 1
              THEN greatest2_1(writeLog(6, lcs_1.tuid),
                               lcs_1(writeLog(7, lcs_1.tuid), l_seq, r_seq, l_pos+1, r_pos),
                               lcs_1(writeLog(8, lcs_1.tuid), l_seq, r_seq, l_pos, r_pos+1))
              ELSE 1 + lcs_1(writeLog(9, lcs_1.tuid), l_seq, r_seq, l_pos+1, r_pos+1)
            END AS val
     FROM sequences_1 AS l,
          sequences_1 AS r
     WHERE (l.seq,l.pos) = (l_seq,l_pos)
       AND (r.seq,r.pos) = (r_seq,r_pos)) AS t(tuid, val)), 0)
$$ LANGUAGE SQL;


--------------------------------------------------------------------------------
-- phase 2


DROP FUNCTION IF EXISTS coalesce2_2(tuid_t, pset_t, pset_t) CASCADE;
CREATE FUNCTION coalesce2_2(tuid tuid_t, v1 pset_t, v2 pset_t)
RETURNS pset_t AS $$
SELECT
  CASE readCase(1, coalesce2_2.tuid)
    WHEN 1 THEN v1 || toY(v1)
    WHEN 0 THEN v2 || toY(v1)
    ELSE empty()
  END
$$ LANGUAGE SQL;



DROP FUNCTION IF EXISTS greatest2_2(tuid_t, pset_t, pset_t) CASCADE;
CREATE FUNCTION greatest2_2(tuid tuid_t, v1 pset_t, v2 pset_t)
RETURNS pset_t AS $$
SELECT
  CASE readCase(2, greatest2_2.tuid)
    WHEN 1 THEN v1 || toY(v1 || v2)
    WHEN 0 THEN v2 || toY(v1 || v2)
    ELSE empty()
  END
$$ LANGUAGE SQL;



DROP FUNCTION IF EXISTS lcs_2(tuid_t, pset_t, pset_t, pset_t, pset_t) CASCADE;
CREATE OR REPLACE FUNCTION lcs_2(tuid tuid_t, l_seq pset_t, r_seq pset_t, l_pos pset_t, r_pos pset_t)
RETURNS pset_t AS $$
SELECT coalesce2_2(readLog(3, lcs_2.tuid), (
  SELECT t.val
  FROM
    (SELECT log.tuid,
            (CASE readCase(5, l.tuid, r.tuid)
               WHEN 1
               THEN greatest2_2(readOne(6, lcs_2.tuid),
                                lcs_2(readOne(7, lcs_2.tuid), l_seq, r_seq, l_pos, r_pos),
                                lcs_2(readOne(8, lcs_2.tuid), l_seq, r_seq, l_pos, r_pos)) || toY(l.val || r.val)
               WHEN 0
               THEN lcs_2(readOne(9, lcs_2.tuid), l_seq, r_seq, l_pos, r_pos) || toY(l.val || r.val)
               ELSE empty()
             END) || wh.y AS val
     FROM sequences_2 AS l,
          sequences_2 AS r,
          readLog(4, l.tuid, r.tuid, lcs_2.tuid) AS log(tuid),
          toY(l.seq || l.pos || l_seq || l_pos || r.seq || r.pos || r_seq || r_pos) AS wh(y)
     ) AS t(tuid, val)), empty())
$$ LANGUAGE SQL;




--------------------------------------------------------------------------------
-- phase 2e


DROP FUNCTION IF EXISTS coalesce2_2e(tuid_t, pset_t, pset_t) CASCADE;
CREATE FUNCTION coalesce2_2e(tuid tuid_t, v1 pset_t, v2 pset_t)
RETURNS pset_t AS $$
SELECT
  CASE readCase(1, coalesce2_2e.tuid)
    WHEN 1 THEN v1
    WHEN 0 THEN v2
    ELSE empty()
  END
$$ LANGUAGE SQL;



DROP FUNCTION IF EXISTS greatest2_2e(tuid_t, pset_t, pset_t) CASCADE;
CREATE FUNCTION greatest2_2e(tuid tuid_t, v1 pset_t, v2 pset_t)
RETURNS pset_t AS $$
SELECT
  CASE readCase(2, greatest2_2e.tuid)
    WHEN 1 THEN v1
    WHEN 0 THEN v2
    ELSE empty()
  END
$$ LANGUAGE SQL;



DROP FUNCTION IF EXISTS lcs_2e(tuid_t, pset_t, pset_t, pset_t, pset_t) CASCADE;
CREATE OR REPLACE FUNCTION lcs_2e(tuid tuid_t, l_seq pset_t, r_seq pset_t, l_pos pset_t, r_pos pset_t)
RETURNS pset_t AS $$
SELECT coalesce2_2e(readLog(3, lcs_2e.tuid), (
  SELECT t.val
  FROM
    (SELECT log.tuid,
            (CASE readCase(5, l.tuid, r.tuid)
               WHEN 1
               THEN greatest2_2e(readOne(6, lcs_2e.tuid),
                                lcs_2e(readOne(7, lcs_2e.tuid), l_seq, r_seq, l_pos, r_pos),
                                lcs_2e(readOne(8, lcs_2e.tuid), l_seq, r_seq, l_pos, r_pos))
               WHEN 0
               THEN lcs_2e(readOne(9, lcs_2e.tuid), l_seq, r_seq, l_pos, r_pos)
               ELSE empty()
             END) AS val
     FROM sequences_2 AS l,
          sequences_2 AS r,
          readLog(4, l.tuid, r.tuid, lcs_2e.tuid) AS log(tuid)
     ) AS t(tuid, val)), empty())
$$ LANGUAGE SQL;



