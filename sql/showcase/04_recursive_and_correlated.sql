-- Recursive CTE identifies uninterrupted runs of positive population growth.
WITH RECURSIVE ordered AS (
    SELECT
        municipality_key,
        year_key,
        population_growth_rate,
        ROW_NUMBER() OVER (PARTITION BY municipality_key ORDER BY year_key) AS sequence_no
    FROM analytics.mart_population_growth
), streaks AS (
    SELECT municipality_key, year_key, sequence_no, 1 AS streak_length
    FROM ordered
    WHERE sequence_no = 1 AND population_growth_rate > 0
    UNION ALL
    SELECT o.municipality_key, o.year_key, o.sequence_no, s.streak_length + 1
    FROM streaks s
    JOIN ordered o
      ON o.municipality_key = s.municipality_key AND o.sequence_no = s.sequence_no + 1
    WHERE o.population_growth_rate > 0
)
SELECT municipality_key, MAX(streak_length) AS longest_growth_streak
FROM streaks
GROUP BY municipality_key;

-- Correlated subquery compares each municipality with its own region and year.
SELECT s.*
FROM analytics.mv_municipality_scorecard s
WHERE s.population_growth_rate > (
    SELECT AVG(peer.population_growth_rate)
    FROM analytics.mv_municipality_scorecard peer
    WHERE peer.region_code = s.region_code AND peer.year = s.year
);

