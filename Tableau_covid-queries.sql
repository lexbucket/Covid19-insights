-- TABLEAU QUERIES

-- 1. This assumes the 'total_cases' column doesn't exist in the original dataset, therefore the sum of new_Cases should provide the value
-- Total cases + total deaths + death percentage
SELECT SUM(new_cases) AS Total_Cases, 
    SUM(new_deaths) AS Total_Deaths,
    ROUND(SUM(new_Deaths)/SUM(total_Cases)*100, 4) AS Death_Percentage,
    population,
    SUM(new_deaths_per_million) AS Deaths_Per_Million
FROM `covid-deaths`
WHERE continent != "" AND date < '2024-01-01'
-- GROUP BY date
ORDER BY date;

-- Validation of previous results considering the dataset includes data for the world => Similar numbers.
/* SELECT SUM(new_cases) AS Total_Cases, 
    SUM(new_deaths) AS Total_Deaths,
    ROUND(SUM(new_Deaths)/SUM(total_CAses)*100, 4) as Death_Percentage
FROM `covid-deaths`
WHERE location = 'World' AND date < '2024-01-01'
ORDER BY date;
*/ 


-- 2. Countries with a higher percentage of cases compared to the population per day
SELECT Location, Population, date, 
	MAX(total_deaths) as HighestDeathCount,
	MAX(total_cases) as HighestInfectionCount
FROM `covid-deaths`
WHERE location = "World" -- Only select countries and not continents as well
	AND date < '2024-01-01'
GROUP BY Location, Population, date
ORDER BY date;


-- 3. Total death count grouped by location (continent) 
-- We want to know the information per continent based on the 'location' column. Therefore don't need to include some values (restriction in WHERE)
SELECT location, SUM(new_deaths) as Total_Death_Count
FROM `covid-deaths`
WHERE continent = ""
	AND location NOT IN ('World', 'High income', 'Upper middle income', 'Lower middle income', 'European Union', 'Low income')
    AND date < '2024-01-01'
GROUP BY location
ORDER BY Total_Death_Count DESC;

-- 4. Countries with a higher percentage of cases compared to population (Important to remember the total cases may count the same person more than once if they have been reinfected
SELECT Location, Population, MAX(total_cases) as HighestInfectionCount,  ROUND(Max((total_cases/population)) *100, 5) as PercentPopulationInfected
FROM `covid-deaths`
WHERE continent != "" -- Only select countries and not continents as well
	AND date < '2024-01-01'
GROUP BY Location, Population
ORDER BY PercentPopulationInfected DESC;

-- 5. Countries with a higher percentage of death compared to the population
SELECT Location, Population, MAX(total_deaths) as HighestDeathCount,  ROUND(Max((total_deaths/population)) *100, 5) as PercentPopulationDeath
FROM `covid-deaths`
WHERE continent != "" -- Only select countries and not continents as well
	AND date < '2024-01-01'
GROUP BY Location, Population
ORDER BY PercentPopulationDeath DESC;

-- 6. Countries with a higher percentage of cases compared to the population per day
SELECT Location, Population, date, MAX(total_cases) as HighestInfectionCount,  ROUND(MAX((total_cases/population))*100, 5) as PercentPopulationInfected
FROM `covid-deaths`
WHERE continent != "" -- Only select countries and not continents as well
	AND date < '2024-01-01'
GROUP BY Location, Population, date;
-- ORDER BY PercentPopulationInfected DESC;

-- 7. Countries with a higher percentage of deaths compared to the population per day
SELECT Location, Population, date, MAX(total_deaths) as HighestDeathsCount,  ROUND(MAX((total_deaths/population))*100, 5) as PercentPopulationDeaths
FROM `covid-deaths`
WHERE continent != "" -- Only select countries and not continents as well
	AND date < '2024-01-01'
GROUP BY Location, Population, date
ORDER BY PercentPopulationDeaths DESC;
