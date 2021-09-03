-- Cleaning Data in SQL

-- Topics Covered from Queries below:
	-- 1. Alter Table, Columns, & Data Types
	-- 2. Using self join to populate & update null values from the same table
	-- 3. Using SUBSTRING, CHARINDEX, and LEN to create valued data columns via delimiters
	-- 4. Using store procedure to rename newly created column names 
	-- 5. Using PARSENAME to replace ',' then split data via '.' for valued columns
	-- 6. Rollback Transactions
	-- 7. Altering & Updating multiple columns vs individually
	-- 8. Modifying data using CASE statements
	-- 9. CTE / WITH Statement using Row_Number, Over, Partition by, order by
   -- 10. Modifying Views - Create, Drop / Alter, Delete
GO


Select *
from PortfolioProject1.dbo.NashvilleHousing

--------------------------------------------------------------------------------------------------------------------------

-- Convert & Update Date Format
--	Current Data Type = Datetime

Alter Table NashvilleHousing
ALTER Column SaleDate date

Select SaleDate
from PortfolioProject1.dbo.NashvilleHousing

--Select SaleDate, CONVERT(date, SaleDate)
--from PortfolioProject1.dbo.NashvilleHousing

--Update NashvilleHousing
--SET SaleDate = CONVERT(Date, SaleDate)

-- Alter = Data Definition Language
-- Update = Data Manipulation Language

 --------------------------------------------------------------------------------------------------------------------------

-- Populate Property Address data (some data is blank)
--		(address column contains address and city)

--		Looking at ParcelID and PropertyAddress, we see these 2 columns relate to one another. ie, ParcelID 1 = Address 1

Select *
from PortfolioProject1.dbo.NashvilleHousing
Where PropertyAddress is null
order by ParcelID

--Self Join to match the 2 Columns
--Query Below Shows A address is null has a populated B address with A & B having the same ParcelIDs

Select A.ParcelID, A.PropertyAddress, B.ParcelID, B.PropertyAddress
from PortfolioProject1.dbo.NashvilleHousing as A
Join PortfolioProject1.dbo.NashvilleHousing as B
	on A.ParcelID = B.ParcelID
	And A.[UniqueID ] <> B.[UniqueID ] -- this is because these are unique ids even if the addresses are the same
Where A.PropertyAddress is null
order by A.ParcelID


-- How to populate the null data
-- So ISNULL(what do we want to check, what data do we want to replace it with)

Select A.ParcelID, A.PropertyAddress, B.ParcelID, B.PropertyAddress,
		ISNULL(A.PropertyAddress,B.PropertyAddress)
from PortfolioProject1.dbo.NashvilleHousing as A
Join PortfolioProject1.dbo.NashvilleHousing as B
	on A.ParcelID = B.ParcelID
	And A.[UniqueID ] <> B.[UniqueID ] -- this is because these are unique ids even if the addresses are the same
Where A.PropertyAddress is null
order by A.ParcelID

--Updating the NULL values in A.PropertyAddress

Update A
SET PropertyAddress = ISNULL(A.PropertyAddress,B.PropertyAddress)
from PortfolioProject1.dbo.NashvilleHousing as A
Join PortfolioProject1.dbo.NashvilleHousing as B
	on A.ParcelID = B.ParcelID
	And A.[UniqueID ] <> B.[UniqueID ]
Where A.PropertyAddress is null

--Confirm with query before update, no rows = no more null values in A.PropertyAddress column
GO
--------------------------------------------------------------------------------------------------------------------------

-- Separating PropertyAddress & OwnerAddresses into Individual Columns (Address, City, State)

--The delimiter in both columns is a ','
--Can simply google the addresses to identify the data is (Street, City, State)

-- SubString
Select PropertyAddress, OwnerAddress
from PortfolioProject1.dbo.NashvilleHousing

-- How do to get just the Property address only and without the ','?
Select PropertyAddress,
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1 ) as Address, -- -1 removes the ','
CHARINDEX(',', PropertyAddress) -1 as ReturnedPosition -- #18 = ',' location, return everything up to this position
from PortfolioProject1.dbo.NashvilleHousing

