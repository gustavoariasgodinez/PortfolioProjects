/*
COVID-19 EXPLORATORY DATA ANALYSIS
Description: Performance of querying tasks to get general insights about COVID-19 at a global and local scales.
Data source: retrieved from https://ourworldindata.org/covid-vaccinations (December, 2021)
Programming language: SQL
Relational Database Management System: Microsoft SQL Server Management Studio 18
Created by: Gustavo Arias-Godínez (M.Sc. Biologist; Data Analyst Specialist)
Contact: gustavoarg7@gmail.com
*/

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- FIRST LOOK AT THE 'CovidDeaths' DATA TABLE
SELECT
   TOP 50* 
FROM
   PortfolioProject..CovidDeaths 
ORDER BY
   total_cases DESC;
-- You can immediately notice that we have NULL values


-- Percentage of null values (for 'most relevant' columns, only)
SELECT 100.0 * SUM(CASE WHEN continent IS NULL THEN 1 ELSE 0 END) / COUNT(*) AS continent_null_percent
      ,100.0 * SUM(CASE WHEN location IS NULL THEN 1 ELSE 0 END) / COUNT(*) AS location_null_percent
      ,100.0 * SUM(CASE WHEN date IS NULL THEN 1 ELSE 0 END) / COUNT(*) AS date_null_percent
	  ,100.0 * SUM(CASE WHEN population IS NULL THEN 1 ELSE 0 END) / COUNT(*) AS population_null_percent
	  ,100.0 * SUM(CASE WHEN total_cases IS NULL THEN 1 ELSE 0 END) / COUNT(*) AS total_cases_null_percent
	  ,100.0 * SUM(CASE WHEN total_deaths IS NULL THEN 1 ELSE 0 END) / COUNT(*) AS total_deaths_null_percent
	  ,100.0 * SUM(CASE WHEN total_deaths_per_million IS NULL THEN 1 ELSE 0 END) / COUNT(*) AS total_deaths_per_million_null_percent
FROM PortfolioProject..CovidDeaths;


-- Let's see what's happening with NULL values in the 'continent' column.
-- It is time to inspect the levels of this factor.
SELECT
   continent,
   COUNT(*) AS N_rows 
FROM
   PortfolioProject..CovidDeaths 
GROUP BY
   continent;
--As you can see here, there are 8,812 NULL values associated to the 'continent' column.


