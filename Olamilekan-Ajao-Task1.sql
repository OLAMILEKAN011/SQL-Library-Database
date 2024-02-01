CREATE DATABASE CreedlyLibrary;

USE CreedlyLibrary;
GO

----Creating Tables

---To create Address Table
CREATE TABLE Address (
AddressId int IDENTITY PRIMARY KEY,
Address1 nvarchar(100) NOT NULL,
Address2 nvarchar(100) NOT NULL,
State nvarchar(50) NOT NULL,
Postcode nvarchar(7) NOT NULL);

---To create Members Table
CREATE TABLE Members (
MemberId int IDENTITY PRIMARY KEY,
FirstName nvarchar(50) NOT NULL,
LastName nvarchar(50) NOT NULL,
DateOfBirth date NOT NULL,
UserName nvarchar(50) UNIQUE NOT NULL CHECK 
(UserName LIKE '%'),
PasswordHash BINARY(64) NOT NULL,
Salt UNIQUEIDENTIFIER,
Email nvarchar(100) UNIQUE NULL CHECK 
(Email LIKE '%_@_%._%'),
Telephone nvarchar(20) NULL,
AddressId int NOT NULL FOREIGN KEY (AddressId) 
REFERENCES Address (AddressId));



---To create ItemType Table
CREATE TABLE ItemType (
Id int IDENTITY PRIMARY KEY,
ItemType nvarchar(20) NOT NULL CHECK (itemType IN ('Book','Journal','DVD','Other Media')));

---To create Author Table
CREATE TABLE Author (
Id int IDENTITY PRIMARY KEY,
AuthorFirstName nvarchar(50) NOT NULL,
AuthorLastName nvarchar(50) NOT NULL);


---To create Items Table
CREATE TABLE Items (
Id int IDENTITY PRIMARY KEY,
Title nvarchar(100) NOT NULL,
AuthorId int NOT NULL FOREIGN KEY (AuthorId) REFERENCES Author (Id),
TypeId int NOT NULL FOREIGN KEY (TypeId) REFERENCES ItemType (Id),
PublishedYear int NOT NULL,
ISBN VARCHAR(20) NULL,
DateAdded date NOT NULL,
CurrentStatus nvarchar(20) NOT NULL,
MemberId int NOT NULL FOREIGN KEY (MemberId) REFERENCES Members (MemberId));

UPDATE Items
SET PublishedYear = YEAR(PublishedYear)


---To create Loans Table
CREATE TABLE Loans (
Id int IDENTITY PRIMARY KEY,
MemberId int NOT NULL FOREIGN KEY (MemberId) 
REFERENCES Members (MemberId),
ItemId int NOT NULL FOREIGN KEY(ItemId)
REFERENCES Items (Id),
LoanStart date NOT NULL,
LoanDue date NOT NULL,
LoanEnd date NULL,
OverDueFee money NOT NULL);


---To create Lost/Removed Table
CREATE TABLE LostRemoved (
ItemId int NOT NULL PRIMARY KEY,
Title nvarchar(100) NOT NULL,
AuthorId int NOT NULL,
TypeId int NOT NULL,
ItemISBN nvarchar(20) NOT NULL,
DateIdentified date NOT NULL,
Id int NOT NULL FOREIGN KEY (AuthorId) 
REFERENCES Author (Id));


---To create MemberExit Table
CREATE TABLE MemberExit (
MemberId int NOT NULL PRIMARY KEY,
FirstName nvarchar(50) NOT NULL,
LastName nvarchar(50) NOT NULL,
DateOfBirth date NOT NULL,
UserName nvarchar(50) NOT NULL,
Password nvarchar(50) NOT NULL,
Email nvarchar(100) UNIQUE NULL CHECK (Email LIKE 
'%_@_%._%'),
Telephone nvarchar(10) NULL,
AddressId int NOT NULL FOREIGN KEY (AddressId) 
REFERENCES Address (AddressId),
EndDate date NOT NULL);


