/*1. Standarise Date Format*/

SELECT SaleDate
FROM dbo.HousingData 

ALTER TABLE dbo.HousingData
ADD SaleDateF DATE;

UPDATE dbo.HousingData
SET SaleDateF = CONVERT(DATE, SaleDate, 103);

ALTER TABLE dbo.HousingData
DROP COLUMN SaleDate;

sp_rename 'HousingData.SaleDateF', 'SaleDate', 'COLUMN' ------ Using CONVERT(DATE, SaleDate, 103) would be much more effiecient sollution, but I did not work and I couldn't figure it out why.

/*2. Populate Property Address Data*/

SELECT ParcelID, PropertyAddress
FROM HousingData
ORDER BY ParcelID ------ Run to check, if parcels of the same ParcelID have the same address (if not null)

SELECT 
	A.ParcelID
	,A.PropertyAddress
	,B.ParcelID
	,B.PropertyAddress
FROM HousingData A
	INNER JOIN HousingData B
	ON A.ParcelID = B.ParcelID
	AND A.[UniqueID ] <> B.[UniqueID ]
WHERE A.PropertyAddress IS NULL ----Set a join to replace the addresses

BEGIN TRAN
UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress,b.PropertyAddress)
FROM HousingData A
	INNER JOIN HousingData B
	ON A.ParcelID = B.ParcelID
	AND A.[UniqueID ] <> B.[UniqueID ]
WHERE a.PropertyAddress IS NULL
ROLLBACK TRAN ----Check the number of the rows affected, then run without the TRAN

SELECT ParcelID, PropertyAddress
FROM HousingData
WHERE PropertyAddress IS NULL
ORDER BY ParcelID ---Check the effects - no rows without the address

/*3. Break out address into individual columns (Address, City, State)*/

SELECT
	SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1) AS Address ----Extract the number of characters from PropertyAddress, which is equal to the ',' position -1)
	,SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress)) AS City ----Extract the number of characters from PropertyAddress from the ',' +1 to the end of string)
FROM HousingData

ALTER TABLE dbo.housingdata
ADD PropertySplitAddress NVARCHAR(MAX);

ALTER TABLE dbo.housingdata
ADD PropertySplitCity NVARCHAR(MAX);

UPDATE dbo.housingdata
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress))

UPDATE dbo.HousingData
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1)

SELECT
	PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3) AS OwnerSplitAddress
	,PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2) AS OwnerSplitCity
	,PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1) AS OwnerSplitState
FROM HousingData							---------Easier way of seperating into the columns - the PARSENAME function splits text between '.', therefore had to replace the ',' with '.'. Parsename reads from right

ALTER TABLE dbo.housingdata
ADD OwnerSplitAddress NVARCHAR(MAX);

ALTER TABLE dbo.housingdata
ADD OwnerSplitCity NVARCHAR(MAX);

ALTER TABLE dbo.housingdata
ADD OwnerSplitState NVARCHAR(MAX);

UPDATE HousingData
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3);

UPDATE HousingData
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2);

UPDATE HousingData
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1);

/*4. Replace Y and N with Yes and No in 'Soldasvacant' field*/

SELECT *
FROM HousingData
WHERE SoldAsVacant NOT IN ('Yes', 'No') ----- check

UPDATE HousingData
SET SoldAsVacant =
CASE WHEN SoldAsVacant = 'N' THEN 'No'
	WHEN SoldAsVacant = 'Y' THEN 'Yes'
	ELSE SoldAsVacant END

/*5. Remove Duplicates*/

WITH RowNumberCTE AS(
SELECT *
	,ROW_NUMBER () OVER (
	PARTITION BY ParcelID
				,PropertyAddress
				,SalePrice
				,SaleDate
				,LegalReference
				ORDER BY
				UniqueID
				) AS RowNum
FROM HousingData
)
DELETE 
FROM RowNumberCTE
WHERE RowNum > 1

--SELECT *
--FROM RowNumberCTE ---- Check if worked. To run: comment out 119 to 121.


/*6. Delete Unused Columns*/
	
ALTER TABLE HousingData
DROP COLUMN OwnerAddress, PropertyAddress

SELECT *
FROM HousingData