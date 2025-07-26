-- ===============================================================
-- Bronze Layer Tables Creation Script
-- ===============================================================
-- Purpose: Create bronze layer tables for raw data ingestion from CRM and ERP systems
-- Author: [Your Name]
-- Date: July 24, 2025
-- ===============================================================

-- BRONZE LAYER: Raw data storage (no transformations)
-- Sources: CRM system (customers, products, sales) + ERP system (location, demographics, categories)

-- ===============================================================
-- CRM SYSTEM TABLES
-- ===============================================================

-- Customer master data from CRM
IF OBJECT_ID('bronze.crm_cust_info', 'U') IS NOT NULL
    DROP TABLE bronze.crm_cust_info;
CREATE TABLE bronze.crm_cust_info (
    cst_id INT,                         -- Customer ID
    cst_key NVARCHAR(50),              -- Customer business key
    cst_firstname NVARCHAR(50),        -- First name
    cst_lastname NVARCHAR(50),         -- Last name
    cst_material_status NVARCHAR(50),  -- Marital status
    cst_gndr NVARCHAR(50),             -- Gender
    cst_create_date DATE               -- Account creation date
);

-- Product master data from CRM
IF OBJECT_ID('bronze.crm_prd_info', 'U') IS NOT NULL
    DROP TABLE bronze.crm_prd_info;
CREATE TABLE bronze.crm_prd_info (
    prd_id INT,                        -- Product ID
    prd_key NVARCHAR(50),             -- Product business key
    prd_nm NVARCHAR(50),              -- Product name
    prd_code INT,                     -- Product code
    prd_line NVARCHAR(50),            -- Product line
    prd_start_dt DATETIME,            -- Launch date
    prd_end_dt DATETIME               -- End date
);

-- Sales transaction details from CRM
IF OBJECT_ID('bronze.crm_sales_details', 'U') IS NOT NULL
    DROP TABLE bronze.crm_sales_details;
CREATE TABLE bronze.crm_sales_details (
    sls_ord_num NVARCHAR(50),         -- Order number
    sls_prd_key NVARCHAR(50),         -- Product key
    sls_cust_id INT,                  -- Customer ID
    sls_order_dt INT,                 -- Order date (integer format)
    sls_ship_dt INT,                  -- Ship date (integer format)
    sls_due_dt INT,                   -- Due date (integer format)
    sls_sales INT,                    -- Sales amount (integer format)
    sls_quantity INT,                 -- Quantity
    sls_price INT                     -- Unit price (integer format)
);

-- ===============================================================
-- ERP SYSTEM TABLES
-- ===============================================================

-- Customer location data from ERP
IF OBJECT_ID('bronze.erp_loc_a101', 'U') IS NOT NULL
    DROP TABLE bronze.erp_loc_a101;
CREATE TABLE bronze.erp_loc_a101 (
    cid NVARCHAR(50),                 -- Customer ID
    cntry NVARCHAR(50)                -- Country
);

-- Customer demographics from ERP
IF OBJECT_ID('bronze.erp_cust_az12', 'U') IS NOT NULL
    DROP TABLE bronze.erp_cust_az12;
CREATE TABLE bronze.erp_cust_az12 (
    cid NVARCHAR(50),                 -- Customer ID
    bdate DATE,                       -- Birth date
    gen NVARCHAR(50)                  -- Gender
);

-- Product category data from ERP
IF OBJECT_ID('bronze.erp_px_cat_g1v2', 'U') IS NOT NULL
    DROP TABLE bronze.erp_px_cat_g1v2;
CREATE TABLE bronze.erp_px_cat_g1v2 (
    id NVARCHAR(50),                  -- Product ID
    cat NVARCHAR(50),                 -- Category
    subcat NVARCHAR(50),              -- Subcategory
    maintenance NVARCHAR(50)          -- Maintenance info
);

-- ===============================================================
-- NOTES FOR NEXT STEPS
-- ===============================================================
-- 1. Load raw data from source systems using BULK INSERT
-- 2. Data quality issues to fix in silver layer:
--    - Convert integer dates to proper DATE format
--    - Convert integer prices to DECIMAL format
--    - Standardize gender codes between CRM and ERP
-- 3. Establish data relationships and validation in silver layer

PRINT '✅ Bronze layer tables created successfully!';
