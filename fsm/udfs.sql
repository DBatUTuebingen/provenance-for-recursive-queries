-- source query

-- there exists a builtin COALESCE() but we do not use it here
-- this handcrafted version improves the provenance accuracy
DROP FUNCTION IF EXISTS coalesce2(anyelement, anyelement) CASCADE;
CREATE FUNCTION coalesce2(v1 anyelement, v2 anyelement)
RETURNS anyelement AS $$
SELECT
  CASE
    WHEN v1 IS NOT NULL THEN v1
    ELSE v2
  END
$$ LANGUAGE SQL;


-- main function
DROP FUNCTION IF EXISTS parse(int, text) CASCADE;
CREATE FUNCTION parse(state int, input text)
RETURNS boolean AS $$
  SELECT
    CASE WHEN length(input) = 0
         THEN (SELECT DISTINCT edge.final --DISTINCT will yield max. 1 row
                                          --  due to functional depdendency
                                          --  in data design
               FROM   fsm AS edge
               WHERE  state = edge.source)
         ELSE coalesce2(parse((
                SELECT edge.target
                FROM fsm AS edge
                WHERE state = edge.source
                AND   edge.label = left(input, 1)
              ), right(input, -1)), false)
    END
$$ LANGUAGE SQL;


--------------------------------------------------------------------------------
-- normalized

DROP FUNCTION IF EXISTS parse_normalized(int, text) CASCADE;
CREATE FUNCTION parse_normalized(state int, input text)
RETURNS boolean AS $$
  SELECT
    CASE WHEN length(input) = 0
         THEN (--normalization: split up DISTINCT and WHERE
               --               i.e., create an additional SFW expression
               SELECT DISTINCT ON(v.final)
                      v.final
               FROM (
                       SELECT edge.final
                       FROM   fsm AS edge
                       WHERE  state = edge.source
                    ) AS v
              )
         ELSE coalesce2(parse_normalized((
                SELECT edge.target
                FROM fsm AS edge
                WHERE state = edge.source
                AND   edge.label = left(input, 1)
         ), right(input, -1)), false)
    END
$$ LANGUAGE SQL;


--------------------------------------------------------------------------------
-- phase 1


DROP FUNCTION IF EXISTS coalesce2_1(tuid_t, anyelement, anyelement) CASCADE;
CREATE FUNCTION coalesce2_1(tuid tuid_t, v1 anyelement, v2 anyelement)
RETURNS anyelement AS $$
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


DROP FUNCTION IF EXISTS parse_1(tuid_t, int, text) CASCADE;
CREATE FUNCTION parse_1(tuid tuid_t, state int, input text)
RETURNS boolean AS $$
SELECT
  CASE
    writeCase(2,parse_1.tuid,
      CASE WHEN length(input) = 0 THEN 1
      ELSE 0
      END
    )
    WHEN 1
    THEN (SELECT v3.final
            FROM (
                  SELECT writeLog(3, v2.tuid, parse_1.tuid) AS tuid,
                         v2.final
                  FROM (SELECT DISTINCT ON(v1.final)
                               v1.tuid,
                               v1.final
                        FROM (SELECT writeLog(4, edge.tuid, parse_1.tuid) AS tuid,
                                     edge.final
                              FROM fsm_1 AS edge
                              WHERE state = edge.source) AS v1) AS v2
                  ) AS v3(tuid, final))
    ELSE coalesce2_1(writeLog(5, parse_1.tuid), parse_1(writeLog(6, parse_1.tuid), (
      SELECT v3.target
      FROM
           (SELECT writeLog(7, edge.tuid, parse_1.tuid) AS tuid,
                  edge.target
           FROM fsm_1 AS edge
           WHERE state = edge.source
           AND   edge.label = left(input, 1)) AS v3(tuid, target)
    ), right(input, -1)), false)
  END
$$ LANGUAGE SQL;




--------------------------------------------------------------------------------
-- phase 2


