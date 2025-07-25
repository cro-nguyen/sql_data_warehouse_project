-- ===============================================================
-- BULK INSERT using Managed Identity Authentication
-- ===============================================================
-- Purpose: Import data from Azure Blob Storage using the most secure authentication method
-- Authentication: System Assigned Managed Identity (no secrets, no expiration)
-- Target: bronze.crm_prd_info table
-- Source: Azure Blob Storage (dwhproject/datasets/source_crm/prd_info.csv)
-- Author: Hung Nguyen
-- Date: July 24, 2025
-- ===============================================================

-- ===============================================================
-- PREREQUISITE: MANAGED IDENTITY SETUP STEPS
-- ===============================================================
-- Complete these steps in Azure Portal BEFORE running this script:
--
-- STEP 1: Enable SQL Server Managed Identity
-- 1. Azure Portal → SQL servers → [your-sql-server-name]
-- 2. Security → Identity → System assigned tab
-- 3. Status → Turn ON → Save
--
-- STEP 2: Grant Storage Account Access
-- 1. Azure Portal → Storage accounts → [your-storage-account-name]
-- 2. Access Control (IAM) → Add role assignment
-- 3. Role: "Storage Blob Data Reader"
-- 4. Assign access to: "Managed identity" → Select members
-- 5. Select: SQL server → [your-sql-server-name] → Select
-- 6. Review + assign
--
-- STEP 3: Wait for Permissions (1-2 minutes)
-- Allow time for role assignments to propagate across Azure services
-- ===============================================================

-- Step 1: Clean up existing external data source
-- External data source must be dropped before its credential
IF EXISTS (SELECT * FROM sys.external_data_sources WHERE name = 'AzureBlobStorageMI')
    DROP EXTERNAL DATA SOURCE AzureBlobStorageMI;

-- Step 2: Clean up existing credential
-- Remove any existing managed identity credential to avoid conflicts
IF EXISTS (SELECT * FROM sys.database_scoped_credentials WHERE name = 'ManagedIdentityCredential')
    DROP DATABASE SCOPED CREDENTIAL ManagedIdentityCredential;

-- Step 3: Create Managed Identity credential
-- Uses SQL Server's system assigned identity for authentication
-- No secrets, passwords, or tokens required - Azure handles authentication automatically
CREATE DATABASE SCOPED CREDENTIAL ManagedIdentityCredential
WITH IDENTITY = 'Managed Identity';

-- Step 4: Create external data source
-- Points to Azure Blob Storage container using managed identity authentication
CREATE EXTERNAL DATA SOURCE AzureBlobStorageMI
WITH (
    TYPE = BLOB_STORAGE,                                                -- Azure Blob Storage type
    LOCATION = 'https://dwhproject.blob.core.windows.net/datasets',    -- Storage account and container
    CREDENTIAL = ManagedIdentityCredential                              -- Use managed identity for authentication
);

-- Step 5: Clear existing data
-- Remove all existing records to ensure clean import
TRUNCATE TABLE bronze.crm_prd_info;

-- Step 6: Import data from CSV file
-- Load product information from Azure Blob Storage into bronze layer table
BULK INSERT bronze.crm_prd_info
    FROM 'source_crm/prd_info.csv'                 -- File path within the datasets container
    WITH (
        DATA_SOURCE = 'AzureBlobStorageMI',         -- Use managed identity data source
        FIRSTROW = 2,                               -- Skip header row (row 1 contains column names)
        FIELDTERMINATOR = ',',                      -- CSV comma separator
        ROWTERMINATOR = '\n',                       -- Line break separator
        TABLOCK                                     -- Table lock for better import performance
    );

-- ===============================================================
-- VERIFICATION QUERIES
-- ===============================================================
-- Check import results
SELECT COUNT(*) AS TotalRecordsImported FROM bronze.crm_prd_info;
SELECT TOP 10 * FROM bronze.crm_prd_info ORDER BY prd_id;

-- ===============================================================
-- TROUBLESHOOTING GUIDE
-- ===============================================================
-- Common errors and solutions:
--
-- Error: "Cannot find the CREDENTIAL 'ManagedIdentityCredential'"
-- Solution: Ensure Database Master Key exists first
--
-- Error: "Access denied to storage account"
-- Solution: 
-- 1. Verify SQL Server has system assigned identity enabled
-- 2. Check SQL Server identity has "Storage Blob Data Reader" role on storage account
-- 3. Wait 10 minutes for permissions to propagate
--
-- Error: "Cannot bulk load. The file does not exist"
-- Solution: Verify file exists at: datasets/source_crm/prd_info.csv in storage account
--
-- Error: "Authentication failed"
-- Solution: Ensure managed identity setup steps were completed correctly
-- ===============================================================

-- ===============================================================
-- ADVANTAGES OF MANAGED IDENTITY
-- ===============================================================
-- ✅ No secrets to manage or store
-- ✅ No expiration dates or token rotation
-- ✅ Native Azure security integration
-- ✅ Full audit trail through Azure AD
-- ✅ Microsoft recommended best practice
-- ✅ Zero maintenance overhead
-- ===============================================================
