/* 

COVID19 Exploratory Analysis using SQL-SERVER

Shine Jayakumar
shinejayakumar@yahoo.com



Data Source: ourworldindata.org

 https://covid.ourworldindata.org/data/owid-covid-data.xlsx
 https://github.com/owid/covid-19-data/tree/master/public/data

*/



SELECT MIN(date), MAX(date) fROM covid19timeseries

-- Setting Right Data Types
ALTER TABLE covid19timeseries ALTER COLUMN total_deaths FLOAT
ALTER TABLE covid19timeseries ALTER COLUMN new_deaths FLOAT
ALTER TABLE covid19timeseries ALTER COLUMN [reproduction_rate] FLOAT
ALTER TABLE covid19timeseries ALTER COLUMN [icu_patients] FLOAT
ALTER TABLE covid19timeseries ALTER COLUMN [hosp_patients] FLOAT
ALTER TABLE covid19timeseries ALTER COLUMN [weekly_icu_admissions] FLOAT
ALTER TABLE covid19timeseries ALTER COLUMN [weekly_hosp_admissions] FLOAT
ALTER TABLE covid19timeseries ALTER COLUMN  [positive_rate] FLOAT
ALTER TABLE covid19timeseries ALTER COLUMN [total_vaccinations] FLOAT
ALTER TABLE covid19timeseries ALTER COLUMN [people_vaccinated] FLOAT
ALTER TABLE covid19timeseries ALTER COLUMN [people_fully_vaccinated] FLOAT
ALTER TABLE covid19timeseries ALTER COLUMN [new_vaccinations] FLOAT

ALTER TABLE covid19timeseries ALTER COLUMN  [male_smokers] FLOAT
ALTER TABLE covid19timeseries ALTER COLUMN  [female_smokers] FLOAT
ALTER TABLE covid19timeseries ALTER COLUMN  [extreme_poverty] FLOAT


ALTER TABLE covid19timeseries ALTER COLUMN  [tests_per_case]  FLOAT
 

/*
 NOTE - continent IS NOT NULL is frequently used in queries
dataset also includes continents in location column - North America, Asia, Africa, Oceania, South America, Europe
continent	location
NULL		South America
NULL		Europe
NULL		North America
NULL		Africa
NULL		Asia
NULL		Oceania
 for these rows, continent is NULL. Excluding these from result set
*/

-- Show Top 50 Records
SELECT TOP 50 * FROM covid19timeseries

-- Global Numbers - Total Cases,Total Deaths, And Death Percentage
SELECT SUM(total_cases) AS Total_Cases, SUM(total_deaths) AS Total_Deaths,
SUM(total_deaths)/SUM(total_cases)*100 AS DeathPercentage
FROM (
		SELECT location, MAX(total_cases) AS total_cases, MAX(total_deaths) AS total_deaths
		FROM covid19timeseries
		WHERE continent IS NOT NULL
		GROUP BY location
		HAVING MAX(total_cases) IS NOT NULL
	  ) AS Gbl_Numbers


-- List Of Countries Affected By Covid19
SELECT DISTINCT location AS 'List of Countries' FROM covid19timeseries
WHERE continent IS NOT NULL AND total_cases IS NOT NULL
ORDER BY location


-- Number Of Countries Affected By Covid19
SELECT COUNT(*) AS 'Number of Countries' FROM (
	SELECT DISTINCT location FROM covid19timeseries
		WHERE continent IS NOT NULL AND total_cases IS NOT NULL
) AS country_count



-- Date Of First Case Reported For Each Country 
SELECT location AS Country, MIN(date) AS FirstCaseReportedOn 
FROM covid19timeseries
WHERE continent IS NOT NULL AND total_cases IS NOT NULL
GROUP BY location
ORDER BY location


-- Total Cases Vs Total Deaths (All Countries) - Observing Change With Time
SELECT location AS Country, date, population, total_cases AS cases, total_deaths AS deaths,
(total_cases/population) * 100 AS PercentPopulationInfected,
(total_deaths/total_cases)*100 AS DeathPercentage
FROM covid19timeseries
WHERE continent IS NOT NULL AND total_cases IS NOT NULL
ORDER BY location, date, population


-- Total Case Vs Total Deaths (India) - Observing Change With Time 
SELECT location AS Country, date, total_cases AS cases, total_deaths AS deaths, 
ROUND((total_deaths/total_cases)*100, 4) AS DeathPercentage
FROM covid19timeseries
WHERE location = 'India'
ORDER BY date