-- You may have already notice (See Query #1) that some observations within the 'location' column include continent names or the word 'world'.
-- For each of those unexpected locations there are NULL values in the continent column.
-- So, to avoid pulling unwanted locations it is necessary to filter for those cases in which the 'continent' column has NULL values.
SELECT
   TOP 20 * 
FROM
   PortfolioProject..CovidDeaths 
WHERE
   continent IS NOT NULL 
ORDER BY
   location,
   DATE;


-- Before moving on to deeper questions, we are going to check how our data table looks like when only relevant columns are included
SELECT
   TOP 600 continent,
   location,
   date,
   population,
   total_cases,
   total_deaths,
   total_deaths_per_million 
FROM
   PortfolioProject..CovidDeaths 
WHERE
   continent IS NOT NULL 
ORDER BY
   location,
   date DESC;

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- GLOBAL NUMBERS
-- First of all, we are going to check the levels of the factor location, for those cases where continent has NULL values
-- Once you run the code you will see that there is a factor level named 'World', so we can obtain the global metrics using this filter
SELECT
   location,
   COUNT(*) AS N_rows 
FROM
   PortfolioProject..CovidDeaths 
WHERE
   continent IS NULL 
GROUP BY
   location;


-- Now, is time to inspect how many positive COVID-19 cases and deaths have accumulated worldwide since the pandemic began
SELECT
   MAX(CAST(total_cases AS INT)) AS TotalCumulativeCases,
   MAX(CAST(total_deaths AS INT)) AS TotalCumulativeDeaths 
FROM
   PortfolioProject..CovidDeaths 
WHERE
   location IN 
   (
      'World'
   )
;

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- LET'S BREAK THINGS DOWN CONTINENT
-- Total Cases by Continent: can be expressed as the SUM of the MAX(total_cases) from locations in the same continent.
SELECT
   continent,
   SUM(MaxTotalCases) AS TotalCases 
FROM
   (
      SELECT
         continent,
         location,
         MAX(CAST(total_cases AS INT)) AS MaxTotalCases 
      FROM
         PortfolioProject..CovidDeaths 
      GROUP BY
         continent,
         location 
   )
   as inner_query 
WHERE
   continent IS NOT NULL 
GROUP BY
   continent 
ORDER BY
   TotalCases DESC;


-- Total Deaths by Continent: can be expressed as the SUM of the MAX(total_deaths) from locations in the same continent.
SELECT
   continent,
   SUM(MaxTotalDeaths) AS TotalDeaths 
FROM
   (
      SELECT
         continent,
         location,
         MAX(CAST(total_deaths AS INT)) AS MaxTotalDeaths 
      FROM
         PortfolioProject..CovidDeaths 
      GROUP BY
         continent,
         location 
   )
   as inner_query 
WHERE
   continent IS NOT NULL 
GROUP BY
   continent 
ORDER BY
   TotalDeaths DESC;

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- LET'S SEE WHAT'S GOING ON WITH COUNTRIES
-- Looking at countries with highest infection rate compared to population
SELECT
   location,
   population,
   MAX(total_cases) as HighestInfectionCount,
   MAX((total_cases / population))*100 AS PercentPopulationInfected 
FROM
   PortfolioProject..CovidDeaths 
WHERE
   continent IS NOT NULL 
GROUP BY
   location,
   population 
ORDER BY
   PercentPopulationInfected DESC;


-- Showing Countries with Highest Death Count per Population
SELECT
   location,
   population,
   MAX(CAST(total_deaths AS INT)) AS TotalDeathCount 	--We need to coerce total_deaths from nvarchar to integer (INT)
,
   MAX((total_deaths / population))*100 AS PercentPopulationDead 
FROM
   PortfolioProject..CovidDeaths 
WHERE
   continent IS NOT NULL 
GROUP BY
   location,
   population 
ORDER BY
   PercentPopulationDead DESC;


-- Deaths per million
SELECT
   location,
   population,
   MAX(CAST(total_deaths_per_million AS FLOAT)) AS TotalDeathsPerMillion 	--We need to coerce total_deaths_per_million from nvarchar to integer (INT)
FROM
   PortfolioProject..CovidDeaths 
WHERE
   continent IS NOT NULL 
GROUP BY
   location,
   population 
ORDER BY
   TotalDeathsPerMillion DESC;

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- CASE ANALYSIS: COSTA RICA (CENTRAL AMERICA)
-- Looking at Total Cases vs Total Deaths
-- I created a new column showing death percentages relative to daily positives
SELECT
   location,
   date,
   total_cases,
   total_deaths,
   (
      total_deaths / total_cases
   )
   *100 AS DeathPercentage 
FROM
   PortfolioProject..CovidDeaths 
WHERE
   total_cases IS NOT NULL 
   AND 	--Removing null values
   total_deaths IS NOT NULL 
   AND 	--Removing null values
   location LIKE '%Costa Rica%' --Selecting locations that include the word 'Costa Rica'
ORDER BY
   1,
   2 DESC;


-- Looking at the total cases vs population
-- Shows what percentage of population got Covid-19
SELECT
   location,
   date,
   total_cases,
   population,
   (
      total_cases / population
   )
   *100 AS PercentPopulationInfected 
FROM
   PortfolioProject..CovidDeaths 
WHERE
   location = 'Costa Rica' 
ORDER BY
   1,
   2 DESC;

------------------------------------------------------------------------------------------------------------------------
/*
OVERALL CONCLUSIONS:

1) Over 260 million of COVID-19 cases have been reported since the pandemic started. About 5 million people have passed as a 
consequence of this desease.

2) To date (December 2021), Asia is the continent with the highest cumulative COVID-19 cases, reaching over 82 million.

This is true when we consider North and South America as separate continents. On the other hand, the American continent 
should be consider as the most affected with over 98 million of positive cases.

3) Europe presents the highest total death count, with over 1.4 million deaths, followed by Asia (1.2 million), South America
(1.1 million), North America (1.1 million), Africa(0.2 million), and Oceania (0.003 million).

4) Peru (South America) has the highest mortality rate with 6,038 deaths per million.

5) In Costa Rica, total cases amount up to five hundred thousand, representing the 11% of the entire population.
By December 7th 2021, the country reported about seven thousand deaths.
*/
------------------------------------------------------------------------------END---------------------------------------------------------------------------------------------------------