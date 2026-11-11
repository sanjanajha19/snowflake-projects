USE ROLE RETAILPULSE_DEMO_ROLE;
USE DATABASE RETAILPULSE_AI;
USE SCHEMA AGENT;

-- Trial fallback when Cortex Search is not available in the selected region.
-- The Agent remains useful with three governed Semantic Views and charting.
CREATE OR REPLACE AGENT RETAILPULSE_AGENT
  COMMENT = 'Retail copilot fallback without Cortex Search'
  PROFILE = '{"display_name":"RetailPulse AI","avatar":"shopping-cart"}'
  FROM SPECIFICATION
$$
{
  "models": {"orchestration": "auto"},
  "orchestration": {"budget": {"seconds": 60, "tokens": 10000}},
  "instructions": {
    "response": "Act as a retail control-tower copilot. Quantify risk and opportunity, state assumptions, and identify the store, product, and date window. Revenue risk is an estimate. Document search is unavailable in this deployment; say so when asked for review or support-case evidence. Only create a transfer request after explicit confirmation, and make clear it remains pending approval.",
    "orchestration": "Use RetailSales for sales and margin, InventorySupply for stockout and transfer analysis, CustomerProduct for return and product quality metrics, DataToChart for useful visuals, and CreateTransfer only on an explicit request."
  },
  "tools": [
    {"tool_spec":{"type":"cortex_analyst_text_to_sql","name":"RetailSales","description":"Governed retail sales and margin analysis"}},
    {"tool_spec":{"type":"cortex_analyst_text_to_sql","name":"InventorySupply","description":"Inventory, stockout, excess, and transfer analysis"}},
    {"tool_spec":{"type":"cortex_analyst_text_to_sql","name":"CustomerProduct","description":"Returns, refunds, ratings, and quality signals"}},
    {"tool_spec":{"type":"data_to_chart","name":"DataToChart","description":"Chart query results"}},
    {
      "tool_spec": {
        "type":"generic", "name":"CreateTransfer",
        "description":"Create a pending-approval transfer request without moving inventory",
        "input_schema": {
          "type":"object",
          "properties": {
            "PRODUCT_ID":{"type":"string"}, "FROM_STORE_ID":{"type":"string"},
            "TO_STORE_ID":{"type":"string"}, "QUANTITY":{"type":"number"},
            "REASON":{"type":"string"}
          },
          "required":["PRODUCT_ID","FROM_STORE_ID","TO_STORE_ID","QUANTITY","REASON"]
        }
      }
    }
  ],
  "tool_resources": {
    "RetailSales":{"semantic_view":"RETAILPULSE_AI.ANALYTICS.RETAIL_SALES_SV"},
    "InventorySupply":{"semantic_view":"RETAILPULSE_AI.ANALYTICS.INVENTORY_SUPPLY_SV"},
    "CustomerProduct":{"semantic_view":"RETAILPULSE_AI.ANALYTICS.CUSTOMER_PRODUCT_SV"},
    "CreateTransfer":{"type":"procedure","identifier":"RETAILPULSE_AI.AGENT.CREATE_TRANSFER_REQUEST"}
  }
}
$$;

GRANT USAGE ON AGENT RETAILPULSE_AGENT TO ROLE RETAILPULSE_DEMO_ROLE;
