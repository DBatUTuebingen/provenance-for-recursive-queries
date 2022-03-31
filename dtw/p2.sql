
SELECT dd(dtw_2(readLog(8),
                empty(), empty(), empty() --query constants become empty sets
                )) AS score;

