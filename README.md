
# Overview


This repository contains supplementery material for the paper submission

*Data Provenance for Recursive SQL Queries*

to TaPP 2022.


Benjamin Dietrich
Tobias Mueller
Torsten Grust


# Query Evaluation

## Requirements

We have tested all queries on PostgreSQL V. 14.1.


## Auxiliary File: aux.sql

This file provides necessary definitions (like, types, tables and UDFs) to turn an ordinary PostgreSQL installation into a runtime for provenance analysis. These definitions are low invasive which is one of the strong points of our approach to provenance analysis.

Installation: $ psql < aux.sql

More information can be found in the aux.sql file.


## Auxiliary File: same.sql

This file provides a new column type. Contents of such columns are ignored by SQL **DISTINCT** operations. Such logic would be required for recursive queries with **UNION DISTINCT** semantics.

Please note that this is a mere outlook for future research. In the paper submission we only cover **UNION ALL** semantics.

Installation: $ psql < same.sql

More information can be found in the same.sql file.


# Examples

Each example consists of

* example data (=tables.sql),
* original (=source.sql) query,
* the queries rewritten for provenance analysis (p1.sql, p2.sql) and
* a make file for convenient evaluation.

UDF examples have an additional udf.sql file.

The additional file p2e.sql also implements phase 2 of the provenance analysis but is restricted to where-provenance (i.e., without why-provenance).


## bom

This example evaluates the Bill of Materials for a humanoid robot. It is an example for **WITH RECURSIVE** in **UNION ALL** semantics and discussed in the paper.


### Reading the Output

Example output:

```
psql < p1.sql
 tuid | sub_part | quantity
------+----------+----------
    8 | head     |        1
    9 | body     |        1
   10 | leg      |        2
   11 | arm      |        2
   12 | foot     |        2
   13 | finger   |       10
(6 rows)

psql < p2.sql
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

For example, the data provenance of *head* (in row *8* and column *sub_part*) can be found in the corresponding row (*8*) and column (*sub_part*) of phase 2. Then, the provenance identifiers in *{-1,2}* can be traced back to the base tables.


Base tables:

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

Identifier *-1* sits in row *1* of column *part*. In the corresponding row and column of phase 1, we find the data value *humanoid*. The minus in *-1* identifies this as a relationship of why-provenance (while positive signs represent where-provenance).

Put in natural language, this means that the input value *humanoid* has been inspected to decide about the existence of output value *head*. Please see Figure 4 and its discussion in the paper for more details on how to read the tables.


## dtw

This examples evaluates the DTW value of two time series. It is an example for a recursive UDF and discussed in the paper.


### dtw-experiments

For completeness, we have also provided the DTW queries that have been used in the quantitative experiments. However, these queries cannot be evaluated. We do not provide the required *pset* plugin here.


## fsm

This example implements a finite state machine in SQL. This machine is used to realize a parser for chemical formulae. It is an example for a recursive UDF.


## lcs

This query computes the longest common subsequence of two strings. It is an example for a recursive UDF.


## mq

The marching squares example implements a 2x2 square that moves over the height profile of a hilly landscape. The result table contains the track of said square. This track corresponds to the mountain edge. This is an example for **WITH RECURSIVE** in **UNION DISTINCT** semantics.


## reachable

This query computes the reachable nodes in a directed graph. It is an example for **WITH RECURSIVE** in **UNION DISTINCT** semantics.