-- How to Return just the City name from PropertyAddress?
Select PropertyAddress,
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1 ) as Address, 
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress)) as City, -- here for the 2nd argument in substring, +1 gives the ',' location
CHARINDEX(',', PropertyAddress) + 1 as CityPositionNum, -- Can see that the 'G' in  Goodlettsville is located on position 20 in the row
LEN(PropertyAddress) as EndingPoint
from PortfolioProject1.dbo.NashvilleHousing

-- SUBSTRING ( Column to return data ,starting position , length or num of characters to return )
-- CHARINDEX ( expressionToFind , expressionToSearch [ , start_location ] ) 
GO

-- Final Query: Creating 2 New Columns
Select
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1 ) as Address,
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress)) as City
from PortfolioProject1.dbo.NashvilleHousing

-- Creating 2 column on the table by adding the query data above

ALTER TABLE NashvilleHousing
Add StreetAddress Nvarchar(255);

BEGIN TRANSACTION -- allows for modification if query does not turn out as expected

Update NashvilleHousing
SET StreetAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1 )

Select PropertyAddress, StreetAddress -- this name was updated later ob from sp_name
from PortfolioProject1.dbo.NashvilleHousing 

ROLLBACK TRAN

ALTER TABLE NashvilleHousing
Add City Nvarchar(255);

Update NashvilleHousing
SET City = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress))

Select PropertyAddress, StreetAddress, City
from PortfolioProject1.dbo.NashvilleHousing 

-- Renaming the newly created Columns via store procedure
EXEC sp_rename 'dbo.NashvilleHousing.StreetAddress', 'PropStreetAddress', 'COLUMN';
EXEC sp_rename 'dbo.NashvilleHousing.City', 'PropCity', 'COLUMN';
GO

-- OwnerAddress Data Extraction via ParseName

-- Just need to know parsename looks for '.' as the delimiter and reads from right to left
Select OwnerAddress
from PortfolioProject1.dbo.NashvilleHousing 

Select OwnerAddress,
PARSENAME(REPLACE(OwnerAddress,',','.'),3) as Street,
PARSENAME(REPLACE(OwnerAddress,',','.'),2) as City,
PARSENAME(REPLACE(OwnerAddress,',','.'),1) as State
from PortfolioProject1.dbo.NashvilleHousing 

-- Adding these 3 Columns

Begin Tran
ALTER TABLE NashvilleHousing
Add OwnerStreetAddress Nvarchar(255),
	OwnerCity Nvarchar(255),
	OwnerState Nvarchar(255);

Select *
from PortfolioProject1.dbo.NashvilleHousing
Rollback Tran

Begin Tran
Update NashvilleHousing
SET OwnerStreetAddress = PARSENAME(REPLACE(OwnerAddress,',','.'),3),
	OwnerCity = PARSENAME(REPLACE(OwnerAddress,',','.'),2),
	OwnerState = PARSENAME(REPLACE(OwnerAddress,',','.'),1);
Select *
from PortfolioProject1.dbo.NashvilleHousing
Rollback Tran

--Final Query (Before & After)
Select PropertyAddress, PropStreetAddress, PropCity, OwnerAddress, OwnerStreetAddress, OwnerCity,OwnerState
from PortfolioProject1.dbo.NashvilleHousing 
GO
--------------------------------------------------------------------------------------------------------------------------


-- Case Statement - Change Y and N to Yes and No in "Sold as Vacant" field


-- Inital Data provides 4 categories of answers, after update there are 2
Select Distinct(SoldAsVacant), Count(*) as Count
from PortfolioProject1.dbo.NashvilleHousing
group by SoldAsVacant
order by 2 DESC

Select SoldAsVacant,
	CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
		 WHEN SoldAsVacant = 'N' THEN 'No'
		 ELSE SoldAsVacant
		 END
from PortfolioProject1.dbo.NashvilleHousing
Group by SoldAsVacant

Update NashvilleHousing
SET SoldAsVacant = 	CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
						 WHEN SoldAsVacant = 'N' THEN 'No'
						 ELSE SoldAsVacant
						 END
from PortfolioProject1.dbo.NashvilleHousing

-----------------------------------------------------------------------------------------------------------------------------------------------------------

