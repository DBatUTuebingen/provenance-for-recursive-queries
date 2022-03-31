-- source


-- there is a Postgres-builtin function LEAST()
--   which will not produce any why-provenance
-- least3() takes three arguments
DROP FUNCTION IF EXISTS least3(float, float, float) CASCADE;
CREATE FUNCTION least3(v1 float, v2 float, v3 float)
RETURNS float AS $$
  SELECT CASE
           WHEN v1 <= v2 AND v1 <= v3 THEN v1
           WHEN v2 <= v3 THEN v2
           ELSE v3
         END
$$ LANGUAGE SQL;


-- dtw parameters:
-- *i: current pointer in time series x
-- *j: current pointer in time series y
-- *w: search window size
DROP FUNCTION IF EXISTS dtw(int, int, int) CASCADE;
CREATE FUNCTION dtw(i int, j int, w int)
RETURNS float AS $$
BEGIN RETURN (
  SELECT CASE
    WHEN dtw.i=0 AND dtw.j=0 THEN 0.0::float
    WHEN dtw.i=0 OR  dtw.j=0 THEN 'Infinity'::float
    WHEN ABS(dtw.i-dtw.j)>dtw.w THEN 'Infinity'::float
    ELSE (SELECT dlt.delta
                 + least3(
                     dtw(dtw.i-1, dtw.j-1, dtw.w),
                     dtw(dtw.i-1, dtw.j  , dtw.w),
                     dtw(dtw.i  , dtw.j-1, dtw.w))
          FROM   delta AS dlt
          WHERE  dlt.x=dtw.i AND dlt.y=dtw.j)::float
    END
);
END;
$$ LANGUAGE PLPGSQL;



--------------------------------------------------------------------------------
-- phase 1


DROP FUNCTION IF EXISTS least3_1(tuid_t, float, float, float) CASCADE;
CREATE FUNCTION least3_1(tuid tuid_t, v1 float, v2 float, v3 float)
RETURNS float AS $$
SELECT CASE writeCase(1, least3_1.tuid,
         CASE
           WHEN v1 <= v2 AND v1 <= v3 THEN 1
           WHEN v2 <= v3 THEN 2
           ELSE 0
         END)
         WHEN 1 THEN v1
         WHEN 2 THEN v2
         WHEN 0 THEN v3
       END
$$ LANGUAGE SQL;



DROP FUNCTION IF EXISTS dtw_1(tuid_t, int, int, int) CASCADE;
CREATE FUNCTION dtw_1(tuid tuid_t, i int, j int, w int)
RETURNS float AS $$
BEGIN RETURN(
SELECT CASE writeCase(2, dtw_1.tuid,
          CASE
            WHEN dtw_1.i=0 AND dtw_1.j=0 THEN 1
            WHEN dtw_1.i=0 OR  dtw_1.j=0 THEN 2
            WHEN ABS(dtw_1.i-dtw_1.j)>dtw_1.w THEN 3
            ELSE 0
          END)
       WHEN 1 THEN 0.0::float
       WHEN 2 THEN 'Infinity'::float
       WHEN 3 THEN 'Infinity'::float
       WHEN 0 THEN (SELECT t.score
                  FROM   (SELECT writeLog(3, dtw_1.tuid, dlt.tuid) AS tuid,
                                 dlt.delta
                                 + least3_1(writeLog(4, dtw_1.tuid),
                                      dtw_1(writeLog(5, dtw_1.tuid), dtw_1.i-1, dtw_1.j-1, dtw_1.w),
                                      dtw_1(writeLog(6, dtw_1.tuid), dtw_1.i-1, dtw_1.j  , dtw_1.w),
                                      dtw_1(writeLog(7, dtw_1.tuid), dtw_1.i  , dtw_1.j-1, dtw_1.w)) AS score
                          FROM   delta_1 AS dlt
                          WHERE  dlt.x=dtw_1.i AND dlt.y=dtw_1.j) AS t(tuid, score))
       END);
END;
$$ LANGUAGE PLPGSQL;


--------------------------------------------------------------------------------
-- phase 2

DROP FUNCTION IF EXISTS least3_2(tuid_t, pset, pset, pset) CASCADE;
CREATE FUNCTION least3_2(tuid tuid_t, v1 pset, v2 pset, v3 pset)
RETURNS pset AS $$
SELECT CASE readCase(1, least3_2.tuid)
            WHEN 1 THEN v1 | toY(v1 | v2 | v3)
            WHEN 2 THEN v2 | toY(v1 | v2 | v3)
            WHEN 0 THEN v3 | toY(v1 | v2 | v3)
            ELSE empty()
        END ::pset;
$$ LANGUAGE SQL;


