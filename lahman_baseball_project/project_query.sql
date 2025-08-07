-- 1. What range of years for baseball games played does the provided database cover?
SELECT MIN(yearid) AS earliest_year,
		MAX(yearid) AS lastest_year
FROM people
INNER JOIN appearances
USING (playerid);

-- 2. Find the name and height of the shortest player in the database. 
SELECT CONCAT(namelast, ', ', namefirst) AS player_name, 
		height
FROM people
ORDER BY height
LIMIT 1;

-- How many games did he play in? What is the name of the team for which he played?
WITH shortest_player AS 
	(SELECT CONCAT(namelast, ', ', namefirst) AS player_name, 
		height
	FROM people
	ORDER BY height
	LIMIT 1)

SELECT DISTINCT player_name,
		(g_all) AS total_games_played, teams.name
FROM shortest_player
CROSS JOIN appearances
LEFT JOIN teams
USING (teamid)
WHERE playerid = 'gaedeed01';

-- 3. Find all players in the database who played at Vanderbilt University. 
SELECT DISTINCT T3.playerid, 
		schoolname
FROM collegeplaying AS T1
LEFT JOIN schools AS T2
USING (schoolid)
INNER JOIN people AS T3
USING (playerid)
WHERE schoolid ILIKE 'vandy';

-- Create a list showing each player’s first and last names as well as the total salary they earned in the major leagues. 
SELECT DISTINCT CONCAT(T3.namelast, ', ', T3.namefirst) AS player_name, 
		T4.salary::INTEGER::MONEY, 
		schoolname
FROM collegeplaying AS T1
LEFT JOIN schools AS T2
USING (schoolid)
INNER JOIN people AS T3
USING (playerid)
INNER JOIN salaries AS T4
USING (playerid)
WHERE schoolid ILIKE 'vandy';

-- Sort this list in descending order by the total salary earned. Which Vanderbilt player earned the most money in the majors?
SELECT DISTINCT CONCAT(T3.namelast, ', ', T3.namefirst) AS player_name, 
		SUM(T4.salary::INTEGER::MONEY) AS salary, 
		schoolname
FROM collegeplaying AS T1
LEFT JOIN schools AS T2
USING (schoolid)
INNER JOIN people AS T3
USING (playerid)
INNER JOIN salaries AS T4
USING (playerid)
WHERE schoolid ILIKE 'vandy'
GROUP BY player_name, schoolname
ORDER BY salary DESC
LIMIT 1;

-- 4. Using the fielding table, group players into three groups based on their position: 
-- label players with position OF as "Outfield", those with position "SS", "1B", "2B", and "3B" as "Infield", 
-- and those with position "P" or "C" as "Battery". 
SELECT 
	CASE 
		WHEN pos = 'OF' THEN 'Outfield'
		WHEN pos = 'SS' OR pos = '1B' OR pos = '2B' OR pos = '3B' THEN 'Infield'
		WHEN pos = 'P' OR pos = 'C' THEN 'Battery'
	END AS positions,
	COUNT(DISTINCT playerid)
FROM fielding
GROUP BY positions;

-- Determine the number of putouts made by each of these three groups in 2016.
SELECT 
	CASE 
		WHEN pos = 'OF' THEN 'Outfield'
		WHEN pos = 'SS' OR pos = '1B' OR pos = '2B' OR pos = '3B' THEN 'Infield'
		WHEN pos = 'P' OR pos = 'C' THEN 'Battery'
	END AS positions, 
	SUM(PO) AS putout_count
FROM fielding
WHERE yearid = 2016
GROUP BY positions;

-- 5. Find the average number of strikeouts per game by decade since 1920. 
-- Round the numbers you report to 2 decimal places. 
SELECT (FLOOR(yearid / 10) * 10) AS decades, 
		SUM(so) AS strikeout_count,
		SUM(so) / COUNT(DISTINCT so) AS avg_strikeouts
FROM teams
WHERE yearid >= 1920
GROUP BY decades
ORDER BY decades;

-- Do the same for home runs per game. Do you see any trends?
SELECT (FLOOR(yearid / 10) * 10) AS decades, 
		SUM(hr) AS homerun_count,
		SUM(hr) / COUNT(DISTINCT hr) AS avg_homeruns
FROM teams
WHERE yearid >= 1920
GROUP BY decades
ORDER BY decades;

-- 6. Find the player who had the most success stealing bases in 2016, where success is measured as the percentage of stolen base attempts which are successful. 
-- (A stolen base attempt results either in a stolen base or being caught stealing.) Consider only players who attempted at least 20 stolen bases.
SELECT DISTINCT CONCAT(T2.namelast, ', ', T2.namefirst) AS player_name, 
		SUM(sb+cs) AS total_stolen,
		SUM(sb+cs) / COUNT(sb+cs) AS avg_stolen
FROM batting AS T1
CROSS JOIN people AS T2
WHERE sb > 20 OR cs > 20
GROUP BY player_name
ORDER BY avg_stolen DESC NULLS LAST
LIMIT 1;

-- 7. From 1970 – 2016, what is the largest number of wins for a team that did not win the world series? 
SELECT  DISTINCT name AS team_name,
		SUM(w) AS total_wins
FROM teams
WHERE yearid BETWEEN 1970 AND 2016
	AND wswin = 'N'
GROUP BY name
ORDER BY total_wins DESC
LIMIT 1;

-- What is the smallest number of wins for a team that did win the world series? 
-- Doing this will probably result in an unusually small number of wins for a world series champion – determine why this is the case. 
-- Then redo your query, excluding the problem year. 
SELECT  DISTINCT name AS team_name,
		SUM(w) AS total_wins