-- CASES_SUMMARY: Isolating Total Cases, Total Deaths For Each Country
CREATE VIEW cases_summary AS
SELECT location AS Country, population, 
MAX(total_cases) AS Total_Cases, 
MAX(total_deaths) AS Total_Deaths,
MAX(total_cases)/population*100 AS Infected_Population_Percentage, -- percentage of population infected
MAX(total_deaths)/population*100 AS Death_Population_Percentage,   -- percentage of population died due to covid
MAX(total_deaths)/MAX(total_cases)*100 AS Death_Percentage -- percentage of deaths out of total number of cases
FROM covid19timeseries
WHERE continent IS NOT NULL AND total_cases IS NOT NULL
GROUP BY location, population


-- Cases And Deaths Compared To Population
SELECT * FROM cases_summary 
ORDER BY Country, population


-- Cases And Deaths Compared To Population (India)
SELECT * FROM cases_summary WHERE Country = 'India'


-- Highest To Lowest Death Count
SELECT Country, population, Total_Deaths
FROM cases_summary
ORDER BY Total_Deaths DESC



-- Cases And Deaths - Continent Wise
SELECT location, MAX(total_cases) AS Total_Cases, MAX(total_deaths) AS Total_Deaths
FROM covid19timeseries
WHERE continent IS NULL AND location NOT IN ('World', 'European Union', 'International')
GROUP BY location



-- Vaccination data 
DROP TABLE IF EXISTS #covidVaccinations
SELECT continent, location, date, new_vaccinations, total_vaccinations, people_vaccinated, people_fully_vaccinated, population
INTO #covidVaccinations
FROM covid19timeseries


-- Vaccination Start Date For Countries

SELECT location AS Country, MIN(date) AS VaccinationStartedOn
FROM #covidVaccinations
WHERE continent IS NOT NULL AND total_vaccinations IS NOT NULL AND total_vaccinations > 0 AND location = 'United States'
GROUP BY location
ORDER BY VaccinationStartedOn



-- Total No. Of People Vaccinated, Vaccination Percentage Of Population
SELECT location, population, 
MAX(people_vaccinated) AS PeopleVaccinated, 
MAX(people_vaccinated)/population*100 AS Percentage_of_population_vaccinated
FROM #covidVaccinations
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY location




-- COUNTRY DEMOGRAPHICS
DROP TABLE IF EXISTS #country_demographics 

WITH cte_countryDemog(location, population, population_density, median_age, aged_65_older, aged_70_older, gdp_per_capita, extreme_poverty, human_development_index)
AS
(
	SELECT location, 
	MAX(population) AS population,
	MAX(population_density) AS Population_Density,
	MAX(median_age) AS Median_Age,
	MAX(aged_65_older) AS Aged_65_Older,
	MAX(aged_70_older) AS Aged_70_Older,
	MAX(gdp_per_capita) AS Gdp_Per_Capita,
	MAX(extreme_poverty) AS Extreme_Poverty,
	MAX(human_development_index) AS Human_Development_Index
	FROM covid19timeseries
	WHERE continent IS NOT NULL
	GROUP BY location
)
SELECT * INTO #country_demographics 
FROM cte_countrydemog



-- COUNTRY HEALTH
DROP TABLE IF EXISTS #country_health

WITH cte_countryHealth (location, population, Stringency_Index, Cardiovascular_Death_Rate, Diabetes_Prevalence, Female_Smokers, Male_Smokers, Life_Expectancy)
AS
(
	SELECT location,
	MAX(population) AS population,
	MAX(stringency_index) AS Stringency_Index,
	MAX(cardiovasc_death_rate) AS Cardiovascular_Death_Rate,
	MAX(diabetes_prevalence) AS Diabetes_Prevalence,
	MAX(female_smokers) AS Female_Smokers,
	MAX(male_smokers) AS Male_Smokers,
	MAX(life_expectancy) AS Life_Expectancy
	FROM covid19timeseries
	WHERE continent IS NOT NULL
	GROUP BY location
)
SELECT * INTO #country_health 
FROM cte_countryHealth




-- VACCINATION SUMMARY 
DROP TABLE IF EXISTS #vaccination_summary

