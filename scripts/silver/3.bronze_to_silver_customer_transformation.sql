-- ===============================================================
-- Bronze to Silver Transformation - Customer Data
-- ===============================================================
-- Purpose: Transform and clean customer data from bronze to silver layer
-- Source: bronze.crm_cust_info
-- Target: silver.crm_cust_info
-- Transformations: Remove spaces, standardize categorical values, deduplicate
-- Author: [Your Name]
-- Date: July 24, 2025
-- ===============================================================

-- Transform customer data with cleaning and standardization
-- 1. Remove leading/trailing spaces from names
-- 2. Standardize marital status (S→Single, M→Married, other→n/a)
-- 3. Standardize gender (F→Female, M→Male, other→n/a)
-- 4. Deduplicate by keeping latest record per customer (ROW_NUMBER with cst_create_date DESC)
-- 5. Filter out records with NULL customer IDs

INSERT INTO silver.crm_cust_info (cst_id, cst_key, cst_firstname, cst_lastname, cst_material_status, cst_gndr, cst_create_date)
SELECT
   cst_id,
   cst_key,
   TRIM(cst_firstname) AS cst_firstname,
   TRIM(cst_lastname) AS cst_lastname,
   CASE WHEN UPPER(TRIM(cst_material_status)) = 'S' THEN 'Single'
        WHEN UPPER(TRIM(cst_material_status)) = 'M' THEN 'Married'
        ELSE 'n/a'
   END cst_material_status,
   CASE WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
        WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
        ELSE 'n/a'
   END cst_gndr,
   cst_create_date
FROM (
   SELECT
   *,
   ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) AS flag_last
   FROM bronze.crm_cust_info
   WHERE cst_id IS NOT NULL ) t
WHERE flag_last = 1;
