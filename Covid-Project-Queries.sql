-- COVID DEATHS TABLE
-- Data preview
SELECT Location, date, total_Cases, new_cases, total_DEaths, population
FROM `covid-deaths`
ORDER BY 1,2;

-- Total Cases vs Total Deaths per country
-- Likelihood of dying if getting infected (percentage)
SELECT Location, date, total_cases, new_cases, total_deaths, (total_deaths/total_cases)*100 AS Death_Percentage
FROM `covid-deaths`
WHERE LOCATION = 'australia'
ORDER BY 1,2 ;


-- Total Cases vs Population per country (keep in mind a person can get infected again so it could count more than once)
SELECT Location, date, population, total_cases, new_cases, (total_cases/population)*100 AS Infected_Percentage
FROM `covid-deaths`
WHERE LOCATION = 'australia'
ORDER BY 1,2 ;

-- Top 10 Higuest death count vs population per country
SELECT Location, population, MAX(total_deaths) AS Higuest_deaths
FROM `covid-deaths`
WHERE continent != ""
GROUP BY Location, population
ORDER BY Higuest_deaths DESC 
LIMIT 10;

-- Top 10 Higuest Death rate percentage count vs population per country
SELECT Location, population, MAX(total_deaths) AS Higuest_deaths, ROUND(MAX((total_deaths/population)*100),4) AS Death_Percentage
FROM `covid-deaths`
WHERE continent != ""
GROUP BY Location, population
ORDER BY Death_Percentage DESC 
LIMIT 10;

-- NOW THE SAME FOR CONTINENTS
-- Top 10 Higuest death count per continent
SELECT location, MAX(total_deaths) AS Higuest_deaths
FROM `covid-deaths`
WHERE continent = "" 
	AND location in ('Europe', 'South America', 'North America', 'Oceania', 'Asia', 'Africa')
GROUP BY Location, population
ORDER BY Higuest_deaths DESC 
LIMIT 10;

-- Top 10 Higuest Death rate percentage count vs population per continent
SELECT Location, population, MAX(total_deaths) AS Higuest_deaths, ROUND(MAX((total_deaths/population)*100), 4) AS Death_Percentage
FROM `covid-deaths`
WHERE continent = ""
	AND location in ('Europe', 'South America', 'North America', 'Oceania', 'Asia', 'Africa')
GROUP BY Location, population
ORDER BY Death_Percentage DESC
LIMIT 10 ;

-- AROUND THE WORLD
-- PER DATE: Cases, new cases, deaths per day (keep in mind a person can get infected again so 'total cases' are counting people who got infected more than once)
SELECT date, SUM(total_cases), SUM(new_cases) AS Total_new_cases, SUM(new_deaths) AS total_Deaths, ROUND(SUM(new_Deaths)/SUM(total_CAses)*100, 4) as death_percentage
FROM `covid-deaths`
WHERE continent != "" 
GROUP BY date
ORDER BY date;

-- TOTALS: Total cases vs death percentage up until specified "date"
SELECT SUM(new_cases) AS Total_cases, SUM(new_deaths) AS total_Deaths, ROUND(SUM(new_Deaths)/SUM(new_CAses)*100, 4) as death_percentage
FROM `covid-deaths`
WHERE continent != "" AND date < "2024-01-01" -- choose reference date
-- GROUP BY date
-- ORDER BY date 
;


-- COMBINING DEATHS TABLE WITH VACCINATIONS TABLE
-- Adding a Rolling Total using 'New vaccines' to identify total of vaccines (this assume the 'total_vaccinations' column doesn't exist)
SELECT d.location, d.date, d.population, v.new_vaccinations,
	SUM(v.new_vaccinations) OVER (PARTITION BY d.location ORDER BY d.location, d.date) AS rol_tot_vac
FROM `covid-deaths` d
JOIN `covid-vaccinations` v
	ON d.location = v.location
    AND d.date = v.date
WHERE d.continent != "" AND d.date < '2024-01-01' AND d.location = "Australia"
order by 1,2;

/* I want to use the result of the rol_total_vaccin to calculate relation(percentage) with population.
However, rol_tot_vac is created in the SELECT and cannot be used again in the same select. There are 2 options to be able to use it.
IMPORTANT: Total vaccines includes the 2 doses per person and the boosters. It means in one point in history the total 
vaccinations could be more than double the population*/
-- FIRST: Using CTE

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


-- SECOND: Using TEMPORARY TABLES
DROP TABLE IF EXISTS TempTable;
CREATE TABLE TempTable
(
location varchar(255),
Date date,
population numeric, 
new_vaccinations numeric,
rol_total_vac numeric
);

INSERT INTO TempTable
SELECT d.location, d.date, d.population, v.new_vaccinations,
	SUM(v.new_vaccinations) OVER (PARTITION BY d.location ORDER BY d.location, d.date) AS rol_tot_vac
FROM `covid-deaths` d
JOIN `covid-vaccinations` v
	ON d.location = v.location
    AND d.date = v.date
WHERE d.continent != "" AND d.date < '2024-01-01' AND d.location = "Australia"
order by 1,2;

SELECT *, (rol_total_vac/population)*100 
FROM TempTable
;