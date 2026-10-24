/* ============================================================
   Property Management Reporting System  -  SQL Server (T-SQL)
   File 1: Create database and tables
   Run in SSMS (SQL Server Express or Developer edition is free)
   ============================================================ */
IF DB_ID('PropertyMgmt') IS NULL CREATE DATABASE PropertyMgmt;
GO
USE PropertyMgmt;
GO

CREATE TABLE dbo.Property (
    PropertyID   INT IDENTITY(1,1) PRIMARY KEY,
    Name         NVARCHAR(100) NOT NULL,
    City         NVARCHAR(60)  NOT NULL,
    Address      NVARCHAR(200) NOT NULL
);

CREATE TABLE dbo.Unit (
    UnitID       INT IDENTITY(1,1) PRIMARY KEY,
    PropertyID   INT NOT NULL REFERENCES dbo.Property(PropertyID),
    UnitNumber   NVARCHAR(10) NOT NULL,
    Bedrooms     TINYINT NOT NULL,
    MarketRent   DECIMAL(10,2) NOT NULL CHECK (MarketRent > 0),
    CONSTRAINT UQ_Unit UNIQUE (PropertyID, UnitNumber)
);

CREATE TABLE dbo.Tenant (
    TenantID     INT IDENTITY(1,1) PRIMARY KEY,
    FullName     NVARCHAR(100) NOT NULL,
    Email        NVARCHAR(120) NULL,
    Phone        NVARCHAR(20)  NULL
);

CREATE TABLE dbo.Lease (
    LeaseID      INT IDENTITY(1,1) PRIMARY KEY,
    UnitID       INT NOT NULL REFERENCES dbo.Unit(UnitID),
    TenantID     INT NOT NULL REFERENCES dbo.Tenant(TenantID),
    StartDate    DATE NOT NULL,
    EndDate      DATE NOT NULL,
    MonthlyRent  DECIMAL(10,2) NOT NULL CHECK (MonthlyRent > 0),
    Status       VARCHAR(10) NOT NULL DEFAULT 'Active'
                 CHECK (Status IN ('Active','Ended')),
    CONSTRAINT CK_LeaseDates CHECK (EndDate > StartDate)
);

CREATE TABLE dbo.RentCharge (          -- what the tenant owes each month
    ChargeID     INT IDENTITY(1,1) PRIMARY KEY,
    LeaseID      INT NOT NULL REFERENCES dbo.Lease(LeaseID),
    DueDate      DATE NOT NULL,
    Amount       DECIMAL(10,2) NOT NULL CHECK (Amount > 0)
);

CREATE TABLE dbo.Payment (             -- what the tenant actually paid
    PaymentID    INT IDENTITY(1,1) PRIMARY KEY,
    ChargeID     INT NOT NULL REFERENCES dbo.RentCharge(ChargeID),
    PaidDate     DATE NOT NULL,
    AmountPaid   DECIMAL(10,2) NOT NULL CHECK (AmountPaid > 0)
);

CREATE TABLE dbo.MaintenanceRequest (
    RequestID    INT IDENTITY(1,1) PRIMARY KEY,
    UnitID       INT NOT NULL REFERENCES dbo.Unit(UnitID),
    Description  NVARCHAR(300) NOT NULL,
    Status       VARCHAR(12) NOT NULL DEFAULT 'Open'
                 CHECK (Status IN ('Open','InProgress','Closed')),
    CreatedDate  DATE NOT NULL
);
GO
