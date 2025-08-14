-- 1. What range of years for baseball games played does the provided database cover?
SELECT MIN(year) AS smallest, MAX(year) AS latest
FROM homegames;


--2.Find the name and height of the shortest player in the database. 
-- How many games did he play in? What is the name of the team for which he played?

SELECT namefirst, namelast, MIN(height) AS shortest, g_all
FROM people
LEFT JOIN appearances USING(playerid)
GROUP BY namefirst, namelast, g_all
HAVING MIN(height) IS NOT NULL
ORDER BY shortest ASC;

-- forgot the team
SELECT CONCAT(namefirst, ' ', namelast) AS playername, MIN(height) AS shortest, g_all, teams.name
FROM people
INNER JOIN appearances USING(playerid)
INNER JOIN teams USING(teamid)
GROUP BY playername, g_all, teams.name
HAVING MIN(height) IS NOT NULL
ORDER BY shortest ASC;

-- 3. Find all players in the database who played at Vanderbilt University. 
-- a.Create a list showing each player’s first and last names as well as the total salary they earned in the major leagues. 
-- b. Sort this list in descending order by the total salary earned. Which Vanderbilt player earned the most money in the majors?

SELECT CONCAT(namefirst, ' ', namelast) AS people, SUM(salary)::NUMERIC::MONEY AS total_salary
FROM people
LEFT JOIN salaries USING(playerid)
WHERE playerid IN
  (SELECT playerid
    FROM collegeplaying
    INNER JOIN schools 
    USING (schoolid)
    WHERE schoolname ILIKE '%Vanderbilt%')
GROUP BY people, playerid
ORDER BY total_salary DESC NULLS LAST;



-- 4. Using the fielding table, 
-- a. group players into three groups based on their position: 
-- b.label players with position OF as "Outfield", those with position "SS", "1B", "2B", and "3B" as "Infield", and those with position "P" or "C" as "Battery". 
-- c.Determine the number of putouts made by each of these three groups in 2016.

SELECT 
  CASE 
    WHEN pos = 'OF' THEN 'Outfield'
    WHEN pos IN ('SS', '1B', '2B', '3B') THEN 'Infield'
    WHEN pos IN ('P', 'C') THEN 'Battery'
  END AS position_group,
  SUM(po) AS total_putouts
FROM fielding
WHERE yearid = 2016
GROUP BY position_group
ORDER BY total_putouts DESC;


-- 5. Find the average number of strikeouts per game by decade since 1920. Round the numbers you report to 2 decimal places. Do the same for home runs per game. Do you see any trends?

-- SELECT SUM(so) AS strikeout_batter, SUM(soa) AS strikeout_pitcher

WITH decades AS(
SELECT
(yearid / 10) * 10 AS decade,
SUM(hr) AS total_hr,
SUM(so) AS total_so,
SUM(g) AS total_games
FROM teams
WHERE yearid >= 1920
GROUP BY decade
)

SELECT decade, ROUND(total_so * 1.0 / total_games, 2) AS avg_strikeout,
ROUND(total_hr * 1.0 / total_games, 2) AS avg_hr
FROM decades
ORDER BY decades;


-- answer
-- SELECT so, hr
-- FROM teams
-- WHERE yearid >= 1920

WITH decades AS(
SELECT
(yearid / 10) * 10 AS decade, hr, so, g
FROM teams
WHERE yearid >= 1920
)
SELECT decade
, ROUND(SUM(hr) / SUM(g)::numeric,2) AS hr_per_game
, ROUND(SUM(so) / SUM(g)::numeric,2) AS so_per_game
FROM decades
GROUP BY decade
ORDER BY decade;

--6. Find the player who had the most success stealing bases in 2016, where success is measured as the percentage of stolen base attempts which are successful. (A stolen base attempt results either in a stolen base or being caught stealing.) Consider only players who attempted at least 20 stolen bases.

SELECT namefirst, namelast, sb AS stolen_bases, cs AS caught_stealing, ROUND(100.0 * sb /(sb + cs), 2) AS success_rate
FROM people
INNER JOIN batting b USING(playerid)
WHERE b.yearid = 2016 AND (sb + cs) >= 20
ORDER BY success_rate DESC;

