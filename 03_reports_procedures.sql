/* File 3: Stored procedures that power the reports (also used by SSRS) */
USE PropertyMgmt;
GO

/* 1) RENT ROLL: every unit with its tenant, rent and lease status */
CREATE OR ALTER PROCEDURE dbo.usp_RentRoll
    @PropertyID INT = NULL            -- NULL = all properties
AS
BEGIN
    SET NOCOUNT ON;
    SELECT p.Name AS Property, u.UnitNumber, u.Bedrooms,
           t.FullName AS Tenant, l.MonthlyRent, u.MarketRent,
           l.StartDate, l.EndDate,
           CASE WHEN l.LeaseID IS NULL THEN 'Vacant' ELSE 'Occupied' END AS UnitStatus
    FROM dbo.Unit u
    JOIN dbo.Property p        ON p.PropertyID = u.PropertyID
    LEFT JOIN dbo.Lease l      ON l.UnitID = u.UnitID AND l.Status = 'Active'
    LEFT JOIN dbo.Tenant t     ON t.TenantID = l.TenantID
    WHERE (@PropertyID IS NULL OR p.PropertyID = @PropertyID)
    ORDER BY p.Name, u.UnitNumber;
END
GO

/* 2) OVERDUE RENT AGING: unpaid balance grouped by how late it is */
CREATE OR ALTER PROCEDURE dbo.usp_OverdueRentAging
    @AsOfDate DATE = NULL,
    @PropertyID INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET @AsOfDate = ISNULL(@AsOfDate, CAST(GETDATE() AS DATE));

    ;WITH Balance AS (
        SELECT c.ChargeID, c.LeaseID, c.DueDate,
               c.Amount - ISNULL(SUM(pay.AmountPaid), 0) AS Outstanding
        FROM dbo.RentCharge c
        LEFT JOIN dbo.Payment pay ON pay.ChargeID = c.ChargeID
        WHERE c.DueDate <= @AsOfDate
        GROUP BY c.ChargeID, c.LeaseID, c.DueDate, c.Amount
    )
    SELECT p.Name AS Property, u.UnitNumber, t.FullName AS Tenant,
           SUM(CASE WHEN DATEDIFF(DAY, b.DueDate, @AsOfDate) BETWEEN 0  AND 30 THEN b.Outstanding ELSE 0 END) AS [0-30 Days],
           SUM(CASE WHEN DATEDIFF(DAY, b.DueDate, @AsOfDate) BETWEEN 31 AND 60 THEN b.Outstanding ELSE 0 END) AS [31-60 Days],
           SUM(CASE WHEN DATEDIFF(DAY, b.DueDate, @AsOfDate) BETWEEN 61 AND 90 THEN b.Outstanding ELSE 0 END) AS [61-90 Days],
           SUM(CASE WHEN DATEDIFF(DAY, b.DueDate, @AsOfDate) > 90 THEN b.Outstanding ELSE 0 END)             AS [90+ Days],
           SUM(b.Outstanding) AS TotalOverdue
    FROM Balance b
    JOIN dbo.Lease l    ON l.LeaseID = b.LeaseID
    JOIN dbo.Unit u     ON u.UnitID = l.UnitID
    JOIN dbo.Property p ON p.PropertyID = u.PropertyID
    JOIN dbo.Tenant t   ON t.TenantID = l.TenantID
    WHERE b.Outstanding > 0
      AND (@PropertyID IS NULL OR p.PropertyID = @PropertyID)
    GROUP BY p.Name, u.UnitNumber, t.FullName
    ORDER BY TotalOverdue DESC;
END
GO

/* 3) OCCUPANCY: occupied vs vacant units per property */
CREATE OR ALTER PROCEDURE dbo.usp_Occupancy
AS
BEGIN
    SET NOCOUNT ON;
    SELECT p.Name AS Property,
           COUNT(u.UnitID) AS TotalUnits,
           COUNT(l.LeaseID) AS OccupiedUnits,
           COUNT(u.UnitID) - COUNT(l.LeaseID) AS VacantUnits,
           CAST(100.0 * COUNT(l.LeaseID) / NULLIF(COUNT(u.UnitID), 0) AS DECIMAL(5,1)) AS OccupancyPercent
    FROM dbo.Property p
    JOIN dbo.Unit u        ON u.PropertyID = p.PropertyID
    LEFT JOIN dbo.Lease l  ON l.UnitID = u.UnitID AND l.Status = 'Active'
    GROUP BY p.Name
    ORDER BY p.Name;
END
GO

/* 4) MONTHLY REVENUE: collected rent per month with running total (window function) */
CREATE OR ALTER PROCEDURE dbo.usp_MonthlyRevenue
    @Year INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET @Year = ISNULL(@Year, YEAR(GETDATE()));
    SELECT DATEFROMPARTS(YEAR(pay.PaidDate), MONTH(pay.PaidDate), 1) AS MonthStart,
           SUM(pay.AmountPaid) AS Collected,
           SUM(SUM(pay.AmountPaid)) OVER (ORDER BY DATEFROMPARTS(YEAR(pay.PaidDate), MONTH(pay.PaidDate), 1)) AS RunningTotal
    FROM dbo.Payment pay
    WHERE YEAR(pay.PaidDate) = @Year
    GROUP BY DATEFROMPARTS(YEAR(pay.PaidDate), MONTH(pay.PaidDate), 1)
    ORDER BY MonthStart;
END
GO
