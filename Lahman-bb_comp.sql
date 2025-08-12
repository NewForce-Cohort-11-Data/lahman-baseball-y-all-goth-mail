-- Question 1: What range of years for baseball games played does the provided database cover?

-- This query should find the earliest and latest years in the database
-- Consider checking multiple tables like teams, batting, pitching to ensure comprehensive coverage

-- Example approach:
-- SELECT MIN(yearid) as earliest_year, MAX(yearid) as latest_year
-- FROM teams;

-- Write your SQL query below:

SELECT 
    MIN(yearid) as earliest_year, 
    MAX(yearid) as latest_year
FROM teams;




-- Question 2: Find the name and height of the shortest player in the database. 
-- How many games did he play in? What is the name of the team for which he played?

-- This query needs to:
-- 1. Find the shortest player by height from the people/master table
-- 2. Get their name information
-- 3. Find how many games they played (from appearances/batting tables)
-- 4. Determine which team(s) they played for

-- Consider joining: people, batting, teams tables
-- Handle potential ties for shortest height

-- Write your SQL query below:

WITH shortest_players AS (
    SELECT 
        playerid,
        namefirst,
        namelast,
        height
    FROM people 
    WHERE height = (SELECT MIN(height) FROM people WHERE height IS NOT NULL)
)
SELECT 
    sp.namefirst || ' ' || sp.namelast as player_name,
    sp.height,
    SUM(b.g) as total_games,
    STRING_AGG(DISTINCT t.name, ', ') as teams_played_for
FROM shortest_players sp
LEFT JOIN batting b ON sp.playerid = b.playerid
LEFT JOIN teams t ON b.yearid = t.yearid AND b.teamid = t.teamid
GROUP BY sp.playerid, sp.namefirst, sp.namelast, sp.height;






-- Question 3: Find all players in the database who played at Vanderbilt University. 
-- Create a list showing each player's first and last names as well as the total salary they earned in the major leagues. 
-- Sort this list in descending order by the total salary earned. 
-- Which Vanderbilt player earned the most money in the majors?

-- This query needs to:
-- 1. Find players who attended Vanderbilt University (collegeplaying table)
-- 2. Get their names from people table
-- 3. Sum their total salaries from salaries table
-- 4. Sort by total salary descending

-- Consider joining: collegeplaying, people, salaries tables
-- Handle players who may not have salary data

-- Write your SQL query below:

-- Find Vanderbilt players and their total MLB salaries
SELECT 
    p.namefirst,
    p.namelast,
    COALESCE(SUM(s.salary), 0) as total_salary_earned
FROM people p
INNER JOIN collegeplaying c ON p.playerid = c.playerid
LEFT JOIN salaries s ON p.playerid = s.playerid
WHERE c.schoolid = 'vandy'
GROUP BY p.playerid, p.namefirst, p.namelast
ORDER BY total_salary_earned DESC; 



-- Question 4: Using the fielding table, group players into three groups based on their position: 
-- label players with position OF as "Outfield", 
-- those with position "SS", "1B", "2B", and "3B" as "Infield", 
-- and those with position "P" or "C" as "Battery". 
-- Determine the number of putouts made by each of these three groups in 2016.

-- This query needs to:
-- 1. Use CASE statement to categorize positions into the three groups
-- 2. Filter for 2016 data
-- 3. Sum putouts (PO column) by group
-- 4. Use fielding table

-- Write your SQL query below:

SELECT 
    CASE 
        WHEN pos = 'OF' THEN 'Outfield'
        WHEN pos IN ('SS', '1B', '2B', '3B') THEN 'Infield' 
        WHEN pos IN ('P', 'C') THEN 'Battery'
    END as position_group,
    SUM(po) as total_putouts
FROM fielding 
WHERE yearid = 2016
  AND pos IN ('OF', 'SS', '1B', '2B', '3B', 'P', 'C')
GROUP BY 
    CASE 
        WHEN pos = 'OF' THEN 'Outfield'
        WHEN pos IN ('SS', '1B', '2B', '3B') THEN 'Infield'
        WHEN pos IN ('P', 'C') THEN 'Battery'
    END;


-- Question 5: Find the average number of strikeouts per game by decade since 1920. 
-- Round the numbers you report to 2 decimal places. 
-- Do the same for home runs per game. Do you see any trends?

-- This query needs to:
-- 1. Group data by decade (1920s, 1930s, etc.)
-- 2. Calculate total strikeouts and total games by decade
-- 3. Calculate average strikeouts per game
-- 4. Do the same for home runs
-- 5. Round to 2 decimal places

