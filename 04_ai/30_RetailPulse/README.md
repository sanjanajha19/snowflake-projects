# RetailPulse AI — Snowflake Retail Inventory and Merchandising Agent

RetailPulse AI is a self-contained Snowflake client demo that helps merchandising, store operations, supply-chain, and customer-experience teams prevent stockouts, reduce overstock, understand promotion performance, and investigate product issues without writing SQL.

## What the use case does

Business users work in Snowflake CoWork and ask questions such as:

- Which promoted products are likely to stock out this weekend?
- How much revenue is at risk, and which stores can supply replacement inventory?
- Why did sales fall for a category or region?
- Which products combine high returns with negative reviews?
- What customer issues are driving return rates?
- Create an approval-gated stock-transfer recommendation.

The primary demonstration journey is: **detect stockout risk → quantify lost revenue → find excess stock → explain customer/product signals → recommend a transfer → create an approval request**.

## Capabilities demonstrated

- Native Semantic Views and Cortex Analyst for governed retail metrics.
- Cortex Search across reviews, support cases, product guidance, and policies.
- Cortex Agent orchestration in Snowflake CoWork.
- Data-to-Chart visualizations.
- Synthetic POS-event simulation with Snowflake SQL procedures.
- Approval-gated inventory-transfer requests stored inside Snowflake.
- Verified questions and domain-specific semantic instructions.
- Dedicated X-Small warehouse, resource monitor, Agent resource budget, and usage views.
- A structured-data fallback Agent if Cortex Search is unavailable.

## Trial-account compatibility

This repository is designed for a student trial with synthetic data. AI must be enabled, the selected region must support the required features directly or through permitted cross-region inference, and the runtime role must receive Cortex privileges.

No external POS, ERP, competitor-pricing, weather, or fulfillment API is required. New transactions and inventory movement are simulated inside Snowflake. Do not upload real customer-identifying data into a personal trial.

## Architecture

```text
Synthetic POS + inventory + promotions + reviews
                    |
          governed tables and views
                    |
        +-----------+-----------+
        |                       |
  Semantic Views           Cortex Search
  sales/inventory/CX       reviews/cases/policies
        |                       |
        +---------- Cortex Agent -----+
                    |
             Snowflake CoWork
                    |
   answer + chart + evidence + approval request
                    |
            RETAIL_ACTION_QUEUE
```

## Installation order

1. `sql/00_preflight.sql`
2. `sql/01_account_setup.sql`
3. `sql/02_credit_control.sql`
4. `sql/03_tables.sql`
5. `sql/04_sample_data.sql`
6. `sql/05_analytics.sql`
7. `sql/06_semantic_views.sql`
8. Optional: `sql/07_cortex_search.sql`
9. `sql/08_simulation_tools.sql`
10. Full mode: `sql/09_agent.sql`; fallback: `sql/09b_agent_without_search.sql`
11. Optional: `sql/09c_agent_resource_budget.sql`
12. `sql/10_validation.sql`

Fixed object names:

- Database: `RETAILPULSE_AI`
- Warehouse: `RETAILPULSE_DEMO_WH`
- Role: `RETAILPULSE_DEMO_ROLE`
- Agent: `RETAILPULSE_AI.AGENT.RETAILPULSE_AGENT`

## Suggested CoWork questions

1. Which promoted products are at risk of stocking out in the next seven days? Chart revenue at risk by category.
2. For product `PRD-0042`, which stores are at risk and which stores have transferable excess inventory?
3. Why is the return rate high for `PRD-0042`? Include review and support-case evidence.
4. Compare promotion uplift and margin by region and category.
5. Create an inventory-transfer review for `PRD-0042` from `STR-003` to `STR-011` for 20 units.

## Live simulation

```sql
CALL RETAILPULSE_AI.AGENT.SIMULATE_POS_EVENTS(50);
```

The procedure inserts synthetic sales and reduces store inventory. Ask the stockout question again to demonstrate changed results.

## Credit controls

- `02_credit_control.sql` controls warehouse compute and exposes cost views.
- `09c_agent_resource_budget.sql` applies a separate monthly budget to the Cortex Agent.
- Cortex Search and AI functions are serverless and require separate budgets/monitoring; a warehouse monitor does not stop them.

## Productionization

Replace the simulator with approved POS, e-commerce, ERP, WMS, and replenishment feeds. Connect approved transfer requests to the inventory-management platform through an external integration. Add row-access policies, masking, formal metric ownership, environment promotion, automated evaluations, and human approval before any operational action.

## Cleanup

`sql/99_cleanup.sql` removes all RetailPulse objects. It is destructive.