---To create Fine Table
CREATE TABLE Fine (
Id int IDENTITY PRIMARY KEY,
MemberId int NOT NULL FOREIGN KEY (MemberId) 
REFERENCES Members (MemberId),
TotalFine money NOT NULL,
AmountPaid money NOT NULL,
OutstandingDebt money NOT NULL);


---To create Payment Table
CREATE TABLE Payment (
Id int IDENTITY PRIMARY KEY,
MemberId int NOT NULL FOREIGN KEY (MemberId) 
REFERENCES Members (MemberId),
Date date NOT NULL,
Time time NULL,
AmountPaid money NOT NULL,
Method nvarchar(4) NOT NULL);




SELECT * FROM members.Members
SELECT * FROM members.address
SELECT * FROM items.Author
SELECT * FROM items.ItemType
SELECT * FROM items.Items
SELECT * FROM loans.Loans
SELECT * FROM transactions.fine
SELECT * FROM transactions.Payment
SELECT * FROM members.MemberExit
SELECT * FROM items.LostRemoved






---(Question 2)---Creating Stored Procedures

--(2a)

CREATE PROCEDURE TitleSearchProcedure 
    @title AS nvarchar(50)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP 100 PERCENT i.Title, i.PublishedYear, i.ISBN, t.Type, a.AuthorFirstName, a.AuthorLastName, i.CurrentStatus
    FROM items.Items AS i 
    INNER JOIN items.ItemType AS t ON i.TypeId=t.Id
    INNER JOIN items.Author AS a ON i.AuthorId = a.Id
    WHERE i.Title LIKE @title+'%'
    ORDER BY PublishedYear desc;

END

--Testing TitleSearchProcedure
EXEC TitleSearchProcedure @title = 'The'


--(2b)


CREATE PROCEDURE GetLoansDueWithinFiveDays
AS
BEGIN
    SET NOCOUNT ON;

    SELECT  i.id, l.MemberId, i.Title,i.CurrentStatus,l.LoanStart, l.LoanDue
FROM Loans.Loans AS l 
INNER JOIN items.Items AS i
ON l.ItemId = i.Id
    WHERE i.CurrentStatus = 'Loan' AND l.LoanDue >= GETDATE() AND l.LoanDue <= DATEADD(day, 5, GETDATE())
END


--Testing GetLoansDueWithinFiveDays Procedure
Exec GetLoansDueWithinFiveDays



--(2c)

-- Stored procedure to insert a new customer and account

Drop procedure InsertNewMember

CREATE PROCEDURE InsertNewMember
    @firstname nvarchar(50), @lastname nvarchar(50), @dateofbirth date, @userName nvarchar(50), 
	@password nvarchar(50), @email nvarchar(100), @telephone nvarchar(10), @address1 nvarchar(100),
	@address2 nvarchar(100), @state nvarchar(50), @postcode nvarchar(7)
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRANSACTION;

    BEGIN TRY
        DECLARE @id int;
		DECLARE @salt UNIQUEIDENTIFIER = NEWID()
        
        -- Insert address record
        INSERT INTO members.Address (Address1, Address2, State, Postcode)
        VALUES (@address1, @address2, @state, @postcode);
        
        SET @id = SCOPE_IDENTITY();

        -- Insert member record
        INSERT INTO members.Members (FirstName, LastName, DateOfBirth, UserName, PasswordHash, Salt, Email, Telephone, AddressID)
        VALUES (@firstname, @lastname, @dateofbirth, @userName, HASHBYTES('SHA2_512',@password+CAST(@salt AS nvarchar(36))), 
		@salt, @email, @telephone, @id);
        
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @ErrMsg nvarchar(4000), @ErrSeverity int;
        SELECT @ErrMsg = ERROR_MESSAGE(), @ErrSeverity = ERROR_SEVERITY();
        RAISERROR(@ErrMsg, @ErrSeverity, 1);
    END CATCH;
END;



--Testing InsertNewMember

Exec InsertNewMember
@firstname = 'James', @lastname = 'Reece', @dateofbirth = '1989-04-06', @userName = 'JReece', @password = 'uynbslsrtduhj',
@email = 'James@hotmail.com', @telephone = 7876672371, @address1 = '52 Wallace Street' , @address2 = 'St. Helens',
@state = 'Warrington', @postcode = 'WA4 7FJ'


