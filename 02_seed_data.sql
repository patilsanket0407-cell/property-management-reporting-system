/* File 2: Sample data (small but enough to test every report) */
USE PropertyMgmt;
GO

INSERT dbo.Property (Name, City, Address) VALUES
 ('Green Park Residency', 'Nagpur',  '12 Ring Road'),
 ('Lake View Towers',     'Pune',    '45 Baner Road'),
 ('Sunrise Heights',      'Mumbai',  '8 Andheri East');

-- 5 units per property (15 total)
;WITH n AS (SELECT 1 AS i UNION ALL SELECT i+1 FROM n WHERE i < 5)
INSERT dbo.Unit (PropertyID, UnitNumber, Bedrooms, MarketRent)
SELECT p.PropertyID, CONCAT('A-', n.i), 1 + (n.i % 3), 9000 + (n.i * 1500) + (p.PropertyID * 500)
FROM dbo.Property p CROSS JOIN n;

INSERT dbo.Tenant (FullName, Email, Phone) VALUES
 ('Amit Sharma','amit@example.com','9000000001'), ('Neha Joshi','neha@example.com','9000000002'),
 ('Rahul Verma','rahul@example.com','9000000003'), ('Priya Nair','priya@example.com','9000000004'),
 ('Karan Mehta','karan@example.com','9000000005'), ('Sneha Kulkarni','sneha@example.com','9000000006'),
 ('Vikas Patil','vikas@example.com','9000000007'), ('Anita Desai','anita@example.com','9000000008'),
 ('Rohan Gupta','rohan@example.com','9000000009'), ('Divya Rao','divya@example.com','9000000010');

-- 10 tenants -> units 1..10 (units 11..15 stay vacant for the occupancy report)
INSERT dbo.Lease (UnitID, TenantID, StartDate, EndDate, MonthlyRent)
SELECT t.TenantID, t.TenantID, '2026-01-01', '2026-12-31',
       (SELECT MarketRent FROM dbo.Unit u WHERE u.UnitID = t.TenantID)
FROM dbo.Tenant t;

-- Monthly charges Jan..Oct 2026 for every lease
;WITH m AS (SELECT 0 AS k UNION ALL SELECT k+1 FROM m WHERE k < 9)
INSERT dbo.RentCharge (LeaseID, DueDate, Amount)
SELECT l.LeaseID, DATEADD(MONTH, m.k, '2026-01-05'), l.MonthlyRent
FROM dbo.Lease l CROSS JOIN m;

-- Pay most charges on time; leave some unpaid or partly paid so aging has data
INSERT dbo.Payment (ChargeID, PaidDate, AmountPaid)
SELECT c.ChargeID, DATEADD(DAY, (c.ChargeID % 4), c.DueDate), c.Amount
FROM dbo.RentCharge c
WHERE c.ChargeID % 7 <> 0              -- every 7th charge is unpaid
  AND c.ChargeID % 11 <> 0;            -- every 11th is only half paid below

INSERT dbo.Payment (ChargeID, PaidDate, AmountPaid)
SELECT c.ChargeID, DATEADD(DAY, 3, c.DueDate), c.Amount / 2
FROM dbo.RentCharge c
WHERE c.ChargeID % 11 = 0 AND c.ChargeID % 7 <> 0;

INSERT dbo.MaintenanceRequest (UnitID, Description, Status, CreatedDate) VALUES
 (1,'Leaking tap','Closed','2026-03-02'), (2,'AC not cooling','Open','2026-09-18'),
 (4,'Broken window latch','InProgress','2026-10-01'), (7,'Power socket fault','Open','2026-10-10');
GO
