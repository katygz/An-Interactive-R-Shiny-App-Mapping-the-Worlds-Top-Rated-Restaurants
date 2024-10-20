--Create Agent Table
CREATE TABLE Agent (
    AgentID INT PRIMARY KEY,
    Name VARCHAR(255) NOT NULL,
    PhoneNum VARCHAR(15) NOT NULL,
    Office INT NOT NULL 
);

--Create House Table
	PropertyID PRIMARY KEY,
    Address VARCHAR(255) NOT NULL,
	Latitude FLOAT NOT NULL,
	Longtitude FLOAT NULL,
    SquareFootage INT NULL,
    NumberOfRooms INT NOT NULL,
    NumberOfBedrooms INT NOT NULL,
    NumberOfGarage INT NOT NULL,
    Description VARCHAR(255) NOT NULL
);

--Create Listing Table
CREATE TABLE Listing (
    ListingID INT PRIMARY KEY,
    PropertyID INT NOT NULL,
    AgentID INT,
    ListDate DATE NOT NULL,
    ListPrice DECIMAL(10,2) NOT NULL,
    Status VARCHAR(50) NOT NULL,
	SoldDate  DATE　NOT NULL,
    FOREIGN KEY (PropertyID) REFERENCES House(PropertyID),
    FOREIGN KEY (AgentID) REFERENCES Agent(AgentID)
);

--Create SalesContract
CREATE TABLE SalesContract (
    ContractID INT PRIMARY KEY,
    AgentID INT NOT NULL,
    SaleDate DATE NOT NULL,
    TotalSalePrice DECIMAL (10,2) NOT NULL,
    ContractDetail VARCHAR (255) NOT NULL,
    ListingID INT,
    PropertyID INT NOT NULL,
    FOREIGN KEY (AgentID) REFERENCES Agent(AgentID),
    FOREIGN KEY (PropertyID) REFERENCES House(PropertyID),
    FOREIGN KEY (ListingID) REFERENCES Listing(ListingID)
);



----House Closed by Agents
SELECT
        PropertyID
        ,ListPrice
        ,DATEDIFF(day, ListDate, SoldDate) AS ListOnMarket
        ,A.AgentID
        ,A.Name
        ,A.Office 
      FROM Agent A
      INNER JOIN Listing L ON A.AgentID = L.AgentID
      WHERE L.Status = 'Sold'

--Dallas House Analytics
SELECT
      ListPrice
      ,DATEDIFF(day, ListDate, SoldDate) AS ListOnMarket
    FROM [ITOM6265_F23_Group8].[dbo].[Agent] A 
    INNER JOIN Listing L ON A.AgentID = L.AgentID
    WHERE L.Status = 'Sold';

-- Delete Sales Contract
DELETE FROM House 
                  WHERE PropertyID = ''

---House Filter
SELECT * 
	   FROM House
       WHERE NumberOfBedRooms BETWEEN 1 AND 6
       AND NumberOfBathRooms BETWEEN 1 AND 8
       AND NumberOfGarage BETWEEN 0 AND 4
       AND ListPrice BETWEEN 20000 AND 10000000
       AND SquareFootage BETWEEN 500 AND 5000

--Update Home Listing
-- Tracation Method
--START TRANSACTION;

UPDATE Listing
SET ListPrice = 800000
WHERE PropertyID = 35;

UPDATE House
SET ListPrice = 800000
WHERE PropertyID = 35;

COMMIT;

--Modify two tables simultanously
UPDATE Listing
INNER JOIN House ON Listing.PropertyID = House.PropertyID
SET Listing.ListPrice = 800000, -- This updates the ListPrice in the Listing table
    House.ListPrice = 800000     -- This updates the ListPrice in the House table
WHERE Listing.PropertyID = 35;    -- This specifies which PropertyID to update

--Integrate
-- Start transaction
BEGIN TRANSACTION;

-- Variables to hold user inputs and intermediate values (Replace the placeholders with actual values)
DECLARE @ListingID INT = [input$listingID];
DECLARE @PropertyID INT = [input$propertyID];
DECLARE @NewPrice MONEY = [input$newPrice];
DECLARE @ActualPropertyID INT;
DECLARE @OldPrice MONEY;
DECLARE @AvgPrice MONEY;
DECLARE @Difference MONEY;
DECLARE @DifferenceFromAvg MONEY;

-- Check if both IDs are provided and validate their match
IF (@ListingID IS NOT NULL AND @PropertyID IS NOT NULL)
BEGIN
    SELECT @ActualPropertyID = PropertyID FROM Listing WHERE ListingID = @ListingID;
    IF (@ActualPropertyID IS NOT NULL AND @ActualPropertyID != @PropertyID)
    BEGIN
        -- The Property ID and Listing ID do not match.
        -- Error handling here
        ROLLBACK TRANSACTION;
        RETURN;
    END
END

-- Determine the PropertyID
IF (@PropertyID IS NOT NULL)
BEGIN
    SET @ActualPropertyID = @PropertyID;
END
ELSE
BEGIN
    SELECT @ActualPropertyID = PropertyID FROM Listing WHERE ListingID = @ListingID;
    IF (@ActualPropertyID IS NULL)
    BEGIN
        -- No corresponding PropertyID found for the given ListingID.
        -- Error handling here
        ROLLBACK TRANSACTION;
        RETURN;
    END
END

-- Retrieve the old price for comparison
SELECT @OldPrice = ListPrice FROM Listing WHERE PropertyID = @ActualPropertyID;

-- Update the listing price in Listing table
UPDATE Listing
SET ListPrice = @NewPrice
WHERE PropertyID = @ActualPropertyID;

-- Update the listing price in House table
UPDATE House
SET ListPrice = @NewPrice
WHERE PropertyID = @ActualPropertyID;

-- Commit the transaction
COMMIT TRANSACTION;

-- Calculate the difference and average
SELECT @AvgPrice = AVG(ListPrice) FROM Listing;
SET @Difference = @NewPrice - @OldPrice;
SET @DifferenceFromAvg = @NewPrice - @AvgPrice;


--Insert New Home
INSERT INTO House(PropertyID, Address,SquareFootage,NumberOfBedRooms,NumberOfBedRooms,NumberOfGarage, ListPrice,Description)
Values(50, 5127 W Amherst Ave, Dallas, TX 75209, 1495, 3,2,2,950000,Single Family Residence, buit in 1940)