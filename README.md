# Property Management Reporting System (SQL Server)

A small database + reports project modelled on the kind of data property management software handles
(properties, units, tenants, leases, rent charges, payments, maintenance).

## What you need (all free)
- SQL Server 2022 **Express** (or Developer edition)
- SQL Server Management Studio (SSMS)
- tSQLt framework (tsqlt.org) for unit tests
- Microsoft **Report Builder** (free) or Visual Studio with SSRS extension, for the reports

## Run order
1. `01_schema.sql`        - creates the database and 7 tables with keys and checks
2. `02_seed_data.sql`     - loads 3 properties, 15 units, 10 tenants, leases, charges, payments
3. `03_reports_procedures.sql` - 4 stored procedures: rent roll, overdue aging, occupancy, monthly revenue
4. `04_indexes_performance.sql` - measure, add indexes, measure again (write down the numbers)
5. `05_unit_tests_tSQLt.sql` - install tSQLt first, then run `EXEC tSQLt.RunAll;`

## SSRS reports (do this yourself in Report Builder, about 1-2 hours)
1. Open Report Builder > New Report > connect to `PropertyMgmt`
2. Dataset type "Stored Procedure": pick `usp_RentRoll`, `usp_OverdueRentAging`, `usp_Occupancy`
3. Add a parameter dropdown for Property (and an As-of Date for aging)
4. Table layout, group by Property, add totals
5. Run > Export to PDF and Excel; keep screenshots for your portfolio / GitHub

## Be ready to explain (interview)
- Why LEFT JOIN for vacant units? Why a CTE for balance? What does the window function do?
- What did the execution plan show before/after the index (scan vs seek, logical reads)?
- Why FakeTable in tSQLt?

## Put it on GitHub
Create a repo, add these files plus screenshots of the reports and execution plans.
Then your resume bullets are provable.