Select * From Members.Members
Where FirstName = 'James'


---(2d)

 CREATE PROCEDURE UpdateMember
  @MemberId int, @FirstName nvarchar(50), @LastName nvarchar(50), @dateofbirth date, @email nvarchar(100), @telephone nvarchar(10),
  @address1 nvarchar(100), @address2 nvarchar(100), @state nvarchar(50), @postcode nvarchar(7), @addressId int
  
AS
BEGIN

  DECLARE @updatedMembers TABLE (MemberID int);

  UPDATE members.Address
	SET
	  Address1 = @address1,	  Address2 = @address2,  State = @state, Postcode = @postcode
  WHERE AddressId = @addressId;

  UPDATE Members.Members
  SET FirstName = @FirstName, LastName = @LastName, DateOfBirth = @dateofbirth,
      Email = @Email,  Telephone = @Telephone

  OUTPUT inserted.MemberID INTO @updatedMembers(MemberID)
  WHERE MemberID = @MemberID;

  IF @@ROWCOUNT = 0
  BEGIN
    RAISERROR('Member with ID %d not found.', 16, 1, @MemberID);
    RETURN;
  END;

  SELECT * FROM @updatedMembers;

END;


---Testing UpdateMember Procedure

Exec UpdateMember

@MemberId = 26, @firstname = 'Sabi', @lastname = 'Dure', @dateofbirth = '1985-10-15', @email = 'Sabi@globe.com', @telephone = 7256445361, 
@address1 = '42 Lamburn Ave' , @address2 = 'Picadilly', @state = 'Manchester', @postcode = 'M7 3LA', @addressId = 14



----( Question 3 ) CREATING VIEW FOR LOAN HISTORY

CREATE VIEW LoanHistory (
LoanId, MemberId, FirstName, LastName, ItemId, Title, AuthorFirstName, AuthorLastName, ItemType,
PublishedYear, ISBN, DateAdded, LoanStart, LoanDue, OverdueFee)
AS
SELECT 
L.Id, L.MemberId, M.FirstName, M.LastName, I.Id, I.Title, A.AuthorFirstName,A.AuthorLastName, T.Type,
I.PublishedYear, I.ISBN, I.DateAdded, L.LoanStart, L.LoanDue, L.OverdueFee
FROM loans.Loans L
INNER JOIN items.Items I ON
L.ItemId = I.Id
INNER JOIN members.Members M ON L.MemberId =M.MemberId
INNER JOIN items.Author A ON A.Id = I.AuthorId
INNER JOIN items.ItemType T ON i.TypeId = T.Id

---Testing LoanHistory View
SELECT * FROM LoanHistory



----( Question 4 ) CREATING TRIGGER TO UPDATE ITEM STATUS

DROP TRIGGER IF EXISTS loans.UpdateItemCurrentStatus;
GO

CREATE TRIGGER UpdateItemCurrentStatus 
ON Loans.loans
AFTER UPDATE
AS
BEGIN
    -- Check if the "LoanEnd" column was updated
    IF UPDATE(LoanEnd)
    BEGIN
        -- Check if the loaned item was returned
        IF EXISTS(SELECT 1 FROM inserted WHERE LoanEnd IS NOT NULL)
        BEGIN
            -- Update the "CurrentStatus" column in the "Items" table to "Available"
            UPDATE Items.Items
            SET CurrentStatus = 'Available'
            WHERE Id IN (SELECT Id FROM inserted WHERE LoanEnd IS NOT NULL)
        END
    END
END;

---Testing UpdateItemCurrentStatus Trigger
UPDATE loans.loans
SET LoanEnd = '2023-04-24' WHERE Id =11

---To view the updated result
Select * from loans.loans l
Join items.items i
On l.itemid = i.id
WHERE l.Id = 11



----( Question 5 ) CREATING FUNCTION THAT COUNTS THE TOTAL NUMBER OF LOANS IN A SPECIFIC DAY

DROP FUNCTION if EXISTS TotalLoan

