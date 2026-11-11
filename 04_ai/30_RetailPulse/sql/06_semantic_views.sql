USE ROLE RETAILPULSE_DEMO_ROLE;
USE WAREHOUSE RETAILPULSE_DEMO_WH;
USE DATABASE RETAILPULSE_AI;

CALL SYSTEM$CREATE_SEMANTIC_VIEW_FROM_YAML('RETAILPULSE_AI.ANALYTICS',$$
name: RETAIL_SALES_SV
description: Governed transaction-level sales, margin, promotion, store, product, category, channel, and regional analytics.
tables:
  - name: SALES
    description: One row per retail transaction line enriched with product, store, and promotion context.
    base_table: {database: RETAILPULSE_AI, schema: ANALYTICS, table: V_RETAIL_SALES}
    primary_key: {columns: [SALE_ID]}
    dimensions:
      - {name: SALE_ID, expr: SALE_ID, data_type: VARCHAR}
      - {name: SALE_TIME, expr: SALE_TIME, data_type: TIMESTAMP_NTZ}
      - {name: STORE_NAME, expr: STORE_NAME, data_type: VARCHAR}
      - {name: REGION, expr: REGION, data_type: VARCHAR}
      - {name: PRODUCT_ID, expr: PRODUCT_ID, data_type: VARCHAR}
      - {name: PRODUCT_NAME, expr: PRODUCT_NAME, data_type: VARCHAR}
      - {name: CATEGORY, expr: CATEGORY, data_type: VARCHAR}
      - {name: CHANNEL, expr: CHANNEL, data_type: VARCHAR}
      - {name: PROMOTION_NAME, expr: PROMOTION_NAME, data_type: VARCHAR}
    facts:
      - {name: UNITS, expr: UNITS, data_type: NUMBER}
      - {name: GROSS_SALES_USD, expr: GROSS_SALES_USD, data_type: NUMBER}
      - {name: DISCOUNT_USD, expr: DISCOUNT_USD, data_type: NUMBER}
      - {name: NET_SALES_USD, expr: NET_SALES_USD, data_type: NUMBER}
      - {name: COST_USD, expr: COST_USD, data_type: NUMBER}
      - {name: GROSS_MARGIN_USD, expr: GROSS_MARGIN_USD, data_type: NUMBER}
    metrics:
      - {name: TOTAL_UNITS, expr: SUM(UNITS)}
      - {name: TOTAL_NET_SALES_USD, expr: SUM(NET_SALES_USD)}
      - {name: TOTAL_DISCOUNT_USD, expr: SUM(DISCOUNT_USD)}
      - {name: TOTAL_GROSS_MARGIN_USD, expr: SUM(GROSS_MARGIN_USD)}
      - {name: AVERAGE_SELLING_PRICE_USD, expr: SUM(NET_SALES_USD)/NULLIF(SUM(UNITS),0)}
module_custom_instructions:
  sql_generation: |
    Use NET_SALES_USD for sales unless the user explicitly requests gross sales. Always label currency as USD.
  question_categorization: |
    Use this view for sales, promotion, margin, channel, region, store, product, and category questions.
verified_queries:
  - name: sales_and_margin_by_region
    question: Show net sales and gross margin by region.
    use_as_onboarding_question: true
    sql: |
      SELECT REGION, SUM(NET_SALES_USD) TOTAL_NET_SALES_USD, SUM(GROSS_MARGIN_USD) TOTAL_GROSS_MARGIN_USD
      FROM RETAILPULSE_AI.ANALYTICS.V_RETAIL_SALES GROUP BY REGION ORDER BY TOTAL_NET_SALES_USD DESC
$$,FALSE,TRUE);

