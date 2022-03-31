
SELECT c.tuid,
       c.compound, c.formula, parse_1(writeLog(8, c.tuid), 0, c.formula)
FROM   compounds_1 AS c;

