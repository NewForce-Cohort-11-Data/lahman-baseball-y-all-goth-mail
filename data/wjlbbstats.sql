-- What range of years for baseball games played does the provided database cover?
SELECT MIN (year) AS smallest, MAX (year) AS latest
FROM homegames;

-- Find the name and height of the shortest player in the database. How many games did he play in? What is the name of the team for which he played?
SELECT namefirst, namelast, MIN (height) AS shortest, g_all
FROM people 
LEFT JOIN appearances  USING (playerid)
GROUP BY namefirst, namelast, g_all
ORDER BY shortest ASC;

-- Find all players in the database who played at Vanderbilt University. Create a list showing each player’s first and last names as well as the total salary they earned in the major leagues. Sort this list in descending order by the total salary earned. Which Vanderbilt player earned the most money in the majors?
SELECT 
    p.nameFirst,
    p.nameLast,
    SUM(s.salary) AS total_salary
FROM people p
JOIN collegeplaying cp
    ON p.playerID = cp.playerID
JOIN salaries s
    ON p.playerID = s.playerID
WHERE cp.schoolID = 'vandy'
GROUP BY p.nameFirst, p.nameLast
ORDER BY total_salary DESC;

-- Using the fielding table, group players into three groups based on their position: label players with position OF as "Outfield", those with position "SS", "1B", "2B", and "3B" as "Infield", and those with position "P" or "C" as "Battery". Determine the number of putouts made by each of these three groups in 2016.
SELECT 
    CASE 
        WHEN pos = 'OF' THEN 'Outfield'
        WHEN pos IN ('SS', '1B', '2B', '3B') THEN 'Infield'
        WHEN pos IN ('P', 'C') THEN 'Battery'
    END AS position_group,
    SUM(po) AS total_putouts
FROM fielding
WHERE yearID = 2016
GROUP BY position_group
ORDER BY total_putouts DESC;

-- Find the average number of strikeouts per game by decade since 1920. Round the numbers you report to 2 decimal places. Do the same for home runs per game. Do you see any trends?
SELECT 
    (yearID / 10) * 10 AS decade,
    ROUND(SUM(SO) * 1.0 / SUM(G), 2) AS avg_strikeouts_per_game,
    ROUND(SUM(HR) * 1.0 / SUM(G), 2) AS avg_home_runs_per_game
FROM teams
WHERE yearID >= 1920
GROUP BY decade
ORDER BY decade;

-- Find the player who had the most success stealing bases in 2016, where success is measured as the percentage of stolen base attempts which are successful. (A stolen base attempt results either in a stolen base or being caught stealing.) Consider only players who attempted at least 20 stolen bases.
SELECT 
    p.nameFirst,
    p.nameLast,
    b.SB,
    b.CS,
    ROUND(b.SB * 1.0 / (b.SB + b.CS), 3) AS success_rate
FROM batting b
JOIN people p ON b.playerID = p.playerID
WHERE b.yearID = 2016
  AND (b.SB + b.CS) >= 20
ORDER BY success_rate DESC
LIMIT 1;

-- From 1970 – 2016, what is the largest number of wins for a team that did not win the world series? What is the smallest number of wins for a team that did win the world series? Doing this will probably result in an unusually small number of wins for a world series champion – determine why this is the case. Then redo your query, excluding the problem year. How often from 1970 – 2016 was it the case that a team with the most wins also won the world series? What percentage of the time?
-- ================================================
-- PART 1: Max wins by a team that did NOT win the World Series
-- ================================================
SELECT 
    MAX(t.W) AS max_wins_no_world_series_title
FROM teams t
WHERE t.yearID BETWEEN 1970 AND 2016
  AND NOT EXISTS (
    SELECT 1
    FROM seriespost s
    WHERE s.yearID = t.yearID
      AND s.round = 'WS'
      AND s.teamIDwinner = t.teamID
  );

-- ================================================
-- PART 2: Min wins by a team that DID win the World Series
-- ================================================
SELECT 
    MIN(t.W) AS min_wins_by_world_series_winner
FROM teams t
JOIN seriespost s 
  ON t.yearID = s.yearID AND t.teamID = s.teamIDwinner
WHERE s.round = 'WS'
  AND t.yearID BETWEEN 1970 AND 2016;

-- ================================================
-- PART 3: Min wins by a WS winner (excluding 1981)
-- ================================================
SELECT 
    MIN(t.W) AS min_wins_by_world_series_winner_excl_1981
FROM teams t
JOIN seriespost s 
  ON t.yearID = s.yearID AND t.teamID = s.teamIDwinner
WHERE s.round = 'WS'
  AND t.yearID BETWEEN 1970 AND 2016
  AND t.yearID != 1981;

