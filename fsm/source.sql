-- Parse the entire table of compounds
--
SELECT c.compound, c.formula, parse(0, c.formula)
FROM   compounds AS c;