CREATE FUNCTION TotalLoan (@LoanStart AS date)
RETURNS int
AS
BEGIN
RETURN
(SELECT COUNT(L.Id)
FROM loans.Loans AS L 
WHERE L.LoanStart = @LoanStart
)
END;

---Testing TotalLoan Function
SELECT dbo.TotalLoan('2023-04-05') AS TotalLoan

select * from loans.loans

----( Question 6 ) Inserting records to tables

INSERT INTO Members.Address
VALUES ('29 Grange Lane','Treak', 'Bolton', 'BL4 6ND'),
('9 Warrington Road','Lowton', 'Wigan', 'WN4 6BD'),
('4 Livepol Ave','Mathy Lane', 'Manchester', 'M6 7FY'),
('41 Salford Road','Salford', 'Manchester', 'M7 1GA'),
('22 Moston Lane','Moston', 'Manchester', 'M21 3KD'),
('81 Stanwey Road','Main', 'Bolton', 'BL4 4FT'),
('33 Walthew Lane','Platt Bridge', 'Wigan', 'WN2 5AH'),
('58 Green Road','Lowton', 'Warrington', 'WA4 4FT')


INSERT INTO Members.members
VALUES ('Lauren', 'Cole', '1985-01-08','lcole','lcolelcole','lcole@yahoo.com',7865782678,3),
('Matt', 'Kimberly', '1980-12-21','Mkim','mgftjkim','mkim@yahoo.com',7673456878,5),
('John', 'Kennedy', '1991-04-28','Jken','jkenjhddu','jken@gmail.com',76534879256,1),
('Kate', 'Nola', '1989-07-09','Knol','kjhdyush','knola@yahoo.com',7434356822,7),
('Jane', 'Lydia', '1992-10-21','Jlady','jhdjdidk','jlady@gmail.com',7876543987,8),
('Patricia', 'Alex', '1983-03-06','Patlex','hdvocim','patlex@yahoo.com',7435672891,2),
('Jim', 'Lyon', '1991-06-21','Jlyon','rgfydidk','jlyon@gmail.com',7876533452,5),
('Pat', 'Arch', '1983-11-16','Patarch','hdfgyu5cim','patarch@yahoo.com',7222472891,3)


INSERT INTO Items.Items
VALUES ('Beyond Believe',5, 3,'2008','','2022-07-08','Available'),
('Mother',1,1,'1998','5-86666-529-7','2022-03-08','Available'),
('A Boy at Sea Greener',4,1,'1998','1-99999-049-7','2022-03-08','Available'),
('Aerospace',2, 2,'1962', '2624-339X','2018-08-22','Available'),
('Reptiles',1, 3,'1984','','2022-06-08','Available'),
('The Game',5, 4,'2017','','2019-03-29','Loan'),
('Parenting',1,1,'1988','5-86666-529-7','2012-03-17','Loan'),
('Sail In Sea',4,1,'1998','1-99999-049-7','2015-05-08','Available'),
('Driving',2, 2,'1962', '2624-339X','2008-12-02','Loan'),
('Reptiles Life Cycle',1, 3,'1984','','2022-06-08','Available'),
('The Realtor',5, 3,'2020','','2022-03-19','Loan')


INSERT INTO Items.ItemType
VALUES ('Book'), ('Journal'), ('DVD'), ('Others')

INSERT INTO Author
VALUES ('Joan', 'Ash'), ('Wale', 'Ayan'), ('Chi', 'Agap'), ('Jim', 'Onye'), ('Amina', 'Awal'), ('Bola', 'Ade'), ('Latifah', 'Ajao'), 
('Tolani', 'Kay')


INSERT INTO Loans.Loans
VALUES   (4,6,'2023-04-05', '2023-04-14','2023-04-18',''),
(4,7,'2023-02-10', '2023-02-20','2023-02-20',0),
(5,9,'2022-11-04', '2022-11-14','2022-11-11',0),
(1,6,'2023-01-01', '2023-01-11','2023-01-10',0),
(6,2,'2023-02-1', '2023-02-10','2023-02-20',1),
(3,8,'2022-11-04', '2022-11-14','2022-11-19',0.5),
(1,3,'2023-01-01', '2023-01-11','2023-01-18',0.7),
(3,6,'2023-04-10', '2024-04-20','',''),
(5,7,'2023-04-9', '2023-02-19','','')