-- Consider using: teams table for games and team stats, or batting/pitching tables
-- Use CASE or mathematical operations to group years into decades

-- Write your SQL query below:

SELECT 
    CONCAT(FLOOR(yearid/10)*10, 's') as decade,
    ROUND(SUM(so)::numeric / SUM(g), 2) as avg_strikeouts_per_game,
    ROUND(SUM(hr)::numeric / SUM(g), 2) as avg_homeruns_per_game
FROM teams 
WHERE yearid >= 1920
GROUP BY FLOOR(yearid/10)*10
ORDER BY FLOOR(yearid/10)*10;




-- Question 6: Find the player who had the most success stealing bases in 2016, 
-- where success is measured as the percentage of stolen base attempts which are successful. 
-- (A stolen base attempt results either in a stolen base or being caught stealing.) 
-- Consider only players who attempted at least 20 stolen bases.

-- This query needs to:
-- 1. Filter for 2016 data
-- 2. Calculate stolen base attempts (SB + CS)
-- 3. Calculate success percentage (SB / (SB + CS))
-- 4. Filter for players with at least 20 attempts
-- 5. Find the player with highest success percentage

-- Use batting table - columns: SB (stolen bases), CS (caught stealing)
-- Join with people table to get player names

-- Write your SQL query below:

SELECT 
    p.namefirst || ' ' || p.namelast AS player_name,
    SUM(b.sb) as stolen_bases,
    SUM(b.cs) as caught_stealing,
    SUM(b.sb + b.cs) as total_attempts,
    ROUND((SUM(b.sb)::numeric / SUM(b.sb + b.cs)) * 100, 2) AS success_percentage
FROM batting b
JOIN people p ON b.playerid = p.playerid
WHERE b.yearid = 2016
  AND (b.sb > 0 OR b.cs > 0)  -- Ensure player had steal attempts
GROUP BY p.playerid, p.namefirst, p.namelast
HAVING SUM(b.sb + b.cs) >= 20
ORDER BY success_percentage DESC
LIMIT 1;




-- Question 7: From 1970 – 2016, what is the largest number of wins for a team that did not win the world series? 
-- What is the smallest number of wins for a team that did win the world series? 
-- Doing this will probably result in an unusually small number of wins for a world series champion – determine why this is the case. 
-- Then redo your query, excluding the problem year. 
-- How often from 1970 – 2016 was it the case that a team with the most wins also won the world series? What percentage of the time?

-- This is a multi-part question that needs several queries:
-- 1. Max wins for non-World Series winner
-- 2. Min wins for World Series winner
-- 3. Investigation of the unusual year
-- 4. Analysis of most wins vs World Series winner correlation

-- Use teams table - columns: W (wins), WSWin (World Series winner - Y/N)

-- Write your SQL queries below:

-- Part 1: Max wins for a team that did NOT win the World Series (1970-2016)
SELECT MAX(w) as max_wins_no_ws
FROM teams 
WHERE yearid BETWEEN 1970 AND 2016
  AND (wswin = 'N' OR wswin IS NULL);

-- Part 2: Min wins for a team that DID win the World Series (1970-2016)
SELECT MIN(w) as min_wins_with_ws
FROM teams 
WHERE yearid BETWEEN 1970 AND 2016
  AND wswin = 'Y';

-- Part 3: Investigation - what happened in the unusual year?
SELECT yearid
FROM teams 
WHERE yearid BETWEEN 1970 AND 2016
  AND wswin = 'Y'
  AND w = (SELECT MIN(w) FROM teams WHERE yearid BETWEEN 1970 AND 2016 AND wswin = 'Y');

-- Part 4: Excluding 1981, redo the min wins for WS winner
SELECT MIN(w) as min_wins_with_ws_excluding_1981
FROM teams 
WHERE yearid BETWEEN 1970 AND 2016
  AND yearid != 1981
  AND wswin = 'Y';

-- Part 5: How often did the team with most wins also win World Series?
WITH yearly_max_wins AS (
    SELECT 
        yearid,
        MAX(w) as max_wins_in_year
    FROM teams 
    WHERE yearid BETWEEN 1970 AND 2016
    GROUP BY yearid),