DROP FUNCTION IF EXISTS coalesce2_2(tuid_t, pset_t, pset_t) CASCADE;
CREATE FUNCTION coalesce2_2(tuid tuid_t, v1 pset_t, v2 pset_t)
RETURNS pset_t AS $$
SELECT (
CASE readCase(1, coalesce2_2.tuid)
  WHEN 1 THEN v1 || toY(v1)
  WHEN 0 THEN v2 || toY(v1)
  ELSE empty()
END) :: pset_t
$$ LANGUAGE SQL;



DROP FUNCTION IF EXISTS parse_2(tuid_t, pset_t, pset_t) CASCADE;
CREATE FUNCTION parse_2(tuid tuid_t, state pset_t, input pset_t)
RETURNS pset_t AS $$
SELECT (
CASE
  readCase(2,parse_2.tuid)
  WHEN 1
  THEN (SELECT v2.final
          FROM (SELECT log.tuid,
                       v1.final || wh.y AS final
                FROM (SELECT log.tuid AS tuid,
                             edge.final || wh.y AS final
                      FROM fsm_2 AS edge,
                           readLog(4, edge.tuid, parse_2.tuid) AS log(tuid),
                           toY(state || edge.source) AS wh(y)
                      ) AS v1,
                      readLog(3, v1.tuid, parse_2.tuid) AS log(tuid),
                      toY(v1.final) AS wh(y)) AS v2(tuid, final)) || toY(input)
  WHEN 0
  THEN coalesce2_2(readOne(5, parse_2.tuid), parse_2(readOne(6, parse_2.tuid), (
    SELECT v3.target
    FROM
         (SELECT log.tuid AS tuid,
                 edge.target || wh.y
         FROM fsm_2 AS edge,
              readLog(7, edge.tuid, parse_2.tuid) AS log(tuid),
              toY(state || edge.source || edge.label || input) AS wh(y)
         ) AS v3(tuid, target)
  ), parse_2.input || empty()), empty()) || toY(input)
  ELSE empty()
END)::pset_t
$$ LANGUAGE SQL;



--------------------------------------------------------------------------------
-- phase 2e


DROP FUNCTION IF EXISTS coalesce2_2e(tuid_t, pset_t, pset_t) CASCADE;
CREATE FUNCTION coalesce2_2e(tuid tuid_t, v1 pset_t, v2 pset_t)
RETURNS pset_t AS $$
SELECT (
CASE readCase(1, coalesce2_2e.tuid)
  WHEN 1 THEN v1
  WHEN 0 THEN v2
  ELSE empty()
END) :: pset_t
$$ LANGUAGE SQL;



DROP FUNCTION IF EXISTS parse_2e(tuid_t, pset_t, pset_t) CASCADE;
CREATE FUNCTION parse_2e(tuid tuid_t, state pset_t, input pset_t)
RETURNS pset_t AS $$
SELECT (
CASE
  readCase(2,parse_2e.tuid)
  WHEN 1
  THEN (SELECT v2.final
          FROM (SELECT log.tuid,
                       v1.final AS final
                FROM (SELECT log.tuid AS tuid,
                             edge.final AS final
                      FROM fsm_2 AS edge,
                           readLog(4, edge.tuid, parse_2e.tuid) AS log(tuid)
                      ) AS v1,
                      readLog(3, v1.tuid, parse_2e.tuid) AS log(tuid)
                      ) AS v2(tuid, final))
  WHEN 0
  THEN coalesce2_2e(readOne(5, parse_2e.tuid), parse_2e(readOne(6, parse_2e.tuid), (
    SELECT v3.target
    FROM
         (SELECT log.tuid AS tuid,
                 edge.target
         FROM fsm_2 AS edge,
              readLog(7, edge.tuid, parse_2e.tuid) AS log(tuid)
         ) AS v3(tuid, target)
  ), parse_2e.input || empty()), empty())
  ELSE empty()
END)::pset_t
$$ LANGUAGE SQL;


