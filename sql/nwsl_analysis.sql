
-- Set up my NWSL database
CREATE DATABASE IF NOT EXISTS nwsl_analytics;

USE nwsl_analytics;

SELECT DATABASE();


-- Check the imported tables
SHOW TABLES;

SELECT COUNT(*) AS player_records
FROM nwsl_players_cleaned;

SELECT COUNT(*) AS team_records
FROM nwsl_teams_cleaned;

SELECT *
FROM nwsl_players_cleaned
LIMIT 10;

SELECT *
FROM nwsl_teams_cleaned
LIMIT 10;


-- Top 10 goal scorers
SELECT
    player_name,
    SUM(goals) AS total_goals
FROM nwsl_players_cleaned
GROUP BY player_id, player_name
ORDER BY total_goals DESC
LIMIT 10;


-- Top 10 players with the most assists
SELECT
    player_name,
    SUM(goal_assist) AS total_assists
FROM nwsl_players_cleaned
GROUP BY player_id, player_name
ORDER BY total_assists DESC
LIMIT 10;


-- Total goals scored by each team
SELECT
    team,
    SUM(goals) AS total_goals
FROM nwsl_teams_cleaned
GROUP BY team
ORDER BY total_goals DESC;


-- Average goals scored per game by each team
SELECT
    team,
    SUM(goals) AS total_goals,
    COUNT(goals) AS matches_played,
    ROUND(AVG(goals), 2) AS avg_goals_per_game
FROM nwsl_teams_cleaned
GROUP BY team
ORDER BY avg_goals_per_game DESC;


-- Compare passing accuracy across teams
SELECT
    team,
    SUM(accurate_pass) AS completed_passes,
    SUM(total_pass) AS total_passes,
    ROUND(
        SUM(accurate_pass) * 100.0 /
        NULLIF(SUM(total_pass), 0),
        2
    ) AS passing_accuracy
FROM nwsl_teams_cleaned
WHERE accurate_pass IS NOT NULL
    AND total_pass IS NOT NULL
GROUP BY team
ORDER BY passing_accuracy DESC;


-- Total goals scored each season
SELECT
    season,
    SUM(goals) AS total_goals
FROM nwsl_teams_cleaned
GROUP BY season
ORDER BY season;


-- Average goals per match for each season
WITH complete_games AS (
    SELECT
        game_id,
        season,
        SUM(goals) AS match_goals
    FROM nwsl_teams_cleaned
    GROUP BY game_id, season
    HAVING COUNT(*) = 2
       AND COUNT(goals) = 2
)
SELECT
    season,
    COUNT(*) AS total_matches,
    SUM(match_goals) AS total_goals,
    ROUND(AVG(match_goals), 2) AS avg_goals_per_match
FROM complete_games
GROUP BY season
ORDER BY season;


-- Compare player goals with team goals in each game
SELECT
    p.season,
    p.player_name,
    p.team_id,
    p.goals AS player_goals,
    t.goals AS team_goals
FROM nwsl_players_cleaned AS p
JOIN nwsl_teams_cleaned AS t
    ON p.game_id = t.game_id
    AND p.team_id = t.team
WHERE p.goals > 0
ORDER BY p.season, p.player_name
LIMIT 20;


-- Check how many player records match the team data
SELECT
    COUNT(*) AS joined_records,
    COUNT(DISTINCT p.game_id, p.player_id)
        AS unique_player_games
FROM nwsl_players_cleaned AS p
JOIN nwsl_teams_cleaned AS t
    ON p.game_id = t.game_id
    AND p.team_id = t.team;


-- Rank the top goal scorers for each season
WITH player_goals AS (
    SELECT
        season,
        player_id,
        player_name,
        SUM(goals) AS total_goals
    FROM nwsl_players_cleaned
    GROUP BY season, player_id, player_name
),
ranked_players AS (
    SELECT
        season,
        player_name,
        total_goals,
        ROW_NUMBER() OVER (
            PARTITION BY season
            ORDER BY total_goals DESC, player_name
        ) AS player_rank
    FROM player_goals
)
SELECT
    season,
    player_rank,
    player_name,
    total_goals
FROM ranked_players
WHERE player_rank <= 5
ORDER BY season, player_rank;