max_win_teams AS (
    SELECT 
        t.yearid,
        CASE WHEN t.wswin = 'Y' THEN 1 ELSE 0 END as won_ws
    FROM teams t
    JOIN yearly_max_wins y ON t.yearid = y.yearid AND t.w = y.max_wins_in_year
    WHERE t.yearid BETWEEN 1970 AND 2016)
SELECT 
    ROUND((SUM(won_ws)::numeric / COUNT(*)) * 100, 2) as percentage_won_ws
FROM max_win_teams;



-- Question 8: Using the attendance figures from the homegames table, 
-- find the teams and parks which had the top 5 average attendance per game in 2016 
-- (where average attendance is defined as total attendance divided by number of games). 
-- Only consider parks where there were at least 10 games played. 
-- Report the park name, team name, and average attendance. 
-- Repeat for the lowest 5 average attendance.

-- This query needs to:
-- 1. Use homegames table for attendance data
-- 2. Filter for 2016 and games >= 10
-- 3. Calculate average attendance per game
-- 4. Join with parks and teams for names
-- 5. Get top 5 and bottom 5

-- Consider: homegames, parks, teams tables

-- Write your SQL query below:

-- TOP 5 and BOTTOM 5 attendance in 2016
WITH attendance_data AS (
    SELECT 
        h.park as park_name,
        t.name as team_name,
        ROUND(SUM(h.attendance) * 1.0 / SUM(h.games), 0) as avg_attendance_per_game
    FROM homegames h
    JOIN teams t ON h.year = t.yearid AND h.team = t.teamid
    WHERE h.year = 2016
    GROUP BY h.park, h.team, t.name
    HAVING SUM(h.games) >= 10
),
ranked_attendance AS (
    SELECT *,
           ROW_NUMBER() OVER (ORDER BY avg_attendance_per_game DESC) as rank_high,
           ROW_NUMBER() OVER (ORDER BY avg_attendance_per_game ASC) as rank_low
    FROM attendance_data
)
SELECT park_name, team_name, avg_attendance_per_game, 'Top 5' as category
FROM ranked_attendance 
WHERE rank_high <= 5
UNION ALL
SELECT park_name, team_name, avg_attendance_per_game, 'Bottom 5' as category
FROM ranked_attendance 
WHERE rank_low <= 5
ORDER BY 
    CASE WHEN category = 'Top 5' THEN 1 ELSE 2 END,
    avg_attendance_per_game DESC;




-- Question 9: Which managers have won the TSN Manager of the Year award in both the National League (NL) and the American League (AL)? 
-- Give their full name and the teams that they were managing when they won the award.

-- This query needs to:
-- 1. Find managers who won TSN Manager of Year award
-- 2. Filter for those who won in both NL and AL
-- 3. Get their full names from people table
-- 4. Include team information for each award

-- Use: awardsmanagers, people, managers tables
-- Award ID should be 'TSN Manager of the Year' or similar

-- Write your SQL query below:

-- First, let's check what manager awards exist
-- SELECT DISTINCT awardid FROM awardsmanagers WHERE awardid LIKE '%Manager%' OR awardid LIKE '%TSN%';

-- Find managers who won TSN Manager of the Year in both leagues
WITH tsn_winners AS (
    SELECT DISTINCT
        am.playerid,
        am.yearid,
        am.lgid,
        am.awardid
    FROM awardsmanagers am
    WHERE am.awardid = 'TSN Manager of the Year'
),
dual_league_managers AS (
    SELECT 
        playerid
    FROM tsn_winners
    WHERE lgid IN ('NL', 'AL')
    GROUP BY playerid
    HAVING COUNT(DISTINCT lgid) = 2  -- Won in both leagues
)
SELECT 
    p.namefirst || ' ' || p.namelast as manager_name,
    tw.yearid,
    tw.lgid as league,
    tw.awardid,
    m.teamid,
    t.name as team_name
FROM dual_league_managers dlm
JOIN people p ON dlm.playerid = p.playerid
JOIN tsn_winners tw ON dlm.playerid = tw.playerid
JOIN managers m ON tw.playerid = m.playerid AND tw.yearid = m.yearid
JOIN teams t ON m.yearid = t.yearid AND m.teamid = t.teamid
WHERE tw.lgid IN ('NL', 'AL')
ORDER BY p.namelast, p.namefirst, tw.yearid;

-- Question 10: Find all players who hit their career highest number of home runs in 2016. 
-- Consider only players who have played in the league for at least 10 years, 
-- and who hit at least one home run in 2016. 
-- Report the players' first and last names and the number of home runs they hit in 2016.

