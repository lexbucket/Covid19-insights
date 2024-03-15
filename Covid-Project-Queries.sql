/* Dataset source: https://ourworldindata.org/covid-deaths
The imported file was split in 2 files (covid-deaths and covid-vaccionations) for this project so JOIN statements can be used later on. 
The objective of this file is showing the use of different statements such as CTEs, temporary tables, Windows funtions, 
Aggregate functions, Joins, etc.
Inspired by 'Alex The Analyst' */

-- COVID DEATHS TABLE
-- 1. Data preview of the columns we are more interested in
SELECT Location, date, total_Cases, new_cases, total_DEaths, population
FROM `covid-deaths`
ORDER BY 1,2;

-- 2. Total Cases vs Total Deaths in Australia (modify location for other countries)
-- Percentage OF likelihood of dying if getting infected. 
-- (When analysing using 'total_Cases', note that as time passes by there are more chances of people getting infected MORE THAN ONCE so total_cases != total people infected)
SELECT continent, Location, date, total_cases, new_cases, total_deaths, (total_deaths/total_cases)*100 AS Death_Percentage
FROM `covid-deaths`
-- WHERE Continent != ""
WHERE location = 'Australia'
ORDER BY 1,2 ;


-- 3. Total Cases vs Population per country
-- (When analysing using 'total_Cases', note that as time passes by there are more chances of people getting infected MORE THAN ONCE so total_cases != total people infected)
SELECT Location, date, 
	population, total_cases, 
	new_cases, (total_cases/population)*100 AS Infected_Percentage
FROM `covid-deaths`
WHERE LOCATION = 'australia'
ORDER BY 1,2 ;

-- 4. Top 10 Higuest death count vs population per country (not a percentage, just quantity)
SELECT Location, population, MAX(total_deaths) AS Higuest_deaths
FROM `covid-deaths`
WHERE continent != ""
GROUP BY Location, population
ORDER BY Higuest_deaths DESC 
LIMIT 10;

-- 5. Top 10 Higuest Death rate PERCENTAGE count vs population per country
SELECT Location, population, 
	MAX(total_deaths) AS Higuest_deaths, 
    ROUND(MAX((total_deaths/population)*100),4) AS Death_Percentage
FROM `covid-deaths`
WHERE continent != ""
GROUP BY Location, population
ORDER BY Death_Percentage DESC 
LIMIT 10;

-- NOW THE SAME FOR CONTINENTS
-- 6. Top 10 Higuest death COUNT per continent (not a percentage, just quantity)
SELECT location, MAX(total_deaths) AS Higuest_deaths
FROM `covid-deaths`
WHERE continent = "" 
	AND location in ('Europe', 'South America', 'North America', 'Oceania', 'Asia', 'Africa')
GROUP BY Location, population
ORDER BY Higuest_deaths DESC 
LIMIT 10;

-- 7. Top 10 Higuest Death rate PERCENTAGE count vs population per continent
SELECT Location, population, 
	MAX(total_deaths) AS Higuest_deaths, 
    ROUND(MAX((total_deaths/population)*100), 4) AS Death_Percentage
FROM `covid-deaths`
WHERE continent = ""
	AND location in ('Europe', 'South America', 'North America', 'Oceania', 'Asia', 'Africa')
GROUP BY Location, population
ORDER BY Death_Percentage DESC
LIMIT 10 ;

-- AROUND THE WORLD
-- 8. PER DAY: Cases, new cases, deaths per day (keep in mind a person can get infected again so 'total cases' are counting people who got infected more than once)
-- (this assumes the 'total_cases' column doesn't exist in the original dataset)
SELECT date, SUM(new_cases) AS Total_new_cases, 
    SUM(new_deaths) AS total_Deaths,
    ROUND(SUM(new_Deaths)/SUM(total_CAses)*100, 4) as death_percentage
FROM `covid-deaths`
WHERE continent != "" 
GROUP BY date
ORDER BY date;

-- 9. TOTALS: Total cases vs death percentage up until specified "date"
SELECT SUM(new_cases) AS Total_cases, 
	SUM(new_deaths) AS total_Deaths, 
    ROUND(SUM(new_Deaths)/SUM(new_CAses)*100, 4) as death_percentage
FROM `covid-deaths`
WHERE continent != "" AND date < "2024-01-01" -- choose reference date
-- GROUP BY date
-- ORDER BY date 
;


-- COMBINING COVID-DEATHS TABLE WITH COVID-VACCINATIONS TABLE (using Joins)
-- 10. Adding a Rolling Total using 'New vaccines' to identify total of vaccines (this assumes the 'total_vaccinations' column doesn't exist)
SELECT d.location, d.date, d.population, v.new_vaccinations,
	SUM(v.new_vaccinations) OVER (PARTITION BY d.location ORDER BY d.location, d.date) AS rol_tot_vac
FROM `covid-deaths` d
JOIN `covid-vaccinations` v
	ON d.location = v.location
    AND d.date = v.date
WHERE d.continent != "" AND d.date < '2024-01-01' AND d.location = "Australia"
order by 1,2;


/* 11. Now I want to use the result of the rol_total_vaccin to calculate relation(percentage) with population.
However, rol_tot_vac is created in the SELECT and cannot be used again in the same select. There are 2 options to be able to use it.
IMPORTANT: Total vaccines includes the 2 doses per person and the boosters. It means in one point in history the total 
vaccinations quantity could be more than double the population*/

-- A) Using CTE

With CTE (location, date, population, new_vaccinations, rol_tot_vac)
	AS
	(SELECT d.location, d.date, d.population, v.new_vaccinations,
		SUM(v.new_vaccinations) OVER (PARTITION BY d.location ORDER BY d.location, d.date) AS rol_tot_vac
	FROM `covid-deaths` d
	JOIN `covid-vaccinations` v
		ON d.location = v.location
		AND d.date = v.date
	WHERE d.continent != "" AND d.date < '2024-01-01' AND d.location = "Australia"
	ORDER BY 1,2)
SELECT *, (rol_tot_vac/population)*100 AS VacPopPercentage
FROM CTE
;


-- B) Using TEMPORARY TABLES
DROP TABLE IF EXISTS TempTable; -- Useful when practicing with the temporary table multiple times
CREATE TABLE TempTable
(
location varchar(255),
Date date,
population numeric, 
new_vaccinations numeric,
rol_total_vac numeric
);

INSERT INTO TempTable -- Add the results of this query to the previously created table
SELECT d.location, d.date, d.population, v.new_vaccinations,
	SUM(v.new_vaccinations) OVER (PARTITION BY d.location ORDER BY d.location, d.date) AS rol_tot_vac
FROM `covid-deaths` d
JOIN `covid-vaccinations` v
	ON d.location = v.location
    AND d.date = v.date
WHERE d.continent != "" AND d.date < '2024-01-01' AND d.location = "Australia"
order by 1,2;

SELECT *, (rol_total_vac/population)*100 -- Using the aggregate value 'rol_tot_vac' to calculate a new value in this query
FROM TempTable
;


-- 12. Create a VIEW that can be used later on as a virtual table
CREATE VIEW PercentagePopVaccin AS
SELECT d.location, d.date, d.population, v.new_vaccinations,
	SUM(v.new_vaccinations) OVER (PARTITION BY d.location ORDER BY d.location, d.date) AS rol_tot_vac
FROM `covid-deaths` d
JOIN `covid-vaccinations` v
	ON d.location = v.location
    AND d.date = v.date
WHERE d.continent != "" AND d.date < '2024-01-01'
order by 1,2;

-- 13. Test View
SELECT *
FROM percentagepopvaccin