-- answer
SELECT namefirst, namelast, sb AS stolen_bases, cs AS caught_stealing, ROUND(100.0 * sb /(sb + cs), 2) AS success_rate
FROM people
INNER JOIN batting b USING(playerid)
WHERE b.yearid = 2016
GROUP BY namefirst, namelast, sb, cs
HAVING SUM(sb) + SUM(cs) >= 20
ORDER BY success_rate DESC;

-- 7. 
-- a. From 1970 – 2016, what is the largest number of wins for a team that did not win the world series? 
-- b. What is the smallest number of wins for a team that did win the world series? Doing this will probably result in an unusually small number of wins for a world series champion – determine why this is the case. 
-- c.Then redo your query, excluding the problem year. How often from 1970 – 2016 was it the case that a team with the most wins also won the world series? What percentage of the time?

-- part a
SELECT yearid,teamid, w AS large_wins
FROM teams
WHERE wswin = 'N' AND yearid BETWEEN 1970 AND 2016
ORDER BY w DESC;
-- part b
SELECT yearid, teamid, w AS few_wins
FROM teams
WHERE wswin = 'Y' AND yearid BETWEEN 1970 AND 2016
ORDER BY w ASC;

-- part c
WITH max_wins AS(SELECT yearid, MAX(w) AS max_wins
FROM teams
WHERE yearid BETWEEN 1970 AND 2016
GROUP BY yearid
),
winners AS(SELECT t.yearid, t.teamid 
FROM teams t
INNER JOIN max_wins m ON t.yearid = m.yearid AND t.w = m.max_wins
WHERE t.wswin = 'Y'
)
SELECT
COUNT(*) AS times_best_team_won,
(2016-1970) AS total_years,
ROUND(COUNT(*) * 100.0 / (2016-1970), 2) AS percentage
FROM winners;


-- ANSWER part c

WITH max_per_year AS (
	SELECT
		yearid,
		MAX(w) max_wins
	FROM
		teams
	WHERE 
		yearid BETWEEN 1970 AND 2016
	GROUP BY
		yearid
	ORDER BY
		yearid
)
SELECT 
	ROUND(((COUNT(yearid) / (2016-1970)::numeric)*100), 2) AS max_winner_percentage
FROM
	teams AS t
INNER JOIN
	max_per_year AS m
	USING(yearid)
WHERE 
	yearid BETWEEN 1970 AND 2016
	AND t.w = m.max_wins
	AND wswin = 'Y';



-- 8. Using the attendance figures from the homegames table, find the teams and parks which had the top 5 average attendance per game in 2016 (where average attendance is defined as total attendance divided by number of games). Only consider parks where there were at least 10 games played. Report the park name, team name, and average attendance. Repeat for the lowest 5 average attendance.

SELECT park_name, team, ROUND(SUM(attendance) / SUM(games) ,2) AS avg_attendance
FROM homegames
INNER JOIN parks USING(park)
WHERE year = 2016
GROUP BY park_name, team, games
HAVING SUM(games) >= 10
ORDER BY avg_attendance DESC
LIMIT 5;


SELECT park_name, team, ROUND(SUM(attendance) / SUM(games) ,2) AS avg_attendance
FROM homegames
INNER JOIN parks USING(park)
WHERE year = 2016
GROUP BY park_name, team, games
HAVING SUM(games) >= 10
ORDER BY avg_attendance ASC
LIMIT 5;


-- 9. Which managers have won the TSN Manager of the Year award in both the National League (NL) and the American League (AL)? 
-- Give their full name and the teams that they were managing when they won the award.

WITH NL_winners AS (
    SELECT playerid
    FROM awardsmanagers
    WHERE awardid = 'TSN Manager of the Year' AND lgid = 'NL'
),
AL_winners AS (
    SELECT playerid
    FROM awardsmanagers  
    WHERE awardid = 'TSN Manager of the Year' AND lgid = 'AL'
),
both_leagues AS (
    SELECT playerid FROM NL_winners
    INTERSECT
    SELECT playerid FROM AL_winners
)
SELECT 
DISTINCT am.yearid,
    p.namefirst,
    p.namelast,
    am.lgid,
    m.teamid
FROM awardsmanagers am
INNER JOIN both_leagues bl ON am.playerid = bl.playerid
INNER JOIN managers m ON am.playerid = m.playerid 
INNER JOIN people p ON am.playerid = p.playerid
WHERE am.awardid = 'TSN Manager of the Year'
ORDER BY p.namelast, p.namefirst, am.yearid;


