-- PARTIAL: only lines 122-128 of this file were visible in the screenshots.
-- Lines 1-121 (the three semantic view definitions) still need to be pasted in.

  module_custom_instructions:
    sql_generation: |
      Product experience metrics show correlation, not proven causation. Use document search for qualitative evidence.
$$,FALSE,TRUE);

GRANT SELECT ON SEMANTIC VIEW ANALYTICS.RETAIL_SALES_SV TO ROLE RETAILPULSE_DEMO_ROLE;
GRANT SELECT ON SEMANTIC VIEW ANALYTICS.INVENTORY_SUPPLY_SV TO ROLE RETAILPULSE_DEMO_ROLE;
-- (file is +130 lines; the CUSTOMER_PRODUCT_SV grant likely follows but was not visible)