INSERT INTO Transactions.Fine
VALUES (6, 1, 0.5, 0.5),  (1, 0.7, 0, 0.7),  (3, 0.5, 0, 0.5);


INSERT INTO Transactions.Payment
VALUES (6, '2023-04-05', '11:23:44', 0.5,'Card'), (1,'2023-04-12', '10:04:22',27,'Cash'), (3,'2023-04-8', '18:04:52',48,'Card');




---(Question 7) Some necessary database objects created for effective functionality

--- Creating Triggers

--Trigger to archive exited members
DROP TRIGGER IF EXISTS members.MemberExitArchive;
GO

CREATE TRIGGER MemberExitArchive ON members.Members
AFTER DELETE
AS BEGIN
	SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
	INSERT INTO members.MemberExit
	(MemberId, FirstName, LastName,DateOfBirth , UserName, Password,
	 Email, Telephone,AddressID, EndDate)
	SELECT
	d.MemberId, d.FirstName, d.LastName, d.DateOfBirth, d.UserName, 
	d.PasswordHash, d.Email, d.Telephone ,d.AddressId, GETDATE()
	FROM deleted d
End;

---Testing the members.MemberExitArchive Trigger
DELETE FROM Members.Members WHERE MemberId = 8;

---To see all Exited Members
Select * From Members.MemberExit



---Trigger to archive removed items

DROP TRIGGER IF EXISTS items.RemovedItemArchive;
GO

CREATE TRIGGER items.RemovedItemArchive ON items.Items
AFTER DELETE
AS BEGIN
	SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
	INSERT INTO items.LostRemoved
	(ItemId, Title, AuthorId, TypeId, ItemISBN, DateIdentified)
	SELECT
	d.Id, d.Title, d.AuthorId, d.TypeId, d.ISBN, GETDATE()
	FROM deleted d
End;


---Testing the items.RemovedItemArchive Trigger
DELETE FROM Items.Items WHERE id = 13;

---To see all RemovedItemArchive
Select * From Items.LostRemoved l Join Items.ItemType t On l.TypeId = t.Id Join Items.Author a On l.AuthorId = a.Id

select * from items.Items

--Trigger to calculate overdue fine

DROP TRIGGER IF EXISTS loans.CalculateItemFine;
GO

CREATE TRIGGER CalculateItemFine
ON loans.Loans
AFTER UPDATE, INSERT
AS
BEGIN
    SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
    UPDATE loans.Loans
    SET OverDueFee = CASE WHEN DATEDIFF(day, LoanDue, LoanEnd) > 0 THEN DATEDIFF(day, LoanDue, LoanEnd) * 10 ELSE 0 END
    WHERE LoanDue IS NOT NULL AND LoanEnd IS NOT NULL AND LoanEnd > LoanStart
END

--To view Loans table and their overdue fine
select * from loans.Loans l Join Members.Members m on l.MemberId = m.MemberId Join Items.Items i on l.ItemId = i.Id



--Trigger to calculate total fine

DROP TRIGGER IF EXISTS loans.CalculateTotalFine;
GO

CREATE TRIGGER CalculateTotalFine
ON loans.Loans
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
    IF UPDATE(LoanEnd)
    BEGIN
        UPDATE transactions.Fine
        SET TotalFine = (
            SELECT SUM(OverDueFee) AS total_fine
            FROM Loans l
            WHERE l.MemberId = fine.MemberId
              AND l.LoanEnd < GETDATE()
			  );
    END
END;

--To view Fine table and the members
select * from transactions.Fine f Join Members.Members m on f.MemberId = m.MemberId


--Trigger to CalculateTotalPayment

DROP TRIGGER IF EXISTS transactions.CalculateTotalPayment;
GO

CREATE TRIGGER CalculateTotalPayment
ON transactions.Payment
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
    IF UPDATE(AmountPaid)
    BEGIN
        UPDATE transactions.Fine
        SET AmountPaid = (
            SELECT SUM(AmountPaid) AS total_payment
            FROM transactions.Payment p
            WHERE p.MemberId = fine.MemberId );
    END
