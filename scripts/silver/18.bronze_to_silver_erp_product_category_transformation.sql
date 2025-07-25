-- ===============================================================
-- Bronze to Silver Transformation - ERP Product Category Data
-- ===============================================================
-- Purpose: Transform ERP product category data from bronze to silver layer
-- Source: bronze.erp_px_cat_g1v2
-- Target: silver.erp_px_cat_g1v2
-- Transformations: Direct copy with data refresh (truncate and reload)
-- Author: Hung Nguyen
-- Date: July 25, 2025
-- ===============================================================

-- Clear existing data and reload with fresh data from bronze layer
-- 1. Remove all existing records from silver table for clean reload
-- 2. Insert all product category data from bronze layer without transformation
-- 3. Maintains referential integrity with product catalog
TRUNCATE TABLE silver.erp_px_cat_g1v2;
INSERT INTO silver.erp_px_cat_g1v2(id, cat, subcat, maintenance)
SELECT
   id,
   cat,
   subcat,
   maintenance
FROM bronze.erp_px_cat_g1v2;
