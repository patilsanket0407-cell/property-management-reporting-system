/* File 4: Performance. Measure BEFORE and AFTER, and note the numbers for your resume/interview.
   Tip: in SSMS press Ctrl+M (Include Actual Execution Plan) and run the SET commands below. */
USE PropertyMgmt;
GO
SET STATISTICS IO ON;
SET STATISTICS TIME ON;

-- STEP 1: run this BEFORE creating indexes. Note logical reads, CPU time, and the plan (table scans?)
EXEC dbo.usp_OverdueRentAging;
EXEC dbo.usp_MonthlyRevenue @Year = 2026;
GO

-- STEP 2: add indexes on the columns used in JOIN / WHERE / GROUP BY
CREATE NONCLUSTERED INDEX IX_RentCharge_Lease_Due   ON dbo.RentCharge (LeaseID, DueDate) INCLUDE (Amount);
CREATE NONCLUSTERED INDEX IX_Payment_Charge         ON dbo.Payment (ChargeID) INCLUDE (AmountPaid, PaidDate);
CREATE NONCLUSTERED INDEX IX_Payment_PaidDate       ON dbo.Payment (PaidDate) INCLUDE (AmountPaid);
CREATE NONCLUSTERED INDEX IX_Lease_Unit_Status      ON dbo.Lease (UnitID, Status) INCLUDE (TenantID, MonthlyRent);
GO

-- STEP 3: run the same two procedures again and compare reads, time, and plan (scan -> seek)
EXEC dbo.usp_OverdueRentAging;
EXEC dbo.usp_MonthlyRevenue @Year = 2026;
GO

/* NOTE: with only ~150 rows the difference is tiny. To see a real change, load more data
   (e.g. repeat the seed for 50,000+ charges/payments) and then compare. Write down what you see. */