WITH cte_vaccination_summary (location, total_vaccinations, people_vaccinated, people_fully_vaccinated)
AS
(
	SELECT location,
	MAX(total_vaccinations),
	MAX(people_vaccinated),
	MAX(people_fully_vaccinated)
	FROM #covidVaccinations
	WHERE continent IS NOT NULL
	GROUP BY location
)
SELECT * INTO #vaccination_summary
FROM cte_vaccination_summary




-- TOP 5 countries with most people vaccinated (United States, India, United Kingdom)

SELECT TOP 5 location
FROM #vaccination_summary
ORDER BY people_vaccinated DESC

-- Above Countries With People Vaccinated and Percentage of population Vaccinated
SELECT vs.location, cd.population, vs.people_vaccinated AS people_vaccinated,
(vs.people_vaccinated/cd.population)*100 AS vaccinated_perc_of_population
FROM #vaccination_summary vs
JOIN #country_demographics cd
	ON vs.location = cd.location
WHERE vs.location IN (
					SELECT TOP 5 location
					FROM #vaccination_summary
					ORDER BY people_vaccinated DESC
					)
ORDER BY vaccinated_perc_of_population DESC



-- Comparing Diabetes Prevalence, Cardiovascular Death Rate To Death Percentage
SELECT cs.Country, ch.Cardiovascular_Death_Rate, ch.Diabetes_Prevalence, cs.Death_Percentage
FROM #country_health ch
JOIN cases_summary cs
	ON ch.location = cs.Country
ORDER BY Death_Percentage DESC



/*
 Stringency Index:	This is a composite measure based on nine response indicators including school closures, workplace
					closures, and travel bans, rescaled to a value from 0 to 100 (100 = strictest).
					The nine metrics used to calculate the Stringency Index are: school closures; workplace closures; 
					cancellation of public events; restrictions on public gatherings; closures of public transport; 
					stay-at-home requirements; public information campaigns; restrictions on internal movements; 
					and international travel controls.
*/

-- Comparing Stringency Index to Infected Population And Death Percentage
SELECT cs.Country, ch.Stringency_Index, cs.Infected_Population_Percentage, cs.Death_Percentage
FROM #country_health ch
JOIN cases_summary cs
	ON ch.location = cs.Country
ORDER BY Stringency_Index DESC



-- Comparing Smokers to Infected Population And Death Percentage
SELECT cs.Country, ch.Female_Smokers, ch.Male_Smokers, cs.Infected_Population_Percentage, cs.Death_Percentage
FROM #country_health ch
JOIN cases_summary cs
	ON ch.location = cs.Country
ORDER BY Male_Smokers DESC



-- Comparing Percentage Of Population Over 65 And 70 To Infected Population And Death Percentage
SELECT cs.Country, 
cd.aged_65_older AS Percetange_of_population_over_65,
cd.aged_70_older AS Percetange_of_population_over_70,
cs.Infected_Population_Percentage, cs.Death_Percentage
FROM #country_demographics cd
JOIN cases_summary cs
	ON cd.location = cs.Country
ORDER BY Percetange_of_population_over_65 DESC


/*
The Human Development Index (HDI) is a summary measure of average achievement in key dimensions 
of human development: a long and healthy life, being knowledgeable and have a decent standard of living.
*/
-- Comparing GDP, Human Development Index, Extreme Poverty To Vaccinated Population Percentage 

SELECT summary.Country, demog.gdp_per_capita AS GDP, 
AVG(demog.gdp_per_capita) OVER () AS AverageGDP,
demog.human_development_index, demog.extreme_poverty, 
(vacc.people_vaccinated / summary.population)*100 AS Vaccinated_population_percentage
FROM cases_summary summary
JOIN #vaccination_summary vacc
	ON vacc.location = summary.Country
JOIN #country_demographics demog
	ON demog.location = summary.Country
ORDER BY gdp_per_capita DESC



