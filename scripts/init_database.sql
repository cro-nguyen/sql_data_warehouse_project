/*
 ===============================================================
 Create Database and Schemas - SQL Server Version
 ===============================================================
 Script Purpose: Initialize DataWarehouse with medallion architecture
 */

-- Create database (SQL Server syntax)
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'DataWarehouse')
BEGIN
    CREATE DATABASE DataWarehouse;
END

-- Switch to the DataWarehouse database
USE DataWarehouse;
GO

-- Create schemas
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'bronze')
BEGIN
    EXEC('CREATE SCHEMA bronze');
END

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'silver')
BEGIN
    EXEC('CREATE SCHEMA silver');
END

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'gold')
BEGIN
    EXEC('CREATE SCHEMA gold');
END
