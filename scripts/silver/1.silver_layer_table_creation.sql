-- ===============================================================
-- Data Warehouse Silver Layer - Table Creation Script
-- ===============================================================
-- Purpose: Create silver layer tables for cleaned and validated data
-- Layer: Silver (Cleaned data with data warehouse metadata)
-- Source: Bronze layer tables (raw data)
-- Author: [Your Name]
-- Date: July 24, 2025
-- ===============================================================

-- MEDALLION ARCHITECTURE - SILVER LAYER:
-- Silver layer stores cleaned, validated, and enriched data from bronze layer.
-- Adds data warehouse metadata (dwh_create_date) for tracking and auditing.
-- Same structure as bronze but ready for business transformations.
-- ===============================================================

-- ===============================================================
-- CRM SYSTEM TABLES (SILVER)
-- ===============================================================

-- Customer master data - cleaned and validated
-- Source: bronze.crm_cust_info
-- Enhancements: Added data warehouse audit column
IF OBJECT_ID('silver.crm_cust_info', 'U') IS NOT NULL
    DROP TABLE silver.crm_cust_info;
CREATE TABLE silver.crm_cust_info (
    cst_id INT,                         -- Customer ID
    cst_key NVARCHAR(50),              -- Customer business key
    cst_firstname NVARCHAR(50),        -- First name (cleaned)
    cst_lastname NVARCHAR(50),         -- Last name (cleaned)
    cst_material_status NVARCHAR(50),  -- Marital status (standardized)
    cst_gndr NVARCHAR(50),             -- Gender (standardized)
    cst_create_date DATE,              -- Account creation date
    dwh_create_date DATETIME2 DEFAULT GETDATE()  -- Data warehouse load timestamp
);

-- Product master data - cleaned and validated
-- Source: bronze.crm_prd_info
-- Enhancements: Added data warehouse audit column
IF OBJECT_ID('silver.crm_prd_info', 'U') IS NOT NULL
    DROP TABLE silver.crm_prd_info;
CREATE TABLE silver.crm_prd_info (
    prd_id INT,                        -- Product ID
    prd_key NVARCHAR(50),             -- Product business key
    prd_nm NVARCHAR(50),              -- Product name (cleaned)
    prd_code INT,                     -- Product code
    prd_line NVARCHAR(50),            -- Product line (standardized)
    prd_start_dt DATETIME,            -- Launch date
    prd_end_dt DATETIME,              -- End date
    dwh_create_date DATETIME2 DEFAULT GETDATE()  -- Data warehouse load timestamp
);

-- Sales transaction data - cleaned and validated
-- Source: bronze.crm_sales_details
-- Note: Date and price fields still in integer format - to be converted in transformation
IF OBJECT_ID('silver.crm_sales_details', 'U') IS NOT NULL
    DROP TABLE silver.crm_sales_details;
CREATE TABLE silver.crm_sales_details (
    sls_ord_num NVARCHAR(50),         -- Order number
    sls_prd_key NVARCHAR(50),         -- Product key
    sls_cust_id INT,                  -- Customer ID
    sls_order_dt INT,                 -- Order date (integer - needs conversion)
    sls_ship_dt INT,                  -- Ship date (integer - needs conversion)
    sls_due_dt INT,                   -- Due date (integer - needs conversion)
    sls_sales INT,                    -- Sales amount (integer - needs conversion)
    sls_quantity INT,                 -- Quantity
    sls_price INT,                    -- Unit price (integer - needs conversion)
    dwh_create_date DATETIME2 DEFAULT GETDATE()  -- Data warehouse load timestamp
);

-- ===============================================================
-- ERP SYSTEM TABLES (SILVER)
-- ===============================================================

-- Customer location data - cleaned and validated
-- Source: bronze.erp_loc_a101
-- Enhancements: Added data warehouse audit column
IF OBJECT_ID('silver.erp_loc_a101', 'U') IS NOT NULL
    DROP TABLE silver.erp_loc_a101;
CREATE TABLE silver.erp_loc_a101 (
    cid NVARCHAR(50),                 -- Customer ID
    cntry NVARCHAR(50),               -- Country (standardized)
    dwh_create_date DATETIME2 DEFAULT GETDATE()  -- Data warehouse load timestamp
);

-- Customer demographics - cleaned and validated
-- Source: bronze.erp_cust_az12
-- Enhancements: Added data warehouse audit column
IF OBJECT_ID('silver.erp_cust_az12', 'U') IS NOT NULL
    DROP TABLE silver.erp_cust_az12;
CREATE TABLE silver.erp_cust_az12 (
    cid NVARCHAR(50),                 -- Customer ID
    bdate DATE,                       -- Birth date
    gen NVARCHAR(50),                 -- Gender (standardized)
    dwh_create_date DATETIME2 DEFAULT GETDATE()  -- Data warehouse load timestamp
);

-- Product category data - cleaned and validated
-- Source: bronze.erp_px_cat_g1v2
-- Enhancements: Added data warehouse audit column
IF OBJECT_ID('silver.erp_px_cat_g1v2', 'U') IS NOT NULL
    DROP TABLE silver.erp_px_cat_g1v2;
CREATE TABLE silver.erp_px_cat_g1v2 (
    id NVARCHAR(50),                  -- Product ID
    cat NVARCHAR(50),                 -- Category (standardized)
    subcat NVARCHAR(50),              -- Subcategory (standardized)
    maintenance NVARCHAR(50),         -- Maintenance info (standardized)
    dwh_create_date DATETIME2 DEFAULT GETDATE()  -- Data warehouse load timestamp
);

-- ===============================================================
-- SILVER LAYER ENHANCEMENTS
-- ===============================================================
-- Key differences from Bronze layer:
-- 1. Added dwh_create_date column to all tables for data lineage tracking
-- 2. Data will be cleaned and validated during bronze-to-silver transformation
-- 3. Ready for business rules and quality checks
-- 4. Prepared for gold layer aggregations and analytics
--
-- Next steps:
-- 1. Create transformation procedures from bronze to silver
-- 2. Implement data quality validation rules
-- 3. Add data type conversions (dates, decimals)
-- 4. Standardize categorical values
-- ===============================================================

PRINT '✅ Silver layer tables created successfully!';
PRINT 'Ready for data transformation from bronze layer.';