-- This query needs to:
-- 1. Find each player's career-high home run total by year
-- 2. Identify players whose career high was in 2016
-- 3. Filter for players with at least 10 years of play
-- 4. Filter for players with at least 1 HR in 2016
-- 5. Get player names from people table

-- Use batting table - HR column for home runs
-- Consider using window functions or subqueries

-- Write your SQL query below:

WITH player_yearly_hrs AS (
    SELECT 
        playerid,
        yearid,
        SUM(hr) as hr_total
    FROM batting
    WHERE hr IS NOT NULL
    GROUP BY playerid, yearid
),
player_careers AS (
    SELECT 
        playerid,
        yearid,
        hr_total,
        MAX(hr_total) OVER (PARTITION BY playerid) as career_high_hrs,
        COUNT(*) OVER (PARTITION BY playerid) as years_played
    FROM player_yearly_hrs
),
career_high_2016 AS (
    SELECT DISTINCT
        playerid,
        hr_total as hr_2016
    FROM player_careers
    WHERE yearid = 2016
      AND hr_total = career_high_hrs
      AND years_played >= 10
      AND hr_total >= 1
)
SELECT 
    p.namefirst,
    p.namelast,
    ch.hr_2016
FROM career_high_2016 ch
JOIN people p ON ch.playerid = p.playerid
ORDER BY ch.hr_2016 DESC;










-- Open-Ended Question 11: Is there any correlation between number of wins and team salary? 
-- Use data from 2000 and later to answer this question. 
-- As you do this analysis, keep in mind that salaries across the whole league tend to increase together, 
-- so you may want to look on a year-by-year basis.

-- This analysis should:
-- 1. Calculate total team payroll by year (sum of salaries by team/year)
-- 2. Get wins data from teams table
-- 3. Analyze correlation year by year or overall
-- 4. Consider relative salary rankings within each year
-- 5. Use statistical measures or visualizations to show correlation

-- Consider: salaries, teams tables
-- May want to calculate salary rankings or percentiles within each year

-- Write your SQL query/analysis below:

WITH team_data AS (
    SELECT 
        t.yearid,
        t.teamid,
        t.w as wins,
        SUM(s.salary) as total_payroll
    FROM teams t
    JOIN salaries s ON t.yearid = s.yearid AND t.teamid = s.teamid
    WHERE t.yearid >= 2000
    GROUP BY t.yearid, t.teamid, t.w
),
correlations AS (
    SELECT 
        'Overall (2000-2016)' as period,
        0 as sort_order,
        ROUND(CORR(total_payroll, wins)::numeric, 3) as correlation
    FROM team_data

    UNION ALL

    SELECT 
        CAST(yearid AS TEXT) as period,
        1 as sort_order,
        ROUND(CORR(total_payroll, wins)::numeric, 3) as correlation
    FROM team_data
    GROUP BY yearid
)
SELECT 
    period,
    correlation
FROM correlations
ORDER BY sort_order, period;



-- Open-Ended Question 12: In this question, you will explore the connection between number of wins and attendance.
-- a) Does there appear to be any correlation between attendance at home games and number of wins?
-- b) Do teams that win the world series see a boost in attendance the following year? 
--    What about teams that made the playoffs? Making the playoffs means either being a division winner or a wild card winner.

-- This analysis should include:
-- Part A: Correlation between home attendance and wins
-- Part B: World Series winner attendance boost analysis
-- Part B: Playoff team attendance boost analysis

-- Consider: teams, homegames tables
-- Need to handle year-over-year comparisons for part B

-- Write your SQL queries/analysis below:

-- Part A: Attendance vs Wins Correlation
WITH team_data AS (
    SELECT 
        t.yearid,
        t.teamid,
        t.w as wins,
        h.attendance
    FROM teams t
    JOIN homegames h ON t.yearid = h.year AND t.teamid = h.team
)
SELECT 
    ROUND(CORR(attendance, wins)::numeric, 3) as attendance_wins_correlation
FROM team_data;

-- Part B: World Series Winner Attendance Boost (following year)
WITH ws_teams AS (
    SELECT 
        t.yearid,
        t.teamid,
        h.attendance as ws_year_attendance,
        LEAD(h.attendance) OVER (PARTITION BY t.teamid ORDER BY t.yearid) as next_year_attendance
    FROM teams t
    JOIN homegames h ON t.yearid = h.year AND t.teamid = h.team
    WHERE t.wswin = 'Y'
)
SELECT 
    ROUND(AVG((next_year_attendance - ws_year_attendance) * 100.0 / ws_year_attendance), 2) as avg_attendance_boost_pct
