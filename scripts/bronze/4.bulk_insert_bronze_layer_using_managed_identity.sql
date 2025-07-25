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

-- Execute both procedures to complete bronze layer loading
EXECUTE bronze.config_external_data_source;
EXECUTE bronze.load_bronze;

-- ===============================================================
-- PROCEDURE 1: Configure External Data Source
-- ===============================================================
-- Purpose: Set up secure connection to Azure Blob Storage using Managed Identity
-- Frequency: Run once or when authentication needs to be refreshed
CREATE OR ALTER PROCEDURE bronze.config_external_data_source AS
    BEGIN
        DECLARE @start_time AS DATETIME, @end_time AS DATETIME;
        BEGIN TRY
            SET @start_time = GETDATE();

            -- Clean up existing resources to avoid conflicts
            PRINT ('-- Drop existing external data source if it exists');
            IF EXISTS (SELECT * FROM sys.external_data_sources WHERE name = 'AzureBlobStorageMI')
                DROP EXTERNAL DATA SOURCE AzureBlobStorageMI;

            PRINT ('-- Drop existing credential if it exists')
            IF EXISTS (SELECT * FROM sys.database_scoped_credentials WHERE name = 'ManagedIdentityCredential')
                DROP DATABASE SCOPED CREDENTIAL ManagedIdentityCredential;

            -- Create secure credential using SQL Server's managed identity
            PRINT ('-- Create Managed Identity credential (no secrets needed!)')
            CREATE DATABASE SCOPED CREDENTIAL ManagedIdentityCredential
            WITH IDENTITY = 'Managed Identity';

            -- Configure connection to Azure Blob Storage
            PRINT ('-- Create external data source')
            CREATE EXTERNAL DATA SOURCE AzureBlobStorageMI
            WITH (
                TYPE = BLOB_STORAGE,
                LOCATION = 'https://dwhproject.blob.core.windows.net/datasets',
                CREDENTIAL = ManagedIdentityCredential
            );

            -- Log execution time for monitoring
            SET @end_time = GETDATE();
            PRINT('>> Load Duration: ') + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + 'seconds';

        END TRY
        BEGIN CATCH
            -- Error handling and logging
            PRINT ('====================================================');
            PRINT ('ERROR OCCURRED');
            PRINT ('Error Message') + error_message();
            PRINT ('Error Number') + CAST (ERROR_NUMBER() AS NVARCHAR);
            PRINT ('Error State') + CAST (ERROR_STATE() AS NVARCHAR);
            PRINT ('====================================================');
        END CATCH
    END