-- Remove Duplicates (not ideal to delete data)

--CTE and use windows functions to find duplicate values


-- How do you identify if the data is not unique? Assuming UniqueID is not a column
		-- There are identifies like SaleDate, LegalReference, ParcelID...
Select *,

	ROW_NUMBER() OVER (
	PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference
	ORDER BY UniqueID
	) RowNum

from PortfolioProject1.dbo.NashvilleHousing
order by ParcelID

-- However, this query isn't too helpful because you can't reference the window function column name "RowNum"

--Creating a CTE to reference the created columne

WITH RowNumCTE AS(
		Select *,
			ROW_NUMBER() OVER (
			PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference
			ORDER BY UniqueID
			) RowNum
		from PortfolioProject1.dbo.NashvilleHousing
		)
DELETE -- Select * shows 104 rows, we want to delete this
From RowNumCTE
Where RowNum > 1


-- Checking for Duplicates after deletion:
WITH RowNumCTE AS(
		Select *,
			ROW_NUMBER() OVER (
			PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference
			ORDER BY UniqueID
			) RowNum
		from PortfolioProject1.dbo.NashvilleHousing
		)
Select *
From RowNumCTE
Where RowNum > 1
GO
---------------------------------------------------------------------------------------------------------

-- Modifying View: Create, Drop / Alter, Delete

Create view NashvilleHousingColumns as

	Select [UniqueID ],ParcelID, PropertyAddress, PropStreetAddress, PropCity, OwnerAddress, OwnerStreetAddress, OwnerCity, OwnerState
	from PortfolioProject1.dbo.NashvilleHousing
GO

-- Alter View Columns
alter view NashvilleHousingColumns as
	Select [UniqueID ],ParcelID, PropStreetAddress, PropCity, OwnerStreetAddress, OwnerCity, OwnerState
From PortfolioProject1.dbo.NashvilleHousing
GO
Select *
From NashvilleHousingColumns
GO

--sys.views vs INFORMATION_SCHEMA.VIEWS

-- Same Results, just schema.views is more specific & complex
select * from sys.views
select * from INFORMATION_SCHEMA.VIEWS
GO

if exists(select * from sys.views where name = 'NashvilleHousingColumns')
	drop view dbo.NashvilleHousingColumns
GO

-- Dropping and Creating View without errors in 1 execution: (Can also be done to alter the view via changing create view data)

if exists(select * from INFORMATION_SCHEMA.VIEWS
where [TABLE_NAME] = 'NashvilleHousingColumns' and [TABLE_SCHEMA] = 'dbo')
   drop view dbo.NashvilleHousingColumns
GO
Create view NashvilleHousingColumns as

	Select [UniqueID ],ParcelID, PropertyAddress, PropStreetAddress, PropCity, OwnerAddress, OwnerStreetAddress, OwnerCity, OwnerState
	from PortfolioProject1.dbo.NashvilleHousing
GO
Select *
From NashvilleHousingColumns
GO
---------------------------------------------------------------------------------------------------------

-- Adding Rows to Views
-- NOTE: This adds a row to the base table
begin tran

insert into NashvilleHousingColumns([UniqueID ],ParcelID, PropStreetAddress, PropCity, OwnerStreetAddress, OwnerCity, OwnerState)
values (60000,'007','Fox Chase', 'North America','Fox Chase', 'North America', 'TN')

select * from NashvilleHousingColumns --View Name
order by [UniqueID ] DESC

rollback tran

select * from NashvilleHousing -- Table Name
order by [UniqueID ] DESC

-- Deleting Rows to Views

Select *
From NashvilleHousingColumns
Delete from NashvilleHousingColumns
Where [UniqueID ]= 60000
Order by 1
GO
select * from NashvilleHousingColumns
order by [UniqueID ] DESC
select * from NashvilleHousing
order by [UniqueID ] DESC


---------------------------------------------------------------------------------------------------------

-- Delete Unused Columns (Not Ideal)

--Select *
--From PortfolioProject1.dbo.NashvilleHousing


--ALTER TABLE PortfolioProject.dbo.NashvilleHousing
--DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress, SaleDate


---------------------------------------------------------------------------------------------------------