END;

--To view Payment table and their overdue fine
select * from transactions.Fine f Join Members.Members m on f.MemberId = m.MemberId
select * from transactions.Payment p Join Members.Members m on p.MemberId = m.MemberId


--Trigger to CalculateOutstandingDebt
DROP TRIGGER IF EXISTS transactions.CalculateOutstandingDebt;
GO

CREATE TRIGGER CalculateOutstandingDebt
ON transactions.Payment
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
    IF UPDATE(AmountPaid)
    BEGIN
        UPDATE transactions.Fine
        SET OutstandingDebt = (
            TotalFine - p.AmountPaid) 
            FROM transactions.Payment p
            WHERE p.MemberId = fine.MemberId;
    END
END;


--To view Payment table and their overdue fine
select * from transactions.Fine f Join Members.Members m on f.MemberId = m.MemberId


--View to BooksByAuthor
Drop view BooksByAuthor

CREATE VIEW BooksByAuthor
AS
SELECT 
    a.Id, a.AuthorFirstName, a.AuthorLastName,
    (SELECT COUNT(*) FROM Items.items i WHERE I.AuthorId = A.Id) AS BookCount
FROM 
    Items.Author a
	
---Testing BooksByAuthor View
SELECT * FROM BooksByAuthor



----To Create maintenance plan for database

	SP_CONFIGURE 'SHOW ADVANCE',1
GO
RECONFIGURE WITH OVERRIDE
GO
SP_CONFIGURE 'AGENT XPs',1
GO
RECONFIGURE WITH OVERRIDE
GO






--- To create schemas to suit different departments

CREATE SCHEMA Items;
GO

ALTER SCHEMA  Items TRANSFER dbo.Items
ALTER SCHEMA  Items TRANSFER dbo.Author
ALTER SCHEMA  Items TRANSFER dbo.ItemType
ALTER SCHEMA  Items TRANSFER dbo.LostRemoved

CREATE SCHEMA Members;
GO

ALTER SCHEMA  Members TRANSFER dbo.Members
ALTER SCHEMA  Members TRANSFER dbo.Address
ALTER SCHEMA  Members TRANSFER dbo.MemberExit

CREATE SCHEMA Loans;
GO

ALTER SCHEMA  Loans TRANSFER dbo.Loans


CREATE SCHEMA Transactions;
GO

ALTER SCHEMA  Transactions TRANSFER dbo.fine
ALTER SCHEMA  Transactions TRANSFER dbo.Payment


---Creating different department

CREATE ROLE Admin;
CREATE ROLE Accountant;
CREATE ROLE Attendant;



--- To different database access to different departments

GRANT SELECT, UPDATE, INSERT ON SCHEMA :: Members TO Admin
GRANT SELECT, UPDATE, INSERT ON SCHEMA :: items TO Admin
GRANT SELECT, UPDATE, INSERT ON SCHEMA :: Loans TO Admin
GRANT SELECT, UPDATE, INSERT ON SCHEMA :: Transactions TO Admin
GRANT SELECT ON SCHEMA :: Members TO Attendant
GRANT SELECT ON SCHEMA :: Items TO Attendant
GRANT SELECT ON SCHEMA ::  Loans TO Accountant
GRANT SELECT ON SCHEMA ::  Transactions TO Accountant
GRANT SELECT ON SCHEMA ::  Members TO Accountant




--- To create security access to different client dedartment as database user

CREATE LOGIN OLAMILEKAN
WITH PASSWORD = 'advancedatabase2023!';

CREATE LOGIN ADMIN
WITH PASSWORD = 'advancedatabase2023!';

CREATE LOGIN ACCOUNTANT
WITH PASSWORD = 'accountant2023!';

CREATE LOGIN ATTENDANT
WITH PASSWORD = 'attendant2023!';




RESTORE VERIFYONLY
FROM DISK =
'C:\Task1 BC\Full Backup\AdbAssessment2023.bak'
WITH CHECKSUM;