-- Answer
SELECT namefirst, 
namelast,
awardsmanagers.lgid,
teams.name,
awardid
FROM managers 
INNER JOIN teams
USING(teamid,yearid)
INNER JOIN people
USING(playerid)
INNER JOIN awardsmanagers
USING(playerid)
WHERE playerid IN(select playerid from awardsmanagers inner join managers using(playerid, yearid) where awardid LIKE '%TSN Manager of the Year%' AND awardsmanagers.lgid IN ('NL','AL'))
AND awardid LIKE '%TSN Manager of the Year%' AND awardsmanagers.lgid IN ('NL','AL')






-- 10. 
-- a. Find all players who hit their career highest number of home runs in 2016. 
-- b. Consider only players who have played in the league for at least 10 years, and who hit at least one home run in 2016. 
-- c. Report the players' first and last names and the number of home runs they hit in 2016.
WITH p_stats AS(
SELECT playerid, namefirst, namelast, yearid, SUM(hr) AS all_hr, LEFT(finalgame, 4)::NUMERIC - LEFT(debut, 4)::NUMERIC AS career_years
FROM people
LEFT JOIN batting USING(playerid)
WHERE hr IS NOT NULL 
GROUP BY playerid, namefirst, namelast, yearid, finalgame, debut
ORDER BY all_hr DESC
),

p_maxhr AS(
SELECT playerid, MAX(all_hr) AS career_high_hr
FROM p_stats
GROUP BY playerid
)

SELECT namefirst, namelast, all_hr AS hr_2016
FROM p_stats
LEFT JOIN p_maxhr USING(playerid)
WHERE yearid = 2016
	AND all_hr = career_high_hr
	AND career_years >= 10
	AND all_hr >= 1
ORDER BY all_hr DESC;

-- need to do debut year - finalgame year
-- SELECT namefirst, namelast, LEFT(finalgame, 4)::NUMERIC - LEFT(debut, 4)::NUMERIC AS career_years
-- FROM people



-- OPEN ENDED QUESTIONS

-- 11. Is there any correlation between number of wins and team salary? Use data from 2000 and later to answer this question. As you do this analysis, keep in mind that salaries across the whole league tend to increase together, so you may want to look on a year-by-year basis.

SELECT yearid, teamid, SUM(salary)::NUMERIC::MONEY AS team_salary, w AS wins
FROM salaries
INNER JOIN teams USING(yearid, teamid)
WHERE yearid >= 2000
GROUP BY yearid, teamid, w
ORDER BY yearid, w DESC;


SELECT yearid, CORR(salary, w) AS correlation
FROM salaries
INNER JOIN teams USING(yearid, teamid)
WHERE yearid >= 2000
GROUP BY yearid
ORDER BY yearid;


-- what I found in the graph visualiser in sql is that there is a correlation between team salary and wins 
-- from the years 2004-2006 were the years with the most correlation with wins and salary, this could mean during that period payrolls were linked to field success. Then it dips down a little from 2007 to 2015 meaning the spending an performance died down. But then increases again in 2016 showing the salary driven success.



-- 12. In this question, you will explore the connection between number of wins and attendance.
-- a. Does there appear to be any correlation between attendance at home games and number of wins?
-- b. Do teams that win the world series see a boost in attendance the following year? What about teams that made the playoffs? Making the playoffs means either being a division winner or a wild card winner.

SELECT t.teamid, t.yearid, t.w AS wins, SUM(h.attendance) AS home_attendance
FROM teams t
INNER JOIN homegames h ON t.teamid = h.team AND t.yearid = h.year
GROUP BY t.teamid, t.yearid, t.w
ORDER BY home_attendance DESC;

SELECT 
    t1.teamid,
    t1.yearid AS ws_year,
    SUM(h1.attendance) AS ws_year_attendance,
    SUM(h2.attendance) AS following_year_attendance,
    SUM(h2.attendance) - SUM(h1.attendance) AS attendance_change
FROM teams t1
INNER JOIN homegames h1 ON t1.teamid = h1.team AND t1.yearid = h1.year
INNER JOIN teams t2 ON t1.teamid = t2.teamid AND t2.yearid = t1.yearid + 1
INNER JOIN homegames h2 ON t2.teamid = h2.team AND t2.yearid = h2.year
WHERE t1.wswin = 'Y'
GROUP BY t1.teamid, t1.yearid
HAVING SUM(h1.attendance) > 0 AND SUM(h2.attendance) > 0
ORDER BY t1.yearid DESC;