-- CORRELATION COEFFICIENT PROCEDURE
-- filter - use this to remove rows for which this column is null
ALTER PROCEDURE CORRELATION(@SourceTable VARCHAR(30), @x VARCHAR(20), @y VARCHAR(20), @country VARCHAR(20), @filter VARCHAR(20)=NULL)
AS
BEGIN
	
	DECLARE @query NVARCHAR(max)
	
	IF @country IS NOT NULL
		BEGIN

			-- Correlation Coefficient: (n*sum_xy - sum_x*sum_y)/SQRT( (n*sum_x_sqrd - sum_x^2) * (n*sum_y_sqrd - sum_y^2) )
			
			SET @query = 'SELECT (COUNT(*)*SUM(' + @x + '*' + @y + ') - SUM(' + @x + ')*SUM(' + @y +'))/SQRT( (COUNT(*)*SUM(' + @x + '*' + @x + ') - SUM(' + @x + ')*SUM(' + @x +')) * (COUNT(*)*SUM(' + @y + '*' + @y + ') - SUM(' + @y +')*SUM(' + @y + ')) ) As CorrCoef_' + @x + '_AND_' + @y  + '_' + REPLACE(@country, ' ','_') + ' FROM ' + @SourceTable + ' WHERE location = ''' + @country + ''''-- AND ' + @y + ' IS NOT NULL'
			IF @filter IS NOT NULL 
				SET @query = @query + ' AND ' + @y + ' IS NOT NULL'
			EXEC(@query)
		END
END




-- Result: United States, India, United Kingdom, Brazil, Germany


-- CORRELATION BETWEEN NEW VACCINATIONS AND NEW CASES
EXEC CORRELATION 'covid19timeseries', 'new_cases', 'new_vaccinations', 'United States', 'new_vaccinations'
EXEC CORRELATION 'covid19timeseries', 'new_cases', 'new_vaccinations', 'India', 'new_vaccinations'
EXEC CORRELATION 'covid19timeseries', 'new_cases', 'new_vaccinations', 'United Kingdom', 'new_vaccinations'
EXEC CORRELATION 'covid19timeseries', 'new_cases', 'new_vaccinations', 'Brazil', 'new_vaccinations'
EXEC CORRELATION 'covid19timeseries', 'new_cases', 'new_vaccinations', 'Germany', 'new_vaccinations'

-- United States: -0.583267771568118		Strong Negative Correlation
-- India: 0.501040976843601			Strong Positive Correlation
-- United Kingdom: -0.290257146338705		Small Negative Correlation
-- Brazil: 0.358391535662677			Medium Positive Correlaton
-- Germany: 0.396840377456182			Medium Positive Correlaton



-- CORRELATION BETWEEN NEW VACCINATIONS AND NEW DEATHS
EXEC CORRELATION 'covid19timeseries', 'new_deaths', 'new_vaccinations', 'United States', 'new_vaccinations'
EXEC CORRELATION 'covid19timeseries', 'new_deaths', 'new_vaccinations', 'India', 'new_vaccinations'
EXEC CORRELATION 'covid19timeseries', 'new_deaths', 'new_vaccinations', 'United Kingdom', 'new_vaccinations'
EXEC CORRELATION 'covid19timeseries', 'new_deaths', 'new_vaccinations', 'Brazil', 'new_vaccinations'
EXEC CORRELATION 'covid19timeseries', 'new_deaths', 'new_vaccinations', 'Germany', 'new_vaccinations'


-- United States: -0.648441168995185		Strong Negative Correlation
-- India: 0.38448386706475			Medium Positive Correlation
-- United Kingdom: -0.165474314697417		Small Negative Correlation
-- Brazil: 0.570892425601426			Strong Positive Correlaton
-- Germany: -0.351848722828281			Medium Negative Correlaton


-- Stringency Index and New Cases for Top 5 countries with most vaccinations done
SELECT location, date, new_cases, stringency_index
FROM covid19timeseries
WHERE location IN ('United States', 'India', 'United Kingdom','Brazil', 'Germany')
ORDER BY location, date

-- CORRELATION BETWEEN NEW VACCINATIONS AND STRINGENCY INDEX
EXEC CORRELATION 'covid19timeseries', 'new_cases', 'stringency_index', 'United States', 'stringency_index'
EXEC CORRELATION 'covid19timeseries', 'new_cases', 'stringency_index', 'India', 'stringency_index'
EXEC CORRELATION 'covid19timeseries', 'new_cases', 'stringency_index', 'United Kingdom', 'stringency_index'
EXEC CORRELATION 'covid19timeseries', 'new_cases', 'stringency_index', 'Brazil', 'stringency_index'
EXEC CORRELATION 'covid19timeseries', 'new_cases', 'stringency_index', 'Germany', 'stringency_index'

-- United States: 0.42158185958772		Medium Positive Correlation
-- India: 0.116429608970361			Small Positive Correlation
-- United Kingdom: 0.38956987468445		Medium Positive Correlation
-- Brazil: 0.191142054700063			Small Positive Correlaton
-- Germany: 0.4535756614707			Medium Positive Correlaton