-- ================================================
-- PART 4: Count how many times best team won World Series
-- ================================================
WITH max_wins_per_year AS (
  SELECT yearID, MAX(W) AS max_wins
  FROM teams
  WHERE yearID BETWEEN 1970 AND 2016
  GROUP BY yearID
),
top_teams AS (
  SELECT t.yearID, t.teamID, t.W
  FROM teams t
  JOIN max_wins_per_year mw 
    ON t.yearID = mw.yearID AND t.W = mw.max_wins
),
ws_winners AS (
  SELECT yearID, teamIDwinner AS teamID
  FROM seriespost
  WHERE round = 'WS'
    AND yearID BETWEEN 1970 AND 2016
)
SELECT 
    COUNT(*) AS years_top_team_won_world_series
FROM top_teams tt
JOIN ws_winners ws
  ON tt.yearID = ws.yearID AND tt.teamID = ws.teamID;

-- ================================================
-- PART 5: Percentage of time best team won World Series
-- ================================================
WITH max_wins_per_year AS (
  SELECT yearID, MAX(W) AS max_wins
  FROM teams
  WHERE yearID BETWEEN 1970 AND 2016
  GROUP BY yearID
),
top_teams AS (
  SELECT t.yearID, t.teamID, t.W
  FROM teams t
  JOIN max_wins_per_year mw 
    ON t.yearID = mw.yearID AND t.W = mw.max_wins
),
ws_winners AS (
  SELECT yearID, teamIDwinner AS teamID
  FROM seriespost
  WHERE round = 'WS'
    AND yearID BETWEEN 1970 AND 2016
),
matchups AS (
  SELECT tt.yearID
  FROM top_teams tt
  JOIN ws_winners ws
    ON tt.yearID = ws.yearID AND tt.teamID = ws.teamID
)
SELECT 
    COUNT(*) AS matching_years,
    47 AS total_years,
    ROUND(COUNT(*) * 100.0 / 47, 2) AS percentage_top_team_won_ws;


-- Using the attendance figures from the homegames table, find the teams and parks which had the top 5 average attendance per game in 2016 (where average attendance is defined as total attendance divided by number of games). Only consider parks where there were at least 10 games played. Report the park name, team name, and average attendance. Repeat for the lowest 5 average attendance.
WITH avg_attendance AS 
		(SELECT DISTINCT team, 
			(SUM(attendance) / SUM(games)) AS avg_attendance_per_game 
		FROM homegames 
		WHERE games >= 10
			AND year = 2016
		GROUP BY team)

SELECT DISTINCT T1.team,
		T1.park,
		T2.avg_attendance_per_game
FROM homegames AS T1
CROSS JOIN avg_attendance AS T2
WHERE games >= 10
	AND year = 2016
ORDER BY avg_attendance_per_game DESC
LIMIT 5;

-- Get Top 5 and Bottom 5 using UNION ALL
SELECT * FROM attendance_data
ORDER BY avg_attendance DESC
LIMIT 5

UNION ALL

SELECT * FROM attendance_data
ORDER BY avg_attendance ASC
LIMIT 5;

-- Which managers have won the TSN Manager of the Year award in both the National League (NL) and the American League (AL)? Give their full name and the teams that they were managing when they won the award.
WITH manager_awards AS (
    SELECT 
        am.playerID,
        t.teamID,
        t.name AS team_name,
        t.lgID,
        am.yearID
    FROM awardsmanagers am
    JOIN managers m ON am.playerID = m.playerID AND am.yearID = m.yearID
    JOIN teams t ON m.teamID = t.teamID AND m.yearID = t.yearID
    WHERE am.awardID = 'TSN Manager of the Year'
),
al_winners AS (
    SELECT playerID FROM manager_awards WHERE lgID = 'AL'
),
nl_winners AS (
    SELECT playerID FROM manager_awards WHERE lgID = 'NL'
),
both_leagues AS (
    SELECT DISTINCT al.playerID
    FROM al_winners al
    INNER JOIN nl_winners nl ON al.playerID = nl.playerID
)
SELECT 
    p.nameFirst || ' ' || p.nameLast AS full_name,
    ma.team_name,
    ma.lgID,
    ma.yearID
FROM both_leagues bl
JOIN manager_awards ma ON bl.playerID = ma.playerID
JOIN people p ON bl.playerID = p.playerID
ORDER BY full_name, ma.yearID;

-- Find all players who hit their career highest number of home runs in 2016. Consider only players who have played in the league for at least 10 years, and who hit at least one home run in 2016. Report the players' first and last names and the number of home runs they hit in 2016.
WITH player_season_counts AS (
    SELECT playerID, COUNT(DISTINCT yearID) AS seasons
    FROM batting
    GROUP BY playerID
),

career_hr_highs AS (
    SELECT playerID, MAX(HR) AS max_hr
    FROM batting
    GROUP BY playerID
),

