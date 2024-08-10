-- Before running drop any existing views
DROP VIEW IF EXISTS q0;
DROP VIEW IF EXISTS q1i;
DROP VIEW IF EXISTS q1ii;
DROP VIEW IF EXISTS q1iii;
DROP VIEW IF EXISTS q1iv;
DROP VIEW IF EXISTS q2i;
DROP VIEW IF EXISTS q2ii;
DROP VIEW IF EXISTS q2iii;
DROP VIEW IF EXISTS q3i;
DROP VIEW IF EXISTS q3ii;
DROP VIEW IF EXISTS q3iii;
DROP VIEW IF EXISTS q4i;
DROP VIEW IF EXISTS q4ii;
DROP VIEW IF EXISTS q4iii;
DROP VIEW IF EXISTS q4iv;
DROP VIEW IF EXISTS q4v;
DROP VIEW IF EXISTS batstat;
DROP VIEW IF EXISTS playerlslg;
DROP VIEW IF EXISTS bins;
DROP VIEW IF EXISTS salary_stat;
DROP VIEW IF EXISTS yearly_diff;
DROP VIEW IF EXISTS maxid;

-- Question 0: Highest era (earned run average)
CREATE VIEW q0(era)
AS
    SELECT max(era)
    FROM pitching
;

-- Question 1i
CREATE VIEW q1i(namefirst, namelast, birthyear)
AS
    SELECT nameFirst, nameLast, birthYear
    FROM people
    WHERE weight > 300
;

-- Question 1ii
CREATE VIEW q1ii(namefirst, namelast, birthyear)
AS
    SELECT nameFirst, nameLast, birthYear
    FROM people
    WHERE nameFirst LIKE '% %'
    ORDER BY nameFirst, nameLast
;

-- Question 1iii
CREATE VIEW q1iii(birthyear, avgheight, count)
AS
    SELECT birthYear, avg(height), count(*)
    FROM people
    GROUP BY birthYear
    ORDER BY birthYear
;

-- Question 1iv
CREATE VIEW q1iv(birthyear, avgheight, count)
AS
    SELECT *
    FROM q1iii
    WHERE avgheight > 70
;

-- Question 2i
CREATE VIEW q2i(namefirst, namelast, playerid, yearid)
AS
    SELECT people.nameFirst, people.nameLast, people.playerID, halloffame.yearid
    FROM people NATURAL JOIN halloffame
    WHERE halloffame.inducted = 'Y'
    ORDER BY yearid DESC, people.playerID ASC
;

-- Question 2ii
CREATE VIEW q2ii(namefirst, namelast, playerid, schoolid, yearid)
AS
    SELECT p.nameFirst, p.nameLast, p.playerID, s.schoolID, f.yearid
    FROM people AS p NATURAL JOIN halloffame AS f,
         collegeplaying as c NATURAL JOIN schools AS s
    WHERE p.playerID = c.playerid AND f.inducted = 'Y' AND s.schoolState = 'CA'
    ORDER BY yearid DESC, s.schoolID, p.playerID
;

-- Question 2iii
CREATE VIEW q2iii(playerid, namefirst, namelast, schoolid)
AS
    SELECT p.playerid, p.nameFirst, p.nameLast, c.schoolID
    FROM q2i AS p LEFT OUTER JOIN collegeplaying AS c
    ON p.playerid = c.playerid
    ORDER BY p.playerID DESC, c.schoolID
;

-- Question 3i
CREATE VIEW q3i(playerid, namefirst, namelast, yearid, slg)
AS
    SELECT p.playerID, p.nameFirst, p.nameLast, b.yearID,
           (b.H + b.H2B + 2 * b.H3B + 3 * b.HR) / CAST(b.AB AS FLOAT) AS slg
    FROM people AS p JOIN batting AS b
    WHERE p.playerID = b.playerID AND b.AB > 50
    ORDER BY slg DESC, b.yearID, p.playerID
    LIMIT 10
;

-- Question 3ii
CREATE VIEW q3ii(playerid, namefirst, namelast, lslg)
AS
    SELECT * FROM playerlslg
    LIMIT 10
;