CALL SYSTEM$CREATE_SEMANTIC_VIEW_FROM_YAML('RETAILPULSE_AI.ANALYTICS',$$
name: INVENTORY_SUPPLY_SV
description: Current store-product inventory, sales velocity, days of supply, promotion status, stockout risk, excess stock, and revenue-at-risk analytics.
tables:
  - name: INVENTORY
    description: One current row per store and product.
    base_table: {database: RETAILPULSE_AI, schema: ANALYTICS, table: V_INVENTORY_CONTROL_TOWER}
    primary_key: {columns: [STORE_ID, PRODUCT_ID]}
    dimensions:
      - {name: STORE_ID, expr: STORE_ID, data_type: VARCHAR}
      - {name: STORE_NAME, expr: STORE_NAME, data_type: VARCHAR}
      - {name: REGION, expr: REGION, data_type: VARCHAR}
      - {name: PRODUCT_ID, expr: PRODUCT_ID, data_type: VARCHAR}
      - {name: PRODUCT_NAME, expr: PRODUCT_NAME, data_type: VARCHAR}
      - {name: CATEGORY, expr: CATEGORY, data_type: VARCHAR}
      - {name: ACTIVE_PROMOTION, expr: ACTIVE_PROMOTION, data_type: BOOLEAN}
      - {name: STOCKOUT_RISK_7D, expr: STOCKOUT_RISK_7D, data_type: BOOLEAN}
    facts:
      - {name: AVAILABLE_QTY, expr: AVAILABLE_QTY, data_type: NUMBER}
      - {name: IN_TRANSIT_QTY, expr: IN_TRANSIT_QTY, data_type: NUMBER}
      - {name: AVG_DAILY_UNITS_7D, expr: AVG_DAILY_UNITS_7D, data_type: NUMBER}
      - {name: DAYS_OF_SUPPLY, expr: DAYS_OF_SUPPLY, data_type: NUMBER}
      - {name: REQUIRED_QTY_7D, expr: REQUIRED_QTY_7D, data_type: NUMBER}
      - {name: TRANSFERABLE_EXCESS_QTY, expr: TRANSFERABLE_EXCESS_QTY, data_type: NUMBER}
      - {name: REVENUE_AT_RISK_USD, expr: REVENUE_AT_RISK_USD, data_type: NUMBER}
    metrics:
      - {name: STORE_PRODUCT_COUNT, expr: COUNT(PRODUCT_ID)}
      - {name: TOTAL_AVAILABLE_QTY, expr: SUM(AVAILABLE_QTY)}
      - {name: TOTAL_REQUIRED_QTY_7D, expr: SUM(REQUIRED_QTY_7D)}
      - {name: TOTAL_TRANSFERABLE_EXCESS_QTY, expr: SUM(TRANSFERABLE_EXCESS_QTY)}
      - {name: TOTAL_REVENUE_AT_RISK_USD, expr: SUM(REVENUE_AT_RISK_USD)}
module_custom_instructions:
  sql_generation: |
    For stockout questions use STOCKOUT_RISK_7D and show revenue at risk. Inventory transfer recommendations require a source with transferable excess and a destination with required quantity.
verified_queries:
  - name: promoted_products_at_stockout_risk
    question: Which promoted products are at risk of stocking out in the next seven days?
    use_as_onboarding_question: true
    sql: |
      SELECT PRODUCT_ID, PRODUCT_NAME, CATEGORY, STORE_NAME, REGION, AVAILABLE_QTY, DAYS_OF_SUPPLY, REVENUE_AT_RISK_USD
      FROM RETAILPULSE_AI.ANALYTICS.V_INVENTORY_CONTROL_TOWER
      WHERE ACTIVE_PROMOTION=TRUE AND STOCKOUT_RISK_7D=TRUE ORDER BY REVENUE_AT_RISK_USD DESC
$$,FALSE,TRUE);

CALL SYSTEM$CREATE_SEMANTIC_VIEW_FROM_YAML('RETAILPULSE_AI.ANALYTICS',$$
name: CUSTOMER_PRODUCT_SV
description: Product sales, returns, refunds, review ratings, support cases, and quality-signal analytics.
tables:
  - name: PRODUCTS
    description: One aggregated row per product.
    base_table: {database: RETAILPULSE_AI, schema: ANALYTICS, table: V_PRODUCT_EXPERIENCE}
    primary_key: {columns: [PRODUCT_ID]}
    dimensions:
      - {name: PRODUCT_ID, expr: PRODUCT_ID, data_type: VARCHAR}
      - {name: PRODUCT_NAME, expr: PRODUCT_NAME, data_type: VARCHAR}
      - {name: CATEGORY, expr: CATEGORY, data_type: VARCHAR}
      - {name: BRAND, expr: BRAND, data_type: VARCHAR}
    facts:
      - {name: SOLD_UNITS, expr: SOLD_UNITS, data_type: NUMBER}
      - {name: NET_SALES_USD, expr: NET_SALES_USD, data_type: NUMBER}
      - {name: RETURNED_UNITS, expr: RETURNED_UNITS, data_type: NUMBER}
      - {name: REFUND_USD, expr: REFUND_USD, data_type: NUMBER}
      - {name: RETURN_RATE_PCT, expr: RETURN_RATE_PCT, data_type: NUMBER}
      - {name: AVG_REVIEW_RATING, expr: AVG_REVIEW_RATING, data_type: NUMBER}
      - {name: SUPPORT_CASE_COUNT, expr: SUPPORT_CASE_COUNT, data_type: NUMBER}
      - {name: QUALITY_SIGNAL_COUNT, expr: QUALITY_SIGNAL_COUNT, data_type: NUMBER}
    metrics:
      - {name: TOTAL_SOLD_UNITS, expr: SUM(SOLD_UNITS)}
      - {name: TOTAL_RETURNED_UNITS, expr: SUM(RETURNED_UNITS)}
      - {name: TOTAL_REFUND_USD, expr: SUM(REFUND_USD)}
      - {name: AVERAGE_RETURN_RATE_PCT, expr: AVG(RETURN_RATE_PCT)}
      - {name: AVERAGE_REVIEW_RATING, expr: AVG(AVG_REVIEW_RATING)}
module_custom_instructions:
  sql_generation: |
    Product experience metrics show correlation, not proven causation. Use document search for qualitative evidence.
$$,FALSE,TRUE);

GRANT SELECT ON SEMANTIC VIEW ANALYTICS.RETAIL_SALES_SV TO ROLE RETAILPULSE_DEMO_ROLE;
GRANT SELECT ON SEMANTIC VIEW ANALYTICS.INVENTORY_SUPPLY_SV TO ROLE RETAILPULSE_DEMO_ROLE;
GRANT SELECT ON SEMANTIC VIEW ANALYTICS.CUSTOMER_PRODUCT_SV TO ROLE RETAILPULSE_DEMO_ROLE;