-- ===============================================================
-- PROCEDURE 2: Load Bronze Layer Data
-- ===============================================================
-- Purpose: Import all source data files into bronze layer tables
-- Frequency: Daily/hourly data refresh (full reload)
-- Data Sources: CRM (customers, products, sales) + ERP (location, demographics, categories)
CREATE OR ALTER PROCEDURE bronze.load_bronze AS
    BEGIN
        DECLARE @start_time AS DATETIME, @end_time AS DATETIME, @batch_start_time AS DATETIME, @batch_end_time AS DATETIME;
        BEGIN TRY
            SET @batch_start_time = GETDATE();

            PRINT ('====================================================');
            PRINT ('Loading Bronze Layer');
            PRINT ('====================================================');

            -- ===============================================================
            -- CRM SYSTEM DATA LOADING
            -- ===============================================================
            PRINT ('----------------------------------------------------');
            PRINT ('Loading CRM Tables');
            PRINT ('----------------------------------------------------');

            -- Load Product Master Data
            SET @start_time = GETDATE();
            PRINT ('Truncating Table: bronze.crm_prd_info');
            TRUNCATE TABLE bronze.crm_prd_info;
            PRINT ('>> Inserting Data Into: bronze.crm_prd_info');
            BULK INSERT bronze.crm_prd_info
                FROM 'source_crm/prd_info.csv'
                WITH (
                    DATA_SOURCE = 'AzureBlobStorageMI',
                    FIRSTROW = 2,           -- Skip header row
                    FIELDTERMINATOR = ',',  -- CSV comma separator
                    ROWTERMINATOR = '\n',   -- Line break separator
                    TABLOCK                 -- Table lock for performance
                );
            SET @end_time = GETDATE();
            PRINT('>> Load Duration: ') + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + 'seconds';

            -- Load Customer Master Data
            SET @start_time = GETDATE();
            PRINT ('Truncating Table: bronze.crm_cust_info');
            TRUNCATE TABLE bronze.crm_cust_info;
            PRINT ('>> Inserting Data Into: bronze.crm_cust_info');
            BULK INSERT bronze.crm_cust_info
                FROM 'source_crm/cust_info.csv'
                WITH (
                    DATA_SOURCE = 'AzureBlobStorageMI',
                    FIRSTROW = 2,
                    FIELDTERMINATOR = ',',
                    ROWTERMINATOR = '\n',
                    TABLOCK
                );
            SET @end_time = GETDATE();
            PRINT('>> Load Duration: ') + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + 'seconds';

            -- Load Sales Transaction Data
            SET @start_time = GETDATE();
            PRINT ('Truncating Table: bronze.crm_sales_details');
            TRUNCATE TABLE bronze.crm_sales_details;
            PRINT ('>> Inserting Data Into: bronze.crm_sales_details');
            BULK INSERT bronze.crm_sales_details
                FROM 'source_crm/sales_details.csv'
                WITH (
                    DATA_SOURCE = 'AzureBlobStorageMI',
                    FIRSTROW = 2,
                    FIELDTERMINATOR = ',',
                    ROWTERMINATOR = '\n',
                    TABLOCK
                );
            SET @end_time = GETDATE();
            PRINT('>> Load Duration: ') + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + 'seconds';

            -- ===============================================================
            -- ERP SYSTEM DATA LOADING
            -- ===============================================================
            PRINT ('----------------------------------------------------');
            PRINT ('Loading ERP Tables');
            PRINT ('----------------------------------------------------');

            -- Load Customer Demographics
            SET @start_time = GETDATE();
            PRINT ('Truncating Table: bronze.erp_cust_az12');
            TRUNCATE TABLE bronze.erp_cust_az12;
            PRINT ('>> Inserting Data Into: bronze.erp_cust_az12');
            BULK INSERT bronze.erp_cust_az12
                FROM 'source_erp/CUST_AZ12.csv'
                WITH (
                    DATA_SOURCE = 'AzureBlobStorageMI',
                    FIRSTROW = 2,
                    FIELDTERMINATOR = ',',
                    ROWTERMINATOR = '\n',
                    TABLOCK
                );
            SET @end_time = GETDATE();
            PRINT('>> Load Duration: ') + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + 'seconds';

            -- Load Location Data
            SET @start_time = GETDATE();
            PRINT ('Truncating Table: bronze.erp_loc_a101');
            TRUNCATE TABLE bronze.erp_loc_a101;
            PRINT ('>> Inserting Data Into: bronze.erp_loc_a101');
            BULK INSERT bronze.erp_loc_a101
                FROM 'source_erp/LOC_A101.csv'
                WITH (
                    DATA_SOURCE = 'AzureBlobStorageMI',
                    FIRSTROW = 2,
                    FIELDTERMINATOR = ',',
                    ROWTERMINATOR = '\n',
                    TABLOCK
                );
            SET @end_time = GETDATE();
            PRINT('>> Load Duration: ') + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + 'seconds';

            -- Load Product Category Data
            SET @start_time = GETDATE();
            PRINT ('Truncating Table: bronze.erp_px_cat_g1v2');
            TRUNCATE TABLE bronze.erp_px_cat_g1v2;
            PRINT ('>> Inserting Data Into: bronze.erp_px_cat_g1v2');
            BULK INSERT bronze.erp_px_cat_g1v2
                FROM 'source_erp/PX_CAT_G1V2.csv'
                WITH (
                    DATA_SOURCE = 'AzureBlobStorageMI',
                    FIRSTROW = 2,
                    FIELDTERMINATOR = ',',
                    ROWTERMINATOR = '\n',
                    TABLOCK
                );
            SET @end_time = GETDATE();
            PRINT('>> Load Duration: ') + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + 'seconds';

            -- Log total batch execution time
            SET @batch_end_time = GETDATE();
            PRINT('>> Load Batch Duration: ') + CAST(DATEDIFF(second, @batch_start_time, @batch_end_time) AS NVARCHAR) + 'seconds';
            
            PRINT ('====================================================');
            PRINT ('Bronze Layer Loading Completed Successfully');
            PRINT ('====================================================');

        END TRY
        BEGIN CATCH
            -- Comprehensive error handling
            PRINT ('====================================================');
            PRINT ('ERROR OCCURRED DURING BRONZE LAYER LOADING');
            PRINT ('Error Message: ' + ERROR_MESSAGE());
            PRINT ('Error Number: ' + CAST (ERROR_NUMBER() AS NVARCHAR));
            PRINT ('Error State: ' + CAST (ERROR_STATE() AS NVARCHAR));
            PRINT ('====================================================');
        END CATCH
    END

-- ===============================================================
-- USAGE NOTES
-- ===============================================================
-- Execute both procedures in sequence:
-- 1. EXECUTE bronze.config_external_data_source; (setup authentication)
-- 2. EXECUTE bronze.load_bronze; (load all data)
--
-- Data loaded from Azure Blob Storage:
-- CRM: source_crm/*.csv (customers, products, sales)
-- ERP: source_erp/*.csv (location, demographics, categories)
--
-- Performance monitoring: Each table load duration is logged
-- Error handling: Detailed error information captured for troubleshooting
-- ===============================================================

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
