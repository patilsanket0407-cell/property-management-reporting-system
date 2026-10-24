/* File 5: Unit tests with tSQLt (free framework: https://tsqlt.org)
   Setup: download tSQLt, run its tSQLt.class.sql once on PropertyMgmt, then run this file.
   Run all tests:  EXEC tSQLt.RunAll;  */
USE PropertyMgmt;
GO
EXEC tSQLt.NewTestClass 'ReportTests';
GO

CREATE OR ALTER PROCEDURE ReportTests.[test occupancy percent is 50 when 1 of 2 units is leased]
AS
BEGIN
    EXEC tSQLt.FakeTable 'dbo.Property';
    EXEC tSQLt.FakeTable 'dbo.Unit';
    EXEC tSQLt.FakeTable 'dbo.Lease';

    INSERT dbo.Property (PropertyID, Name) VALUES (1, 'Test Tower');
    INSERT dbo.Unit (UnitID, PropertyID) VALUES (1, 1), (2, 1);
    INSERT dbo.Lease (LeaseID, UnitID, Status) VALUES (1, 1, 'Active');

    CREATE TABLE #Actual (Property NVARCHAR(100), TotalUnits INT, OccupiedUnits INT, VacantUnits INT, OccupancyPercent DECIMAL(5,1));
    INSERT #Actual EXEC dbo.usp_Occupancy;

    SELECT 'Test Tower' AS Property, 2 AS TotalUnits, 1 AS OccupiedUnits, 1 AS VacantUnits, CAST(50.0 AS DECIMAL(5,1)) AS OccupancyPercent
    INTO #Expected;

    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END
GO

CREATE OR ALTER PROCEDURE ReportTests.[test overdue aging puts unpaid rent in the 31-60 bucket]
AS
BEGIN
    EXEC tSQLt.FakeTable 'dbo.Property';
    EXEC tSQLt.FakeTable 'dbo.Unit';
    EXEC tSQLt.FakeTable 'dbo.Tenant';
    EXEC tSQLt.FakeTable 'dbo.Lease';
    EXEC tSQLt.FakeTable 'dbo.RentCharge';
    EXEC tSQLt.FakeTable 'dbo.Payment';

    INSERT dbo.Property (PropertyID, Name) VALUES (1, 'Test Tower');
    INSERT dbo.Unit (UnitID, PropertyID, UnitNumber) VALUES (1, 1, 'A-1');
    INSERT dbo.Tenant (TenantID, FullName) VALUES (1, 'Test Tenant');
    INSERT dbo.Lease (LeaseID, UnitID, TenantID) VALUES (1, 1, 1);
    INSERT dbo.RentCharge (ChargeID, LeaseID, DueDate, Amount) VALUES (1, 1, '2026-08-20', 10000);  -- 41 days before 30 Sep

    DECLARE @bucket DECIMAL(10,2);
    CREATE TABLE #Actual (Property NVARCHAR(100), UnitNumber NVARCHAR(10), Tenant NVARCHAR(100),
        D0_30 DECIMAL(10,2), D31_60 DECIMAL(10,2), D61_90 DECIMAL(10,2), D90Plus DECIMAL(10,2), TotalOverdue DECIMAL(10,2));
    INSERT #Actual EXEC dbo.usp_OverdueRentAging @AsOfDate = '2026-09-30';
    SELECT @bucket = D31_60 FROM #Actual;

    EXEC tSQLt.AssertEquals 10000, @bucket;
END
GO

CREATE OR ALTER PROCEDURE ReportTests.[test lease end date must be after start date]
AS
BEGIN
    EXEC tSQLt.ExpectException;      -- the CHECK constraint should reject bad dates
    INSERT dbo.Lease (UnitID, TenantID, StartDate, EndDate, MonthlyRent)
    VALUES (1, 1, '2026-06-01', '2026-01-01', 10000);
END
GO
-- EXEC tSQLt.RunAll;
