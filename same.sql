-- author: Christian Duta


-- "Same" provides a new column type, derived from integer. This column type is
-- designed in order to make its contents indifferent for DISTINCT
-- operations / duplicate elimination.

-- This is achieved through re-definition of all relevant comparison operators,
-- for example = and <>.

-- Example query and result:

-- select distinct row.*
-- from (values (1::same, 'a'),
--              (2::same, 'a'),
--              (3::same, 'b')) as row(same, payload);
--
--  same | payload
-- ------+---------
--  1    | a
--  3    | b
-- (2 rows)

-- This means that column "payload" alone determines if duplicate elimination
-- takes place. Column "same" is not relevant.


-- Installation: $ psql < same.sql
-- tested on PostgreSQL Version 14.1



DROP TYPE IF EXISTS same CASCADE;
CREATE TYPE same;

CREATE FUNCTION same_in(s cstring)
RETURNS same LANGUAGE internal IMMUTABLE AS 'int4in';
CREATE FUNCTION same_out(d same)
RETURNS cstring LANGUAGE internal IMMUTABLE AS 'int4out';

CREATE TYPE same (
  INPUT  = same_in,
  OUTPUT = same_out,
  LIKE   = integer
);

CREATE FUNCTION same_eq(same, same) RETURNS boolean AS
$$
  SELECT true;
$$  LANGUAGE SQL IMMUTABLE STRICT;
-- RETURNS boolean LANGUAGE C IMMUTABLE STRICT AS '$libdir/pg_same';

CREATE FUNCTION same_ne(same, same) RETURNS boolean AS
$$
  SELECT false;
$$  LANGUAGE SQL IMMUTABLE STRICT;
-- RETURNS boolean LANGUAGE C IMMUTABLE STRICT AS '$libdir/pg_same';

CREATE FUNCTION same_lt(same, same) RETURNS boolean AS
$$
  SELECT false;
$$  LANGUAGE SQL IMMUTABLE STRICT;
-- RETURNS boolean LANGUAGE C IMMUTABLE STRICT AS '$libdir/pg_same';

CREATE FUNCTION same_le(same, same) RETURNS boolean AS
$$
  SELECT true;
$$  LANGUAGE SQL IMMUTABLE STRICT;
-- RETURNS boolean LANGUAGE C IMMUTABLE STRICT AS '$libdir/pg_same';

CREATE FUNCTION same_gt(same, same) RETURNS boolean AS
$$
  SELECT false;
$$  LANGUAGE SQL IMMUTABLE STRICT;
-- RETURNS boolean LANGUAGE C IMMUTABLE STRICT AS '$libdir/pg_same';

CREATE FUNCTION same_ge(same, same) RETURNS boolean AS
$$
  SELECT true;
$$  LANGUAGE SQL IMMUTABLE STRICT;
-- RETURNS boolean LANGUAGE C IMMUTABLE STRICT AS '$libdir/pg_same';

CREATE FUNCTION same_cmp(same, same) RETURNS integer AS
$$
  SELECT 0;
$$  LANGUAGE SQL IMMUTABLE STRICT;
-- RETURNS integer LANGUAGE C IMMUTABLE STRICT AS '$libdir/pg_same';

CREATE FUNCTION hash_same(same) RETURNS integer AS
$$
  SELECT 0;
$$  LANGUAGE SQL IMMUTABLE STRICT;
-- RETURNS integer LANGUAGE C IMMUTABLE STRICT AS '$libdir/pg_same';

CREATE OPERATOR = (
  LEFTARG = same,
  RIGHTARG = same,
  PROCEDURE = same_eq,
  COMMUTATOR = '=',
  NEGATOR = '<>',
  RESTRICT = eqsel,
  JOIN = eqjoinsel,
  HASHES, MERGES
);

CREATE OPERATOR <> (
  LEFTARG = same,
  RIGHTARG = same,
  PROCEDURE = same_ne,
  COMMUTATOR = '<>',
  NEGATOR = '=',
  RESTRICT = neqsel,
  JOIN = neqjoinsel
);

CREATE OPERATOR < (
  LEFTARG = same,
  RIGHTARG = same,
  PROCEDURE = same_lt,
  COMMUTATOR = > ,
  NEGATOR = >= ,
  RESTRICT = scalarltsel,
  JOIN = scalarltjoinsel
);

CREATE OPERATOR <= (
  LEFTARG = same,
  RIGHTARG = same,
  PROCEDURE = same_le,
  COMMUTATOR = >= ,
  NEGATOR = > ,
  RESTRICT = scalarltsel,
  JOIN = scalarltjoinsel
);

CREATE OPERATOR > (
  LEFTARG = same,
  RIGHTARG = same,
  PROCEDURE = same_gt,
  COMMUTATOR = < ,
  NEGATOR = <= ,
  RESTRICT = scalargtsel,
  JOIN = scalargtjoinsel
);

CREATE OPERATOR >= (
  LEFTARG = same,
  RIGHTARG = same,
  PROCEDURE = same_ge,
  COMMUTATOR = <= ,
  NEGATOR = < ,
  RESTRICT = scalargtsel,
  JOIN = scalargtjoinsel
);

CREATE OPERATOR CLASS btree_same_ops
DEFAULT FOR TYPE same USING btree
AS
        OPERATOR        1       <  ,
        OPERATOR        2       <= ,
        OPERATOR        3       =  ,
        OPERATOR        4       >= ,
        OPERATOR        5       >  ,
        FUNCTION        1       same_cmp(same, same);

CREATE OPERATOR CLASS hash_same_ops
    DEFAULT FOR TYPE same USING hash AS
        OPERATOR        1       = ,
        FUNCTION        1       hash_same(same);

CREATE CAST (integer AS same) WITHOUT FUNCTION AS IMPLICIT;
CREATE CAST (same AS integer) WITHOUT FUNCTION AS IMPLICIT;