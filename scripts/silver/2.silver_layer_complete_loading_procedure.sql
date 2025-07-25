-- ===============================================================
-- Silver Layer Data Loading Procedure
-- ===============================================================
-- Purpose: Automated transformation and loading of all tables from bronze to silver layer
-- Tables: CRM (customers, products, sales) + ERP (demographics, location, categories)
-- Transformations: Data cleaning, standardization, date conversions, deduplication
-- Author: Hung Nguyen
-- Date: July 25, 2025
-- ===============================================================

-- Execute procedure to load all silver layer tables
EXEC silver.load_silver;

-- ===============================================================
-- PROCEDURE: Complete Bronze to Silver Transformation
-- ===============================================================
-- Purpose: Transform all bronze layer data to silver with comprehensive cleaning and standardization
-- Frequency: Daily/batch processing for data warehouse refresh
CREATE OR ALTER PROCEDURE silver.load_silver AS
BEGIN
   DECLARE @start_time DATETIME, @end_time DATETIME, @batch_start_time DATETIME, @batch_end_time DATETIME;
   BEGIN TRY

   SET @batch_start_time = GETDATE()

       -- ===============================================================
       -- CRM CUSTOMER DATA TRANSFORMATION
       -- ===============================================================
       SET @start_time = GETDATE();

       PRINT '>> TRUNCATING TABLE: silver.crm_cust_info';
       TRUNCATE TABLE silver.crm_cust_info; -- Remove all existing records for clean reload

       PRINT '>> INSERTING DATA INTO: silver.crm_cust_info';
       -- Transform customer data: trim names, standardize marital status and gender, deduplicate
       INSERT INTO silver.crm_cust_info (cst_id, cst_key, cst_firstname, cst_lastname, cst_material_status, cst_gndr,
                                         cst_create_date)
       SELECT cst_id,
              cst_key,
              TRIM(cst_firstname) AS cst_firstname,
              TRIM(cst_lastname)  AS cst_lastname,
              CASE
                  WHEN UPPER(TRIM(cst_material_status)) = 'S' THEN 'Single'
                  WHEN UPPER(TRIM(cst_material_status)) = 'M' THEN 'Married'
                  ELSE 'n/a'
                  END                cst_material_status,
              CASE
                  WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
                  WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
                  ELSE 'n/a'
                  END                cst_gndr,
              cst_create_date
       FROM (SELECT *,
                    ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) AS flag_last
             FROM bronze.crm_cust_info
             WHERE cst_id IS NOT NULL) t
       WHERE flag_last = 1;

       SET @end_time = GETDATE()
       PRINT '>> Load duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS VARCHAR) + ' seconds'
       PRINT '---------------------------------------'

       -- ===============================================================
       -- CRM PRODUCT DATA TRANSFORMATION
       -- ===============================================================
       SET @start_time = GETDATE();
       PRINT '>> TRUNCATING TABLE: silver.crm_prd_info';
       TRUNCATE TABLE silver.crm_prd_info;

       PRINT '>> INSERTING DATA INTO: silver.crm_prd_info';
       -- Transform product data: extract category ID, clean product key, standardize product lines, calculate end dates
       INSERT INTO silver.crm_prd_info(prd_id, cat_id, prd_key, prd_nm, prd_cost, prd_line, prd_start_dt, prd_end_dt)
       SELECT prd_id,
              REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_')                                             AS cat_id,
              SUBSTRING(prd_key, 7, LEN(prd_key))                                                     AS prd_key,
              prd_nm,
              COALESCE(prd_code, 0)                                                                   AS prd_cost,
              CASE UPPER(TRIM(prd_line))
                  WHEN 'M' THEN 'Mountain'
                  WHEN 'R' THEN 'Road'
                  WHEN 'S' THEN 'Other Sales'
                  WHEN 'T' THEN 'Touring'
                  ELSE 'n/a'
                  END                                                                                 AS prd_line,
              CAST(prd_start_dt AS DATE)                                                              AS prd_start_dt,
              CAST(LEAD(prd_start_dt) OVER ( PARTITION BY prd_key ORDER BY prd_start_dt) - 1 AS DATE) AS prd_end_dt
       FROM bronze.crm_prd_info
       SET @end_time = GETDATE()
       PRINT '>> Load duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS VARCHAR) + ' seconds'
       PRINT '---------------------------------------'

       -- ===============================================================
       -- CRM SALES DATA TRANSFORMATION
       -- ===============================================================
       SET @start_time = GETDATE();
       PRINT '>> TRUNCATING TABLE: silver.crm_sales_details';
       TRUNCATE TABLE silver.crm_sales_details;

       PRINT '>> INSERTING DATA INTO: silver.crm_sales_details';
       -- Transform sales data: convert integer dates to DATE format, fix calculated fields, handle NULLs
       INSERT INTO silver.crm_sales_details (sls_ord_num,
                                             sls_prd_key,
                                             sls_cust_id,
                                             sls_order_dt,
                                             sls_ship_dt,
                                             sls_due_dt,
                                             sls_sales,
                                             sls_quantity,
                                             sls_price)
       SELECT sls_ord_num,
              sls_prd_key,
              sls_cust_id,
              CASE
                  WHEN sls_order_dt = 0 OR LEN(sls_order_dt) != 8 THEN NULL
                  ELSE CAST(CAST(sls_order_dt AS VARCHAR) AS DATE)
                  END AS sls_order_dt,
              CASE
                  WHEN sls_ship_dt = 0 OR LEN(sls_ship_dt) != 8 THEN NULL
                  ELSE CAST(CAST(sls_ship_dt AS VARCHAR) AS DATE)
                  END AS sls_ship_dt,
              CASE
                  WHEN sls_due_dt = 0 OR LEN(sls_due_dt) != 8 THEN NULL
                  ELSE CAST(CAST(sls_due_dt AS VARCHAR) AS DATE)
                  END AS sls_due_dt,
              CASE
                  WHEN sls_sales IS NULL OR sls_sales <= 0 OR sls_sales != sls_quantity * ABS(sls_price)
                      THEN sls_quantity * ABS(sls_price)
                  ELSE sls_sales
                  END AS sls_sales,
              sls_quantity,
              CASE
                  WHEN sls_price IS NULL OR sls_price <= 0
                      THEN sls_sales / NULLIF(sls_quantity, 0)
                  ELSE sls_price
                  END AS sls_price
       FROM bronze.crm_sales_details
       SET @end_time = GETDATE()
       PRINT '>> Load duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS VARCHAR) + ' seconds'
       PRINT '---------------------------------------'

       -- ===============================================================
       -- ERP CUSTOMER DEMOGRAPHICS TRANSFORMATION
       -- ===============================================================
       SET @start_time = GETDATE();
       PRINT '>> TRUNCATING TABLE: silver.erp_cust_az12';
       TRUNCATE TABLE silver.erp_cust_az12;

       PRINT '>> INSERTING DATA INTO: silver.erp_cust_az12';
       -- Transform ERP customer data: clean customer IDs, validate birth dates, standardize gender
       INSERT INTO silver.erp_cust_az12(cid, bdate, gen)
       SELECT CASE
                  WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LEN(cid))
                  ELSE cid
                  END AS cid,
              CASE
                  WHEN bdate > GETDATE() THEN NULL
                  ELSE bdate
                  END AS bdate,
              CASE
                  WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE') THEN 'Female'
                  WHEN UPPER(TRIM(gen)) IN ('M', 'MALE') THEN 'Male'
                  ELSE 'n/a'
                  END AS gen
       FROM bronze.erp_cust_az12;
       SET @end_time = GETDATE()
       PRINT '>> Load duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS VARCHAR) + ' seconds'
       PRINT '---------------------------------------'

       -- ===============================================================
       -- ERP LOCATION DATA TRANSFORMATION
       -- ===============================================================
       SET @start_time = GETDATE();
       PRINT '>> TRUNCATING TABLE: silver.erp_loc_a101';
       TRUNCATE TABLE silver.erp_loc_a101;

       PRINT '>> INSERTING DATA INTO: silver.erp_loc_a101';
       -- Transform ERP location data: clean customer IDs, standardize country codes
       INSERT INTO silver.erp_loc_a101(cid, cntry)
       SELECT REPLACE(cid, '-', '') cid,
              CASE
                  WHEN UPPER(TRIM(cntry)) = 'DE' THEN 'Germany'
                  WHEN UPPER(TRIM(cntry)) IN ('US', 'USA') THEN 'United State'
                  WHEN TRIM(cntry) = '' OR cntry IS NULL THEN 'n/a'
                  ELSE TRIM(cntry)
                  END AS            cntry
       FROM bronze.erp_loc_a101;
       SET @end_time = GETDATE()
       PRINT '>> Load duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS VARCHAR) + ' seconds'
       PRINT '---------------------------------------'

       -- ===============================================================
       -- ERP PRODUCT CATEGORY DATA TRANSFORMATION
       -- ===============================================================
       SET @start_time = GETDATE();
       PRINT '>> TRUNCATING TABLE: silver.erp_px_cat_g1v2';
       TRUNCATE TABLE silver.erp_px_cat_g1v2;

       PRINT '>> INSERTING DATA INTO: silver.erp_px_cat_g1v2';
       -- Transfer ERP product category data: direct copy without transformation
       INSERT INTO silver.erp_px_cat_g1v2(id, cat, subcat, maintenance)
       SELECT id,
              cat,
              subcat,
              maintenance
       FROM bronze.erp_px_cat_g1v2;
       SET @end_time = GETDATE()
       PRINT '>> Load duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS VARCHAR) + ' seconds'
       PRINT '---------------------------------------'

       -- ===============================================================
       -- BATCH COMPLETION SUMMARY
       -- ===============================================================
       SET @batch_end_time = GETDATE();
       PRINT '---------------------------------------';
       PRINT 'Loading Silver Layer is Completed';
       PRINT '- Total duration: ' + CAST(DATEDIFF(SECOND,@batch_start_time, @batch_end_time) AS NVARCHAR) + ' seconds';

   END TRY

   BEGIN CATCH
      -- Comprehensive error handling and logging
      PRINT '---------------------------------------';
      PRINT 'ERROR OCCURRED DURING LOADING SILVER LAYER';
      PRINT 'ERROR MESSAGE: ' + ERROR_MESSAGE();
      PRINT 'ERROR NUMBER: ' + CAST(ERROR_NUMBER() AS NVARCHAR);
      PRINT 'ERROR STATE: ' + CAST(ERROR_STATE() AS NVARCHAR);
   END CATCH
END