hr_2016 AS (
    SELECT b.playerID, p.nameFirst, p.nameLast, b.HR
    FROM batting b
    JOIN people p ON b.playerID = p.playerID
    WHERE b.yearID = 2016 AND b.HR > 0
)

SELECT 
    h.nameFirst,
    h.nameLast,
    h.HR AS hr_2016
FROM hr_2016 h
JOIN player_season_counts s ON h.playerID = s.playerID
JOIN career_hr_highs c ON h.playerID = c.playerID
WHERE 
    s.seasons >= 10
    AND h.HR = c.max_hr
ORDER BY hr_2016 DESC;

-- Is there any correlation between number of wins and team salary? Use data from 2000 and later to answer this question. As you do this analysis, keep in mind that salaries across the whole league tend to increase together, so you may want to look on a year-by-year basis.
WITH team_salaries AS (
    SELECT
        teamID,
        yearID,
        SUM(salary) AS total_salary
    FROM salaries
    WHERE yearID >= 2000
    GROUP BY teamID, yearID
),

team_performance AS (
    SELECT
        teamID,
        yearID,
        W AS wins
    FROM teams
    WHERE yearID >= 2000
)

SELECT 
    s.yearID,
    s.teamID,
    s.total_salary,
    t.wins
FROM team_salaries s
JOIN team_performance t 
  ON s.teamID = t.teamID AND s.yearID = t.yearID
ORDER BY s.yearID, s.total_salary DESC;

-- In this question, you will explore the connection between number of wins and attendance.
-- Does there appear to be any correlation between attendance at home games and number of wins?
SELECT
    t.yearID,
    t.name AS team_name,
    h.attendance,
    t.W AS wins
FROM teams t
JOIN homegames h ON t.teamID = h.team AND t.yearID = h.year
WHERE t.yearID >= 2000
  AND h.attendance IS NOT NULL
  AND t.W IS NOT NULL
ORDER BY t.yearID, t.name;

-- Do teams that win the world series see a boost in attendance the following year? What about teams that made the playoffs? Making the playoffs means either being a division winner or a wild card winner.
WITH playoff_teams AS (
    SELECT DISTINCT
        t.yearID,
        t.teamID
    FROM teams t
    JOIN seriespost sp 
        ON t.yearID = sp.yearID 
       AND t.teamID = sp.teamIDwinner
    WHERE sp.round IN ('WS', 'ALCS', 'NLCS', 'ALDS', 'NLDS', 'WC')
),
world_series_winners AS (
    SELECT DISTINCT
        t.yearID,
        t.teamID
    FROM teams t
    JOIN seriespost sp 
        ON t.yearID = sp.yearID 
       AND t.teamID = sp.teamIDwinner
    WHERE sp.round = 'WS'
),
attendance_by_year AS (
    SELECT
        t.yearID,
        t.teamID,
        SUM(h.attendance) AS total_attendance,
        SUM(h.games) AS total_games,
        SUM(h.attendance) / NULLIF(SUM(h.games), 0) AS avg_attendance
    FROM teams t
    JOIN homegames h
        ON t.teamID = h.team
       AND t.yearID = h.year
    GROUP BY t.yearID, t.teamID
)
SELECT
    a1.teamID,
    a1.yearID,
    CASE WHEN ws.teamID IS NOT NULL THEN 'WS Winner'
         WHEN pt.teamID IS NOT NULL THEN 'Playoff Team'
         ELSE 'Other'
    END AS category,
    a1.avg_attendance AS attendance_year,
    a2.avg_attendance AS attendance_next_year,
    ROUND(
        ((a2.avg_attendance - a1.avg_attendance) / NULLIF(a1.avg_attendance, 0)) * 100, 
        2
    ) AS pct_change
FROM attendance_by_year a1
LEFT JOIN attendance_by_year a2
    ON a1.teamID = a2.teamID
   AND a1.yearID + 1 = a2.yearID
LEFT JOIN playoff_teams pt
    ON a1.teamID = pt.teamID
   AND a1.yearID = pt.yearID
LEFT JOIN world_series_winners ws
    ON a1.teamID = ws.teamID
   AND a1.yearID = ws.yearID
WHERE ws.teamID IS NOT NULL OR pt.teamID IS NOT NULL
ORDER BY category, pct_change DESC;

-- It is thought that since left-handed pitchers are more rare, causing batters to face them less often, that they are more effective. Investigate this claim and present evidence to either support or dispute this claim. First, determine just how rare left-handed pitchers are compared with right-handed pitchers. Are left-handed pitchers more likely to win the Cy Young Award? Are they more likely to make it into the hall of fame?
SELECT 
    p.throws,
    COUNT(DISTINCT h.playerID) AS hof_pitchers
FROM halloffame h
JOIN people p ON h.playerID = p.playerID
JOIN pitching pi ON p.playerID = pi.playerID
WHERE h.inducted = 'Y'
  AND p.throws IN ('L', 'R')
GROUP BY p.throws;