FROM ws_teams
WHERE next_year_attendance IS NOT NULL AND ws_year_attendance > 0;

-- Part C: Playoff Team Attendance Boost (following year)
WITH playoff_teams AS (
    SELECT 
        t.yearid,
        t.teamid,
        h.attendance as playoff_year_attendance,
        LEAD(h.attendance) OVER (PARTITION BY t.teamid ORDER BY t.yearid) as next_year_attendance
    FROM teams t
    JOIN homegames h ON t.yearid = h.year AND t.teamid = h.team
    WHERE (t.divwin = 'Y' OR t.wcwin = 'Y')
)
SELECT 
    ROUND(AVG((next_year_attendance - playoff_year_attendance) * 100.0 / playoff_year_attendance), 2) as avg_attendance_boost_pct
FROM playoff_teams
WHERE next_year_attendance IS NOT NULL AND playoff_year_attendance > 0;






-- Open-Ended Question 13: It is thought that since left-handed pitchers are more rare, 
-- causing batters to face them less often, that they are more effective. 
-- Investigate this claim and present evidence to either support or dispute this claim. 
-- First, determine just how rare left-handed pitchers are compared with right-handed pitchers. 
-- Are left-handed pitchers more likely to win the Cy Young Award? 
-- Are they more likely to make it into the hall of fame?

-- This analysis should include:
-- 1. Proportion of left-handed vs right-handed pitchers overall
-- 2. Effectiveness metrics comparison (ERA, WHIP, wins, etc.)
-- 3. Cy Young Award analysis by handedness
-- 4. Hall of Fame analysis by handedness

-- Consider: people (throws column), pitching, awardsplayers, halloffame tables

-- Write your SQL queries/analysis below:

-- Part 1: Rarity of left-handed pitchers
SELECT 
    throws,
    COUNT(*) as pitcher_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) as percentage
FROM people p
WHERE EXISTS (SELECT 1 FROM pitching pt WHERE pt.playerid = p.playerid)
  AND throws IN ('L', 'R')
GROUP BY throws;

-- Part 2: Effectiveness comparison (career averages for pitchers with significant innings)
WITH pitcher_careers AS (
    SELECT 
        p.playerid,
        p.throws,
        SUM(pt.ipouts) as total_ipouts,
        SUM(pt.er) as total_er,
        SUM(pt.h + pt.bb) as total_walks_hits,
        SUM(pt.w) as total_wins,
        SUM(pt.l) as total_losses,
        SUM(pt.so) as total_strikeouts
    FROM pitching pt
    JOIN people p ON pt.playerid = p.playerid
    WHERE p.throws IN ('L', 'R')
      AND pt.ipouts IS NOT NULL
    GROUP BY p.playerid, p.throws
    HAVING SUM(pt.ipouts) >= 1620  -- At least 540 innings pitched (equivalent to ~3+ seasons)
)
SELECT 
    throws,
    COUNT(*) as pitcher_count,
    ROUND(AVG(total_er * 27.0 / total_ipouts), 3) as avg_era,
    ROUND(AVG(CASE 
        WHEN (total_wins + total_losses) > 0 
        THEN total_wins * 1.0 / (total_wins + total_losses) 
        ELSE NULL 
    END), 3) as avg_win_pct,
    ROUND(AVG(total_walks_hits * 27.0 / total_ipouts), 3) as avg_whip,
    ROUND(AVG(total_strikeouts * 27.0 / total_ipouts), 2) as avg_k_per_game
FROM pitcher_careers
GROUP BY throws;

-- Part 3: Cy Young Award analysis
SELECT 
    p.throws,
    COUNT(*) as cy_young_winners
FROM awardsplayers ap
JOIN people p ON ap.playerid = p.playerid
WHERE ap.awardid = 'Cy Young Award'
  AND p.throws IN ('L', 'R')
GROUP BY p.throws;

-- Part 4: Hall of Fame analysis (pitchers only)
SELECT 
    p.throws,
    COUNT(*) as hof_inductees,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) as hof_percentage
FROM halloffame hof
JOIN people p ON hof.playerid = p.playerid
WHERE hof.inducted = 'Y'
  AND p.throws IN ('L', 'R')
  AND EXISTS (SELECT 1 FROM pitching pt WHERE pt.playerid = p.playerid)
GROUP BY p.throws;





