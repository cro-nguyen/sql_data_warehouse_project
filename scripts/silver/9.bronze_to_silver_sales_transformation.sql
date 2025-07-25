-- ===============================================================
-- Bronze to Silver Transformation - Sales Data
-- ===============================================================
-- Purpose: Transform and clean sales data from bronze to silver layer
-- Source: bronze.crm_sales_details
-- Target: silver.crm_sales_details
-- Transformations: Convert integer dates to DATE format, fix calculated fields, handle NULLs
-- Author: Hung Nguyen
-- Date: July 25, 2025
-- ===============================================================

-- Transform sales data with complex data cleaning and validation
-- 1. Convert integer dates (YYYYMMDD) to proper DATE format, handle invalid formats with NULL
-- 2. Fix sales amount calculation: use quantity × price when original calculation is wrong
-- 3. Handle negative prices by taking absolute value
-- 4. Calculate missing prices by dividing sales by quantity (avoid division by zero)
-- 5. Maintain data integrity while fixing common data quality issues

TRUNCATE TABLE silver.crm_sales_details;   -- Remove all existing records from silver table for clean reload
INSERT INTO silver.crm_sales_details (
   sls_ord_num,
   sls_prd_key,
   sls_cust_id,
   sls_order_dt,
   sls_ship_dt,
   sls_due_dt,
   sls_sales,
   sls_quantity,
   sls_price)
SELECT
   sls_ord_num,
   sls_prd_key,
   sls_cust_id,
   CASE WHEN sls_order_dt = 0 OR LEN(sls_order_dt) != 8 THEN NULL
       ELSE CAST(CAST(sls_order_dt AS VARCHAR) AS DATE)
       END AS sls_order_dt,
   CASE WHEN sls_ship_dt = 0 OR LEN(sls_ship_dt) != 8 THEN NULL
       ELSE CAST(CAST(sls_ship_dt AS VARCHAR) AS DATE)
       END AS sls_ship_dt,
   CASE WHEN sls_due_dt = 0 OR LEN(sls_due_dt) != 8 THEN NULL
       ELSE CAST(CAST(sls_due_dt AS VARCHAR) AS DATE)
       END AS sls_due_dt,
   CASE WHEN sls_sales IS NULL OR sls_sales <= 0 OR sls_sales != sls_quantity * ABS(sls_price)
       THEN sls_quantity * ABS(sls_price)
       ELSE sls_sales
   END AS sls_sales,
   sls_quantity,
   CASE WHEN sls_price IS NULL OR sls_price <= 0
       THEN sls_sales/NULLIF(sls_quantity, 0)
       ELSE sls_price
   END AS sls_price
FROM bronze.crm_sales_details
