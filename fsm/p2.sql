
SELECT c.tuid,
       c.compound,
       c.formula,
       dd(parse_2(readOne(8, c.tuid), empty(), c.formula)) AS parse
FROM   compounds_2 AS c;

