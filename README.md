

# Overview


This repository contains supplementary material for the paper submission

*Data Provenance for Recursive SQL Queries*

to TaPP 2022.


Benjamin Dietrich •
Tobias Mueller •
Torsten Grust


# Query Evaluation

## Requirements

We have tested all queries on PostgreSQL version 14.1.


## Auxiliary File: `aux.sql`

This file provides necessary definitions (like types, tables, and UDFs) to turn an ordinary PostgreSQL installation into a runtime for provenance analysis. 
These are user-level definitions that do not invade the PostgreSQL internals, 
a salient feature of the two-phase approach to provenance derivation.

Installation (`psql` denotes the PostgreSQL REPL): `$ psql < aux.sql`

More information can be found in the `aux.sql` file itself.


## Auxiliary File: `same.sql`

This file provides a new data type `same`. Values of this type are ignored by SQL **DISTINCT** operations
which aids provenance derivation of recursive CTEs with `UNION DISTINCT` semantics.

Note: We mention the treatment of `UNION DISTINCT` at the end of Section 2.2,
but only cover `UNION ALL` semantics in the present paper.

Installation: `$ psql < same.sql`

More information can be found in the `same.sql` file.


# Examples

Each example consists of

* example data (in file `tables.sql`),
* original (`source.sql`) query,
* the queries rewritten for Phases 1 and 2 of provenance derivation (`p1.sql`, `p2.sql`), and
* a `Makefile` for convenience.

Examples based on recursive UDFs come with an additional `udfs.sql` file that hold the
function definitions.

The additional file `p2e.sql` also implements Phase 2 of provenance derivation 
but is restricted to *where*-provenance (and thus ignores *why*-provenance).


## `bom`

This example evaluates the *bill of materials* for a humanoid robot. 
It is an example of `WITH RECURSIVE` with `UNION ALL` semantics and it is discussed in the paper.


### Reading the Output

**Example query output:**

```
$ psql < p1.sql
 tuid | sub_part | quantity
------+----------+----------
    8 | head     |        1
    9 | body     |        1
   10 | leg      |        2
   11 | arm      |        2
   12 | foot     |        2
   13 | finger   |       10
(6 rows)

$ psql < p2.sql
 tuid |        sub_part        |          quantity
------+------------------------+-----------------------------
    8 | {-1,2}                 | {-1,3}
    9 | {5,-4}                 | {6,-4}
   11 | {8,-7,-5,-4}           | {-7,9,-5,6,-4}
   10 | {-10,-5,-4,11}         | {-10,-5,6,12,-4}
   13 | {-7,-8,-5,-13,14,-4}   | {-7,9,-8,15,-5,6,-13,-4}
   12 | {-16,-10,-5,-11,-4,17} | {-16,18,-10,-5,6,-11,12,-4}
(6 rows)
```

(Column `tuid` represent column `ϱ` in the paper.  Negative cell identifiers like `-1`
indicate *why*-provenance, positive identifiers indicate *where*-provenance.)

To illustrate, the data provenance of *head* (in row *8* and column `sub_part`) can be 
found in the corresponding row (*8*) and column (`sub_part`) of the Phase 2 output. 
The provenance identifiers in *{-1,2}* found in that table cell 
can be traced back to the base tables.


**Example base tables:**

```
postgres=# table parts_1;
 tuid |   part   | sub_part | quantity
------+----------+----------+----------
    1 | humanoid | head     |        1
    2 | humanoid | body     |        1
    3 | body     | arm      |        2
    4 | body     | leg      |        2
    5 | arm      | finger   |        5
    6 | leg      | foot     |        1
    7 | chassis  | wheel    |        4
(7 rows)

postgres=# table parts_2;
 tuid | part | sub_part | quantity
------+------+----------+----------
    1 | {1}  | {2}      | {3}
    2 | {4}  | {5}      | {6}
    3 | {7}  | {8}      | {9}
    4 | {10} | {11}     | {12}
    5 | {13} | {14}     | {15}
    6 | {16} | {17}     | {18}
    7 | {19} | {20}     | {21}
(7 rows)
```

Cell identifier `-1` sits in row *1* of column `part`. 
In the corresponding row and column of Phase 1, we find the data value `humanoid`. 

Interpretation: the input value `humanoid` has been inspected to decide 
the existence of output value `head`. Please see Figure 4 and its discussion in 
the paper for more details on how to read these tables.


## `dtw`

This example evaluates the *Dynamic Time Warping* (DTW) score of two time series. 
It is an example of a recursive UDF and is discussed in the paper.


### `dtw-experiments`

For completeness, we have also provided the DTW queries that have been used 
in Section 3.2 (experiments). However, these queries cannot be evaluated as is:
we do not provide the required PostgreSQL bit set extension here.  Please approach
us if you are interested.


## `fsm`

This example implements a finite state machine in SQL. This machine is used to realize a 
parser for chemical formulae. It is an example of a recursive UDF.


## `lcs`

This query computes the longest common subsequence of two strings. It is an example of a recursive UDF.


## `mq`

This *Marching Squares* example implements a 2x2 pixel square that moves over the height 
profile of a hilly landscape. The result table contains the track of said square along the
hill's perimeter. This is an example for `WITH RECURSIVE` in `UNION DISTINCT` semantics.


## `reachable`

This query computes the reachable nodes in a directed graph. 
It is an example for `WITH RECURSIVE` in `UNION DISTINCT` semantics.

