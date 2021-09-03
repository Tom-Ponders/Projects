-- Query 2: Using Covid Vaccination & Covid Death Tables

-- Topics Covered from Queries below:
	-- 1. inner join
	-- 2. join & where using multiple conditions
	-- 3. Over, Partition by, & order by clauses
	-- 4. Using CTE to calculate % vaccinated / population partition by location
	-- 5. Creating a temp table to calculate % vaccinated / population partition by location
	-- 6. Creating a view to store data for visualizations
	-- 7. Finding the view in sys.objects

--Note: Data used from:
-- https://ourworldindata.org/covid-deaths
-- https://github.com/CSSEGISandData/COVID-19

--You can also google covid19 values to verify if query outputs are correct
GO


-- Joining our 2 tables together:
Select * 
From PortfolioProject1..CovidDeaths as CD
join PortfolioProject1..CovidVaccinations as Vacs
	on CD.location = Vacs.location
	and CD.date = Vacs.date
GO

-- Population and Vaccine data

-- What is the total people in the world that have been vaccinated?


-- Write a query to find the new vaccinations per day.
Select CD.continent, CD.location, CD.date, CD.population, Vacs.new_vaccinations
From PortfolioProject1..CovidDeaths as CD
join PortfolioProject1..CovidVaccinations as Vacs
	on CD.location = Vacs.location
	and CD.date = Vacs.date
Where CD.continent is not null
order by 1,2,3
GO

-- What is the 1st vaccinate date for the US?

Select CD.continent, CD.location, CD.date, CD.population, Vacs.new_vaccinations
From PortfolioProject1..CovidDeaths as CD
join PortfolioProject1..CovidVaccinations as Vacs
	on CD.location = Vacs.location
	and CD.date = Vacs.date
Where CD.location = 'United States'
	and Vacs.new_vaccinations is not null
order by 3
GO


-- How do you find the culmulative number of new vaccines via the new vaccinations column?

Select CD.continent, CD.location, CD.date, CD.population, Vacs.new_vaccinations,
		SUM(CONVERT(int, Vacs.new_vaccinations)) OVER (Partition by CD.location, CD.Date) as TotalVaccinated

	-- the partition will only summarize data by the different countries and restart the count per location
	-- if you don't separate by date, your new column will just show you the total values on each row which isn'thelpful

From PortfolioProject1..CovidDeaths as CD
join PortfolioProject1..CovidVaccinations as Vacs
	on CD.location = Vacs.location
	and CD.date = Vacs.date
Where CD.continent is not null
order by 1,2,3
GO


-- How do you use the above query to find % vaccinated / population?
		-- Via using the population and our created column 'TotalVaccinated'
		-- BUT the query above won't know how to reference our new column 

		-- To reference the new column, create a CTE or temp table
GO


-- Using a CTE (Common Table Expression):
With PopulationVac (continent, location, date, population, new_vaccinations, TotalVaccinated)
as
	(
		Select CD.continent, CD.location, CD.date, CD.population, Vacs.new_vaccinations,
			SUM(CONVERT(int, Vacs.new_vaccinations))
			OVER (Partition by CD.location order by CD.location, CD.Date) as TotalVaccinated
		From PortfolioProject1..CovidDeaths as CD
		join PortfolioProject1..CovidVaccinations as Vacs
			on CD.location = Vacs.location
			and CD.date = Vacs.date
		Where CD.continent is not null
	)
Select *
From PopulationVac
order by 1,2,3
GO

-- This CTE allow us to do further calculations in the 2nd select statement by using the data

With PopulationVac (continent, location, date, population, new_vaccinations, TotalVaccinated)
as
	(
		Select CD.continent, CD.location, CD.date, CD.population, Vacs.new_vaccinations,
			SUM(CONVERT(int, Vacs.new_vaccinations))
			OVER (Partition by CD.location order by CD.location, CD.Date) as TotalVaccinated
		From PortfolioProject1..CovidDeaths as CD
		join PortfolioProject1..CovidVaccinations as Vacs
			on CD.location = Vacs.location
			and CD.date = Vacs.date
		Where CD.continent is not null
	)
Select *,
		(TotalVaccinated / population) * 100 as Percent_Vaccinated
From PopulationVac
GO

-- Using a Temp Table instead of a CTE

DROP Table if exists #PercentOfPopulationVaccinated
Create Table #PercentOfPopulationVaccinated
(
	Continent nvarchar(255),
	Location nvarchar(255),
	Date datetime,
	Population numeric,
	new_vaccinations numeric,
	TotalVaccinated numeric
)

Insert into #PercentOfPopulationVaccinated
		Select CD.continent, CD.location, CD.date, CD.population, Vacs.new_vaccinations,
			SUM(CONVERT(int, Vacs.new_vaccinations))
			OVER (Partition by CD.location order by CD.location, CD.Date) as TotalVaccinated
		From PortfolioProject1..CovidDeaths as CD
		join PortfolioProject1..CovidVaccinations as Vacs
			on CD.location = Vacs.location
			and CD.date = Vacs.date
		Where CD.continent is not null

Select *,
		(TotalVaccinated / population) * 100 as Percent_Vaccinated
From #PercentOfPopulationVaccinated
GO

-- Creating a view
GO

--How do you put the below query in a view?

		-- create view viewname as
		--		select statement you want someone to view
GO

---- Creating view to store data for later visualizations
Drop view dbo.PercentOfPopulationVaccinated
go

Create View PercentOfPopulationVaccinated as

		Select CD.continent, CD.location, CD.date, CD.population, Vacs.new_vaccinations,
			SUM(CONVERT(int, Vacs.new_vaccinations))
			OVER (Partition by CD.location order by CD.location, CD.Date) as TotalVaccinated
		From PortfolioProject1..CovidDeaths as CD
		join PortfolioProject1..CovidVaccinations as Vacs
			on CD.location = Vacs.location
			and CD.date = Vacs.date
		Where CD.continent is not null
GO

select *
from dbo.PercentOfPopulationVaccinated
GO

-- Finding the view in sys.objects
select * from sys.objects
where name = 'PercentOfPopulationVaccinated'
GO

-- 2nd View
create view vContinents as
Select continent,
	MAX(cast(total_deaths as int)) as TotalDeathCount
From PortfolioProject1..CovidDeaths
Where continent is not null
group by continent
--order by TotalDeathCount DESC
GO

select *
from vContinents
GO
