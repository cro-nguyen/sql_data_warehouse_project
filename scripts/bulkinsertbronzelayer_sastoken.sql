-- ===============================================================
-- BULK INSERT from Azure Blob Storage using SAS Token
-- ===============================================================
-- Purpose: Import customer data from CSV file stored in Azure Blob Storage
--          into the bronze.crm_cust_info table in our data warehouse
-- Author: [Your Name]
-- Date: July 24, 2025
-- Data Source: Azure Blob Storage (dwhproject/datasets/source_crm/cust_info.csv)
-- ===============================================================

-- ===============================================================
-- HOW TO GENERATE SAS TOKEN (Shared Access Signature)
-- ===============================================================
-- 1. Go to Azure Portal (portal.azure.com)
-- 2. Navigate to Storage accounts → [your-storage-account-name]
-- 3. In the left menu, go to Security + networking → Shared access signature
-- 4. Configure the following settings:
--    ✅ Allowed services: Blob (uncheck Table, Queue, File)
--    ✅ Allowed resource types: Container ✅ + Object ✅
--    ✅ Allowed permissions: Read ✅ + List ✅ (minimum required)
--    📅 Start time: Current date/time (or leave default)
--    📅 Expiry time: Set future date (e.g., 1 year from now)
--    🔒 Allowed protocols: HTTPS only (recommended)
--    🔑 Signing key: key1 (default)
-- 5. Click "Generate SAS and connection string" button
-- 6. Copy the "SAS token" value (starts with ?sv=...)
-- 7. IMPORTANT: Remove the leading "?" when using in SQL credential
--    Example: If token is "?sv=2024...", use "sv=2024..." in SECRET
-- ===============================================================

-- STEP 1: Clean up existing database scoped credential
-- Remove any existing SAS token credential to avoid conflicts
IF EXISTS (SELECT * FROM sys.database_scoped_credentials WHERE name = 'SASTokenCredential')
    DROP DATABASE SCOPED CREDENTIAL SASTokenCredential;

-- STEP 2: Create database scoped credential with SAS token
-- This credential stores the Shared Access Signature (SAS) token that allows
-- SQL Database to authenticate and access the Azure Storage Account
CREATE DATABASE SCOPED CREDENTIAL SASTokenCredential
    WITH IDENTITY = 'SHARED ACCESS SIGNATURE',  -- Identity type for SAS token authentication
    SECRET = 'sv=2024-11-04&ss=b&srt=co&sp=rlx&se=2025-08-16T17:34:21Z&st=2025-07-24T09:19:21Z&spr=https&sig=YltYuh%2BfO8ivK4yHgIp99nWM4AChAXKmrYEk3tFdLio%3D';
    -- SAS token components breakdown:
    -- sv = Storage service version (2024-11-04)
    -- ss = Services (b = blob service only)
    -- srt = Resource types (co = container and object)
    -- sp = Permissions (rlx = read, list, and execute)
    -- se = Expiry time (2025-08-16T17:34:21Z)
    -- st = Start time (2025-07-24T09:19:21Z)
    -- spr = Protocol (https only)
    -- sig = Signature for authentication

-- STEP 3: Clean up existing external data source
-- Remove any existing external data source to avoid naming conflicts
IF EXISTS (SELECT * FROM sys.external_data_sources WHERE name = 'AzureBlobStorageSAS')
    DROP EXTERNAL DATA SOURCE AzureBlobStorageSAS;

-- STEP 4: Create external data source pointing to Azure Blob Storage
-- This creates a reference to the Azure Storage container where our data files are stored
CREATE EXTERNAL DATA SOURCE AzureBlobStorageSAS
    WITH (
        TYPE = BLOB_STORAGE,                                                    -- Specify this is Azure Blob Storage
        LOCATION = 'https://dwhproject.blob.core.windows.net/datasets',        -- Storage account URL and container name
        CREDENTIAL = SASTokenCredential                                         -- Use the SAS token credential created above
    );
    -- Data source points to:
    -- Storage Account: dwhproject
    -- Container: datasets
    -- Authentication: SAS token stored in SASTokenCredential

-- STEP 5: Clear existing data from target table
-- Remove all existing records from the bronze layer customer info table
-- This ensures we have a clean dataset without duplicates
TRUNCATE TABLE bronze.crm_cust_info;

-- STEP 6: Bulk insert data from CSV file to SQL table
-- Import customer data from the CSV file in Azure Blob Storage
-- into our bronze layer table for further processing
BULK INSERT bronze.crm_cust_info
    FROM 'source_crm/cust_info.csv'                    -- File path within the datasets container
    WITH (
        DATA_SOURCE = 'AzureBlobStorageSAS',            -- Use the external data source created above
        FIRSTROW = 2,                                   -- Skip header row (row 1 contains column names)
        FIELDTERMINATOR = ',',                          -- CSV fields are separated by commas
        TABLOCK                                         -- Use table lock for better performance during bulk load
    );
    -- File structure:
    -- Full path: https://dwhproject.blob.core.windows.net/datasets/source_crm/cust_info.csv
    -- Format: CSV with comma-separated values
    -- Header: First row contains column names (skipped)
    -- Data: Customer information starting from row 2

-- STEP 7: Verify data import - Display sample records
-- Show all imported records to verify the data was loaded correctly
-- This helps us validate the structure and content of the imported data
SELECT * FROM bronze.crm_cust_info;

-- STEP 8: Verify data import - Check record count
-- Count total number of records imported to ensure completeness
-- Compare this number with the expected record count from the source file
SELECT COUNT(*) FROM bronze.crm_cust_info;

-- ===============================================================
-- EXPECTED RESULTS:
-- - All existing data in bronze.crm_cust_info should be cleared
-- - New customer data should be imported from the CSV file
-- - Record count should match the number of data rows in the source CSV
-- - All customer fields should be populated correctly
-- ===============================================================

-- ===============================================================
-- TROUBLESHOOTING NOTES:
-- If errors occur, check:
-- 1. SAS token has not expired (valid until 2025-08-16)
-- 2. SAS token has correct permissions (read, list)
-- 3. Storage account and container names are correct
-- 4. File path 'source_crm/cust_info.csv' exists in the container
-- 5. bronze.crm_cust_info table structure matches CSV columns
-- 6. Database has sufficient space for the import
-- ===============================================================
