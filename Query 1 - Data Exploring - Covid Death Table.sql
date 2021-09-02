-- Query 1: Exploring the table dbo.CovidDeaths

-- Topics Covered from Queries Below:
	-- 1. Running basic queries to explore the CovidDeaths table 
	-- 2. Identifying wrong assumptions of how the data is organized & how this impacts the accuracy of results
	-- 3. Converting Data Types
	-- 4. Aggregate Functions


--Note: Data used from:
-- https://ourworldindata.org/covid-deaths
-- https://github.com/CSSEGISandData/COVID-19

--You can also google covid19 values to verify if query outputs are correct
GO

-- Query 1: Covid Death Data & Vaccination Data

Select *
From PortfolioProject1..CovidDeaths
--where continent is not null
--where location = 'North America'
order by 3,4

--Select *
--From PortfolioProject1..CovidVaccinations
--order by 3,4
GO

-- Data that I am going to be using:

Select Location, date, total_cases, new_cases, total_deaths, population
From PortfolioProject1..CovidDeaths
order by 1,2 -- based off location and date
GO

--Looking at the total cases vs total deaths
--how many cases are in the country, and how many deaths for their entire cases?
-- % of people who died that had covid?


--Shows the likelyhood of dying from covid per country selected
Select Location, date, total_cases, new_cases, total_deaths, (total_deaths/total_cases) * 100 as DeathPercentage
From PortfolioProject1..CovidDeaths
order by 1,2

Select Location, date, total_cases, new_cases, total_deaths, (total_deaths/total_cases) * 100 as DeathPercentage
From PortfolioProject1..CovidDeaths
Where location like '%states%'
order by 1,2
GO


-- Looking at total cases vs population
		--what % of the US population has contracted COVID-19?

Select Location, date, population, total_cases, new_cases, (total_cases/population) * 100 as PercentPopulationInfected
From PortfolioProject1..CovidDeaths
Where location like '%states%'
order by 1,2


-- What countries have the highest infection rates compared to their population?

Select Location, Population, MAX(total_cases) as MaxCovidCount, MAX((total_cases/population)) * 100 as PercentPopulationInfected
From PortfolioProject1..CovidDeaths
--Where location like '%states%'
group by Location, Population
order by PercentPopulationInfected DESC


-- What are the countires with highest deathcount per population?


-- Query Problem:
	--This query does not provide accurate numbers given total_deaths column's data type is nvarchar 255 and not an integer
Select Location, Population, MAX(total_deaths) as TotalDeathCount, MAX((total_deaths/population)) * 100 as PercentOfDeaths
From PortfolioProject1..CovidDeaths
group by Location, Population
order by PercentOfDeaths DESC

--Convert = Cast total deaths as an integer
Select Location, Population,
	MAX(cast(total_deaths as int)) as TotalDeathCount,
	MAX((total_deaths/population)) * 100 as PercentOfDeaths
From PortfolioProject1..CovidDeaths
group by Location, Population
order by PercentOfDeaths DESC


--Which countries have the highest total deaths?

	--Problem with query: We see data that shouldn't belong like 'World', 'European Union'...
	-- Our table has a continent column, but sometimes the data in 'Location' is a continent...
Select Location,
	MAX(cast(total_deaths as int)) as TotalDeathCount
From PortfolioProject1..CovidDeaths
group by Location
order by TotalDeathCount DESC


-- Correction: select locations that do not have a null continent value

Select Location,
	MAX(cast(total_deaths as int)) as TotalDeathCount
From PortfolioProject1..CovidDeaths
Where continent is not null
group by Location
order by TotalDeathCount DESC
GO

-- Write a query that shows the total deaths per continent


	--Problem: If you compare the query above and below, the North America data seems to be only showing the USA Data
Select continent,
	MAX(cast(total_deaths as int)) as TotalDeathCount
From PortfolioProject1..CovidDeaths
Where continent is not null
group by continent
order by TotalDeathCount DESC

-- So this helps us understand how the data table is arranged. 
	-- When the location column is naming a continent, the continent column is 'NULL'


--Correct the query by grouping via location and filter only null continent columns:

Select location,
	MAX(cast(total_deaths as int)) as TotalDeathCount
From PortfolioProject1..CovidDeaths
Where continent is null
group by location
order by TotalDeathCount DESC
GO


-- How do we visualize our data for tableu?

-- Global Analytics:

--Per Day
Select date,
		SUM(new_cases) as Total_Global_Cases,
		SUM(cast(new_deaths as int)) as Total_Global_Deaths,
		SUM(cast(new_deaths as int))/SUM(New_Cases) * 100 as Global_DeathPercentage
From PortfolioProject1..CovidDeaths
where continent is not null 
Group By date
order by 1,2

-- Global Data Aggregated
Select
		SUM(new_cases) as Global_Cases,
		SUM(cast(new_deaths as int)) as Global_Deaths,
		SUM(cast(new_deaths as int))/SUM(New_Cases) * 100 as Global_DeathPercentage
From PortfolioProject1..CovidDeaths
where continent is not null 
order by 1,2
GO