-- 3ii helpers
CREATE VIEW batstat(playerid, sumH, sumH2B, sumH3B, sumHR, sumAB)
AS
    SELECT playerID,
           SUM(H) AS sumH,
           SUM(H2B) AS sumH2B,
           SUM(H3B) AS sumH3B,
           SUM(HR) AS sumHR,
           SUM(AB) AS sumAB
    FROM batting
    GROUP BY playerID
    HAVING sumAB > 50
;

CREATE VIEW playerlslg(playerid, namefirst, namelast, lslg)
AS
    SELECT p.playerID, p.nameFirst, p.nameLast,
           (b.sumH + b.sumH2B + 2 * b.sumH3B + 3 * b.sumHR) / CAST(b.sumAB as FLOAT) AS lslg
    FROM people AS p JOIN batstat AS b
    WHERE p.playerID = b.playerid
    ORDER BY lslg DESC, p.playerID
;

-- Question 3iii
CREATE VIEW q3iii(namefirst, namelast, lslg)
AS
    SELECT namefirst, namelast, lslg
    FROM playerlslg
    WHERE lslg > (SELECT lslg
                  FROM playerlslg
                  WHERE playerid = 'mayswi01')
;

-- Question 4i
CREATE VIEW q4i(yearid, min, max, avg)
AS
    SELECT s.yearID, min(salary), max(salary), avg(salary)
    FROM people AS p INNER JOIN salaries AS s
    ON p.playerID = s.playerID
    GROUP BY s.yearID
    ORDER BY s.yearID
;

-- Question 4ii
CREATE VIEW q4ii(binid, low, high, count)
AS
    SELECT binid, low, high, count(salary)
    FROM bins LEFT OUTER JOIN salaries
    ON salary >= low
    AND ((binid < 9 AND salary < high) OR (binid = 9 AND salary <= high))
    AND yearID = 2016
    GROUP BY binid, low, high
    ORDER BY binid
;

CREATE VIEW salary_stat(min_salary, max_salary, range)
AS
    SELECT min(salary), max(salary), max(salary) - min(salary)
    FROM salaries
    WHERE yearID = 2016
;

DROP TABLE IF EXISTS binids;
CREATE TABLE binids(id);
INSERT INTO binids VALUES (0), (1), (2), (3), (4), (5), (6), (7), (8), (9);

CREATE VIEW bins(binid, low, high)
AS
    SELECT
        id AS binid,
        min_salary + (id * (range / 10)) AS low,
        CASE
            WHEN id < 9 THEN (min_salary + (id + 1) * (range / 10))
            ELSE max_salary
        END AS high
    FROM binids JOIN salary_stat
;

-- Question 4iii
CREATE VIEW q4iii(yearid, mindiff, maxdiff, avgdiff)
AS
    SELECT curr.yearid,
           curr.min_salary - prev.min_salary AS mindiff,
           curr.max_salary - prev.max_salary AS maxdiff,
           curr.avg_salary - prev.avg_salary AS avgdiff
    FROM yearly_diff AS curr
    JOIN yearly_diff AS prev
    ON curr.yearid = prev.yearid + 1
    ORDER BY curr.yearid
;

CREATE VIEW yearly_diff(yearid, min_salary, max_salary, avg_salary)
AS
    SELECT yearID, min(salary), max(salary), avg(salary)
    FROM salaries
    GROUP BY yearID
    ORDER BY yearID
;

-- Question 4iv
CREATE VIEW q4iv(playerid, namefirst, namelast, salary, yearid)
AS
    SELECT p.playerID, p.nameFirst, p.nameLast, m.salary, m.yearid
    FROM people AS p INNER JOIN maxid AS m
    ON p.playerID = m.playerid
;

CREATE VIEW maxid(playerid, salary, yearid)
AS
    SELECT playerID, max(salary), yearID
    FROM salaries
    WHERE yearID = 2000 OR yearID = 2001
    GROUP BY yearID
;

-- Question 4v
CREATE VIEW q4v(team, diffAvg) AS
    SELECT a.teamID, max(s.salary) - min(s.salary)
    FROM allstarfull AS a INNER JOIN salaries AS s
    ON a.playerID = s.playerID
    AND a.yearID = s.yearID
    AND a.yearID = 2016
    GROUP BY a.teamID
;