FROM teams
WHERE yearid BETWEEN 1970 AND 2016
	AND yearid <> 1995
	AND wswin = 'Y'
GROUP BY name
ORDER BY total_wins ASC;


-- How often from 1970 – 2016 was it the case that a team with the most wins also won the world series? 
-- What percentage of the time?
WITH max_wins_by_year AS 
		(SELECT yearid AS year,
				MAX(w) AS max_wins
		FROM teams
		WHERE yearid BETWEEN 1970 AND 2016
		GROUP BY yearid)

SELECT 	COUNT(T2.*) AS total_years,
		SUM(CASE WHEN T1.wswin = 'Y' THEN 1 ELSE 0 END) AS best_year_won,
		ROUND((SUM(CASE WHEN T1.wswin = 'Y' THEN 1 ELSE 0 END::NUMERIC) / COUNT(*) * 100),2) AS percentage_of_wins
FROM teams AS T1
LEFT JOIN max_wins_by_year AS T2
ON T1.yearid = T2.year
WHERE T1.yearid BETWEEN 1970 AND 2016;

-- 8. Using the attendance figures from the homegames table, find the teams and parks which had the top 5 average attendance per game in 2016 
-- (where average attendance is defined as total attendance divided by number of games). 
-- Only consider parks where there were at least 10 games played. 
-- Report the park name, team name, and average attendance. Repeat for the lowest 5 average attendance.
SELECT *
FROM homegames;

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
-- ***************************************************
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
ORDER BY avg_attendance_per_game ASC
LIMIT 5;

-- 9. Which managers have won the TSN Manager of the Year award in both the National League (NL) and the American League (AL)? 
-- Give their full name and the teams that they were managing when they won the award.
WITH natl_league AS 
		(SELECT NL1.playerid,
				NL1.awardid,
				NL1.yearid,
				NL1.lgid,
				NL2.name
		FROM awardsmanagers AS NL1
		CROSS JOIN teams AS NL2
		WHERE NL1.lgid = 'NL'
		AND NL1.awardid ILIKE '%TSN Manager%'),
ameri_league AS 
		(SELECT AL1.playerid,
				AL1.awardid,
				AL1.yearid,
				AL1.lgid,
				AL2.name
		FROM awardsmanagers AS AL1
		CROSS JOIN teams AS AL2
		WHERE AL1.lgid = 'AL'
		AND AL1.awardid ILIKE '%TSN Manager%')

SELECT CONCAT(T3.namelast, ', ', T3.namefirst) AS nl_award_winner, 
		T1.yearid AS NL_award_year, 
		T1.name,
		CONCAT(T3.namelast, ', ', T3.namefirst) AS al_award_winner, 
		T2.yearid AS AL_award_year,
		T2.name
FROM natl_league AS T1
INNER JOIN ameri_league AS T2
ON T1.playerid = T2.playerid
INNER JOIN people AS T3
ON T1.playerid = T3.playerid;

-- 10. Find all players who hit their career highest number of home runs in 2016. 
-- Consider only players who have played in the league for at least 10 years, and who hit at least one home run in 2016. 
-- Report the players' first and last names and the number of home runs they hit in 2016.

SELECT DISTINCT CONCAT(T2.namelast, ', ', T2.namefirst) AS player_name,
		MAX(T1.hr) OVER(PARTITION BY namelast) AS max_homeruns_2016
		FROM batting AS T1
		INNER JOIN people AS T2
		USING (playerid)
		WHERE yearid = 2016
			AND hr >= 1
			AND debut LIKE '2006%'
ORDER BY max_homeruns_2016 DESC;

-- *************************************************************Open-ended questions*************************************************************

-- 11. Is there any correlation between number of wins and team salary? Use data from 2000 and later to answer this question. 
-- As you do this analysis, keep in mind that salaries across the whole league tend to increase together, so you may want to look on a year-by-year basis.
SELECT *
FROM salaries;



-- 12. In this question, you will explore the connection between number of wins and attendance.

-- 13. Does there appear to be any correlation between attendance at home games and number of wins?
-- Do teams that win the world series see a boost in attendance the following year? What about teams that made the playoffs? 
-- Making the playoffs means either being a division winner or a wild card winner.
-- It is thought that since left-handed pitchers are more rare, causing batters to face them less often, that they are more effective. 
-- Investigate this claim and present evidence to either support or dispute this claim. 
-- First, determine just how rare left-handed pitchers are compared with right-handed pitchers. 
-- Are left-handed pitchers more likely to win the Cy Young Award? Are they more likely to make it into the hall of fame?


SELECT *
FROM appearances;

SELECT *
FROM awardsmanagers;

SELECT *
FROM awardsplayers;

SELECT *
FROM awardssharemanagers;

SELECT *
FROM awardsshareplayers;

SELECT *
FROM batting;

SELECT *
FROM battingpost;

SELECT *
FROM collegeplaying;

SELECT *
FROM fielding;

SELECT *
FROM fieldingof;

SELECT *
FROM fieldingofsplit;

SELECT *
FROM fieldingpost;

SELECT *
FROM halloffame;

SELECT *
FROM homegames;

SELECT *
FROM managers;

SELECT *
FROM managershalf;

SELECT *
FROM parks;

SELECT *
FROM people;

SELECT *
FROM pitching;

SELECT *
FROM pitchingpost;

SELECT *
FROM salaries;

SELECT *
FROM schools
ORDER BY schoolname DESC;

SELECT *
FROM seriespost;

SELECT *
FROM teams;

SELECT *
FROM teamsfranchises;

SELECT *
FROM teamshalf;