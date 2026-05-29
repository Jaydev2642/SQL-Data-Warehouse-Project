/*
===============================================================================
Quality Checks
===============================================================================
Script Purpose:
    This script performs various quality checks for data consistency, accuracy, 
    and standardization across the 'silver' layer. It includes checks for:
    - Null or duplicate primary keys.
    - Unwanted spaces in string fields.
    - Data standardization and consistency.
    - Invalid date ranges and orders.
    - Data consistency between related fields.

Usage Notes:
    - Run these checks after data loading Silver Layer.
    - Investigate and resolve any discrepancies found during the checks.
===============================================================================
*/

-- TABLE 1: silver.crm_cust_info =============================================================

-- Checks for Nulls or Duplicates in Primary Key
-- Expectation: No Result

SELECT
	cst_id,
	COUNT(*)
FROM silver.crm_cust_info
GROUP BY cst_id
HAVING 	
	count(*) > 1 OR cst_id IS NULL;	


-- Check for Unwanted Spaces
-- Expectation: No Result
SELECT cst_firstname
FROM silver.crm_cust_info
WHERE cst_firstname != TRIM(cst_firstname);


-- Data Standardization & Consistancy
SELECT DISTINCT cst_gndr
FROM silver.crm_cust_info;

SELECT DISTINCT cst_marital_status
FROM silver.crm_cust_info;


-- TABLE 2: silver.crm_prd_info =============================================================

-- Checks for Nulls or Duplicates in Primary Key
-- Expectation: No Result
SELECT
	prd_id,
	COUNT(*)
FROM silver.crm_prd_info
GROUP BY prd_id
HAVING COUNT(*) > 1 OR prd_id IS NULL;

-- Check for Unwanted Spaces
-- Expectation: No Result
SELECT prd_nm
FROM silver.crm_prd_info
WHERE prd_nm != TRIM(prd_nm);

-- Check for Nulls or Negative value in cost
-- Expectation: NO Result
SELECT prd_cost
FROM silver.crm_prd_info
WHERE prd_cost < 0 OR prd_cost IS NULL;

-- Data Standardization & Consistancy
SELECT DISTINCT prd_line
FROM silver.crm_prd_info;

-- Check for Invalid Date Orders (Start Date > End Date)
-- Expectation: No Results
SELECT *
FROM silver.crm_prd_info
WHERE prd_start_dt > prd_end_dt;

-- All Data
SELECT * FROM silver.crm_prd_info;


-- TABLE 3: silver.crm_sales_details =============================================================

-- Check for Unwanted Spaces
-- Expectation: No Result
SELECT sls_ord_num
FROM silver.crm_sales_details
WHERE sls_ord_num != TRIM(sls_ord_num);


-- Primary key integrity with Dimention tables
select * from silver.crm_sales_details
WHERE sls_prd_key NOT IN (SELECT prd_key FROM silver.crm_prd_info);

select * from silver.crm_sales_details
WHERE sls_cust_id NOT IN (SELECT cst_id FROM silver.crm_cust_info);

-- Check for Invalid dates
-- Expectation: No Invalid Dates
SELECT
	NULLIF(sls_order_dt, 0) AS sls_order_dt
FROM silver.crm_sales_details
WHERE
	sls_order_dt <= 0 
	OR LENGTH(CAST(sls_order_dt AS VARCHAR)) != 8
	OR sls_order_dt > 20270101 
    OR sls_order_dt < 19900101;

-- Check for Invalid dates Orders
SELECT *
FROM silver.crm_sales_details
WHERE sls_order_dt > sls_ship_dt
	OR sls_order_dt > sls_due_dt
	OR sls_ship_dt > sls_due_dt;


-- Check Data Consistency: Between Sales, Quantity, and Price
-- >> Sales = Quantity * Price
-- >> Values must not be NULL, Zero, or Negative.

SELECT
	sls_sales,
	sls_quantity,
	sls_price
FROM silver.crm_sales_details
WHERE sls_sales != sls_quantity * sls_price
	OR sls_sales IS NULL 
	OR sls_quantity IS NULL
	OR sls_price IS NULL
	OR sls_sales <= 0 
	OR sls_quantity <= 0 
	OR sls_price <= 0
ORDER BY sls_sales, sls_quantity, sls_price;

-- CHECK ALL DATA
SELECT * FROM silver.crm_sales_details;



-- TABLE 4: silver.erp_cust_az12 =============================================================
-- 
SELECT
	cid,
	CASE
		WHEN cid like 'NAS%' THEN SUBSTRING(cid, 4, LENGTH(cid))
		ELSE cid
	END AS cid_new,
	bdate,
	gen
FROM silver.erp_cust_az12
WHERE CASE
		WHEN cid like 'NAS%' THEN SUBSTRING(cid, 4, LENGTH(cid))
		ELSE cid
	END NOT IN (SELECT DISTINCT cst_key FROM silver.crm_cust_info);


-- Identify Out-of-Ranges Dates

SELECT DISTINCT
	bdate
FROM silver.erp_cust_az12
WHERE bdate < '1924-01-01'
	OR bdate > CURRENT_DATE;

-- Data Stanadardization & Consistency
SELECT DISTINCT
	gen
FROM silver.erp_cust_az12;

-- All Data
SELECT * FROM silver.erp_cust_az12;



-- TABLE 5: silver.erp_loc_a101 =============================================================

-- Data Standardization & Consistency
SELECT DISTINCT
	cntry
FROM silver.erp_loc_a101
ORDER BY cntry;

-- All Data
SELECT *
FROM silver.erp_loc_a101;


-- TABLE 6: silver.erp_px_cat_g1v2 =============================================================

-- Check for unwanted spaces
-- Expectation: No Results
SELECT *
FROM silver.erp_px_cat_g1v2
WHERE cat != TRIM(cat)
	OR subcat != TRIM(subcat)
	OR maintenance != TRIM(maintenance);


--  Data Standardization & Consistency
SELECT DISTINCT
	maintenance
FROM silver.erp_px_cat_g1v2;
