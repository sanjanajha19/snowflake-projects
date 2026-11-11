USE ROLE RETAILPULSE_DEMO_ROLE;
USE DATABASE RETAILPULSE_AI;
USE SCHEMA AGENT;

CREATE OR REPLACE AGENT RETAILPULSE_AGENT
  COMMENT = 'Retail inventory, sales, customer experience, and approval-gated transfer copilot'
  PROFILE = '{"display_name":"RetailPulse AI","avatar":"shopping-cart"}'
  FROM SPECIFICATION
$$
{
  "models": {"orchestration": "auto"},
  "orchestration": {
    "budget": {"seconds": 60, "tokens": 12000}
  },
  "instructions": {
    "response": "Act as a retail control-tower copilot. Start with the business answer, quantify risk and opportunity, state assumptions, and cite the store, product, date window, and evidence used. Revenue risk is an estimate, not booked revenue. Treat correlations in returns or reviews as signals, not proof of causality. Never claim that inventory moved. Only invoke CreateTransfer after the user explicitly asks to create a request; the result remains PENDING_APPROVAL.",
    "orchestration": "Use RetailSales for sales, revenue, margin, promotion, channel, store, product, and category questions. Use InventorySupply for on-hand, available inventory, velocity, days of supply, stockout risk, excess, and transfer analysis. Use CustomerProduct for return rates, refunds, quality signals, ratings, and product experience metrics. Use ProductExperienceSearch for unstructured reviews, support cases, guides, policies, and store notes. Use DataToChart when a chart materially improves the answer. Combine structured metrics and document evidence for root-cause questions."
  },
  "tools": [
    {
      "tool_spec": {
        "type": "cortex_analyst_text_to_sql",
        "name": "RetailSales",
        "description": "Governed retail sales, margin, promotions, channel, store, product, and category analysis"
      }
    },
    {
      "tool_spec": {
        "type": "cortex_analyst_text_to_sql",
        "name": "InventorySupply",
        "description": "Inventory health, demand velocity, stockout risk, excess stock, and store transfer analysis"
      }
    },
    {
      "tool_spec": {
        "type": "cortex_analyst_text_to_sql",
        "name": "CustomerProduct",
        "description": "Returns, refunds, ratings, support contacts, and product quality signal analysis"
      }
    },
    {
      "tool_spec": {
        "type": "cortex_search",
        "name": "ProductExperienceSearch",
        "description": "Search product reviews, support cases, product guides, policies, and store notes"
      }
    },
    {
      "tool_spec": {
        "type": "data_to_chart",
        "name": "DataToChart",
        "description": "Chart query results"
      }
    },
    {
      "tool_spec": {
        "type": "generic",
        "name": "CreateTransfer",
        "description": "Create an approval-gated inventory transfer request; never moves inventory",
        "input_schema": {
          "type": "object",
          "properties": {
            "PRODUCT_ID": {"type": "string"},
            "FROM_STORE_ID": {"type": "string"},
            "TO_STORE_ID": {"type": "string"},
            "QUANTITY": {"type": "number"},
            "REASON": {"type": "string"}
          },
          "required": ["PRODUCT_ID", "FROM_STORE_ID", "TO_STORE_ID", "QUANTITY", "REASON"]
        }
      }
    }
  ],
  "tool_resources": {
    "RetailSales": {"semantic_view": "RETAILPULSE_AI.ANALYTICS.RETAIL_SALES_SV"},
    "InventorySupply": {"semantic_view": "RETAILPULSE_AI.ANALYTICS.INVENTORY_SUPPLY_SV"},
    "CustomerProduct": {"semantic_view": "RETAILPULSE_AI.ANALYTICS.CUSTOMER_PRODUCT_SV"},
    "ProductExperienceSearch": {
      "search_service": "RETAILPULSE_AI.SEARCH.PRODUCT_EXPERIENCE_SEARCH",
      "max_results": 8,
      "id_column": "DOCUMENT_ID",
      "title_column": "TITLE"
    },
    "CreateTransfer": {
      "type": "procedure",
      "identifier": "RETAILPULSE_AI.AGENT.CREATE_TRANSFER_REQUEST"
    }
  }
}
$$;

GRANT USAGE ON AGENT RETAILPULSE_AGENT TO ROLE RETAILPULSE_DEMO_ROLE;