DROP FUNCTION IF EXISTS dtw_2(tuid_t, pset, pset, pset) CASCADE;
CREATE FUNCTION dtw_2(tuid tuid_t, i pset, j pset, w pset)
RETURNS pset AS $$
BEGIN RETURN(
SELECT CASE readCase(2, dtw_2.tuid)
         WHEN 1 THEN toY(dtw_2.i | dtw_2.j)
         WHEN 2 THEN toY(dtw_2.i | dtw_2.j)
         WHEN 3 THEN toY(dtw_2.i | dtw_2.j | dtw_2.w)
         WHEN 0 THEN
           (SELECT t.score
            FROM   (SELECT  l.tuid AS tuid,
                            dlt.delta
                            | least3_2(readLog(4, dtw_2.tuid),
                                dtw_2(readLog(5, dtw_2.tuid), dtw_2.i, dtw_2.j, dtw_2.w),
                                dtw_2(readLog(6, dtw_2.tuid), dtw_2.i, dtw_2.j, dtw_2.w),
                                dtw_2(readLog(7, dtw_2.tuid), dtw_2.i, dtw_2.j, dtw_2.w))
                            | wh.y
                                AS score
                    FROM    delta_2 AS dlt,
                            readLog(3, dtw_2.tuid, dlt.tuid) AS l(tuid),
                            toY(dlt.x | dtw_2.i | dlt.y | dtw_2.j) AS wh(y)
                            ) AS t(tuid, score))
            | toY(dtw_2.i|dtw_2.j|dtw_2.w)
         ELSE empty()
         END ::pset);
END;
$$ LANGUAGE PLPGSQL;

--------------------------------------------------------------------------------
-- phase 2e
-- where-prov. without why-prov.

DROP FUNCTION IF EXISTS least3_2e(tuid_t, pset, pset, pset) CASCADE;
CREATE FUNCTION least3_2e(tuid tuid_t, v1 pset, v2 pset, v3 pset)
RETURNS pset AS $$
SELECT CASE readCase(1, least3_2e.tuid)
            WHEN 1 THEN v1
            WHEN 2 THEN v2
            WHEN 0 THEN v3
            ELSE empty()
       END ::pset
$$ LANGUAGE SQL;


DROP FUNCTION IF EXISTS dtw_2e(tuid_t, pset, pset, pset) CASCADE;
CREATE FUNCTION dtw_2e(tuid tuid_t, i pset, j pset, w pset)
RETURNS pset AS $$
BEGIN RETURN(
SELECT CASE readCase(2, dtw_2e.tuid)
         WHEN 1 THEN empty()
         WHEN 2 THEN empty()
         WHEN 3 THEN empty()
         WHEN 0 THEN
           (SELECT t.score
            FROM   (SELECT  l.tuid AS tuid,
                            dlt.delta
                            | least3_2e(readLog(4, dtw_2e.tuid),
                                dtw_2e(readLog(5, dtw_2e.tuid), dtw_2e.i, dtw_2e.j, dtw_2e.w),
                                dtw_2e(readLog(6, dtw_2e.tuid), dtw_2e.i, dtw_2e.j, dtw_2e.w),
                                dtw_2e(readLog(7, dtw_2e.tuid), dtw_2e.i, dtw_2e.j, dtw_2e.w))
                                AS dtw
                    FROM    delta_2 AS dlt,
                            readLog(3, dtw_2e.tuid, dlt.tuid) AS l(tuid)
                            ) AS t(tuid, score))
         ELSE empty()
         END ::pset);
END;
$$ LANGUAGE PLPGSQL;




--------------------------------------------------------------------------------
-- provenance size


DROP FUNCTION IF EXISTS reportPsize2(text, text) CASCADE;
CREATE OR REPLACE FUNCTION reportPsize2(scaleFactor text, phase text)
RETURNS TABLE(scaleFactor text, phase text, rows text, psize text) AS
$$

SELECT
    scaleFactor,
    phase,
    '1' AS rows,
    sum(pset_cardinality(b.res)) AS psize
FROM (SELECT dtw_2(readLog(8), empty(), empty(), empty())) AS b(res)

$$ LANGUAGE SQL;







DROP FUNCTION IF EXISTS reportPsize2e(text, text) CASCADE;
CREATE OR REPLACE FUNCTION reportPsize2e(scaleFactor text, phase text)
RETURNS TABLE(scaleFactor text, phase text, rows text, psize text) AS
$$

SELECT
    scaleFactor,
    phase,
    '1' AS rows,
    sum(pset_cardinality(b.res)) AS psize
FROM (SELECT dtw_2e(readLog(8), empty(), empty(), empty())) AS b(res)

$$ LANGUAGE SQL;