-- a. Looking at the graph it looks like the higher the attendace the more likely the team might win there is alot of wins from attendance itself at home games

-- b. Looking at the data for teams with following year attendace after they won the world series looks like there are some slight jumps in several teams but it just depends on the team and the year, but it seems like the highest looks like NYA and the lowest is SL4

-- 13. It is thought that since left-handed pitchers are more rare, causing batters to face them less often, that they are more effective. Investigate this claim and present evidence to either support or dispute this claim. 

-- a. First, determine just how rare left-handed pitchers are compared with right-handed pitchers. 
-- b. Are left-handed pitchers more likely to win the Cy Young Award? 
-- c. Are they more likely to make it into the hall of fame?

SELECT 
  p.throws,
  COUNT(DISTINCT p.playerid) AS num_pitchers
FROM people p
INNER JOIN pitching pg USING(playerid)
WHERE p.throws IN ('R', 'L')
GROUP BY p.throws;

-- from the data there are a total of 9082 pitchers, and only 2477 are left handed which makes it 27% chance that players are left handed

SELECT 
  p.throws,
  COUNT(DISTINCT p.playerid) AS Cy_winners
FROM people p
INNER JOIN awardsplayers ap USING(playerid)
WHERE ap.awardid = 'Cy Young Award' 
AND p.throws IN ('R', 'L')
GROUP BY p.throws;

-- they are likely to win the award but the data shows there are more right handed pitchers 53 that received the award than left 24

SELECT 
  p.throws,
  COUNT(DISTINCT p.playerid) AS hof_pitchers
FROM people p
INNER JOIN halloffame h USING(playerid)
INNER JOIN pitching pg USING(playerid)
WHERE h.inducted = 'Y' 
AND p.throws IN ('R', 'L')
GROUP BY p.throws;

-- on the last one they are likely to make it in the hall of fame only one did not make it out of the 24 i saw



-- BONUS
-- 1. In this question, you'll get to practice correlated subqueries and learn about the LATERAL keyword. Note: This could be done using window functions, but we'll do it in a different way in order to revisit correlated subqueries and see another keyword - LATERAL.

SELECT *
FROM(SELECT DISTINCT lgid FROM teams WHERE yearid = 2016) AS leagues,
LATERAL(
SELECT teamid, w 
FROM teams 
WHERE yearid = 2016
ORDER BY w DESC) AS top_teams;


-- 3 Recursive CTEs 
-- a. Willie Mays holds the record of the most All Star Game starts with 18. How many players started in an All Star Game with Willie Mays? (A player started an All Star Game if they appear in the allstarfull table with a non-null startingpos value).

-- 1. find where all star game is located
2. COUNT how many players started in a all star game
-- 3. join on allstarfull to find the teamid
-- 4. look for the name Willy Mays
5. Figure out recursion

WITH willie_info AS(
SELECT namefirst,namelast
FROM people
INNER JOIN allstarfull USING(playerid)
WHERE namefirst LIKE '%Willie%'
AND namelast LIKE '%Mays%'
),

WITH wille_year AS(
SELECT DISTINCT asf.yearid
FROM allstarfull asf
INNER JOIN willie_info wmi USING(playerid)
WHERE asf.startingpos IS NOT NULL
)



WITH RECURSIVE allstar_willie AS(

SELECT asf.yearid, asf.playerid, 1 AS pdepth
FROM allstarfull asf
INNER JOIN people p USING(playerid)
WHERE p.namefirst = 'Willie'
AND p.namelast = 'Mays'
AND asf.startingpos IS NOT NULL

UNION ALL

-- recursion
SELECT a.yearid, asf.playerid, a.pdepth + 1 
FROM allstar_willie a
INNER JOIN allstarfull asf ON asf.yearid = a.yearid
WHERE asf.startingpos IS NOT NULL
AND a.pdepth < 2
)
SELECT COUNT(DISTINCT playerid) AS players_with_willie
FROM allstar_willie


--b. How many players didn't start in an All Star Game with Willie Mays but started an All Star Game with another player who started an All Star Game with Willie Mays? For example, Graig Nettles never started an All Star Game with Willie Mayes, but he did star the 1975 All Star Game with Blue Vida who started the 1971 All Star Game with Willie Mays.





