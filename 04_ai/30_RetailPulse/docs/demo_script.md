# RetailPulse AI — 15-minute client demo

## The story

A regional retailer is promoting the Apex Barista Pro coffee machine. Demand is accelerating at several stores, one store has excess inventory, and customers are reporting reservoir leaks and setup confusion. RetailPulse AI connects governed metrics with unstructured evidence and turns the result into a controlled, human-approved action.

## 0-2 minutes: frame the business problem

“The merchandising team normally switches between POS dashboards, inventory reports, returns data, customer reviews, and support tickets. We will ask one governed Snowflake Agent to investigate the issue and prepare an action without moving inventory automatically.”

Show the three composable Semantic Views:

- `RETAIL_SALES_SV` — revenue, margin, promotions, channel, store, product.
- `INVENTORY_SUPPLY_SV` — velocity, days of supply, stockout risk, excess, transfer need.
- `CUSTOMER_PRODUCT_SV` — returns, refunds, ratings, and quality signals.

## 2-5 minutes: identify risk

Ask:

> Which stores are at risk of stocking out of PRD-0042 in the next seven days, and how much revenue is exposed?

Then ask:

> Chart available inventory versus seven-day required quantity for those stores.

Call out that the answer is generated through governed semantic definitions, not unrestricted table exploration.

## 5-8 minutes: connect commercial and customer evidence

Ask:

> Is the weekend home promotion helping sales and margin for PRD-0042? Compare promoted and non-promoted performance.

Then:

> Why are returns elevated for this product? Combine return metrics with reviews, support cases, and product guidance. Separate evidence from hypotheses.
>
> The promotion dates are tied to the day you ran 04, so they will drift. Before any client demo, re-run 04 and then 05 so the “active promotion” window is current.

The Agent should combine Cortex Analyst results with Cortex Search evidence about reservoir leakage and setup confusion. If Search is unavailable, use the structured product-experience metrics and show the SQL fallback document view.

## 8-11 minutes: recommend an inventory move

Ask:

> Find a store with safe excess inventory of PRD-0042 and recommend a transfer to the highest-risk store. Show the quantity, donor-store safety, and estimated protected revenue.

The recommendation is calculated from demand velocity, safety stock, available inventory, and seven-day need.

## 11-13 minutes: demonstrate the approval boundary

Ask:

> Create the recommended transfer request, but do not execute an inventory movement.

The generic tool validates both stores, caps the quantity to source excess and destination need, and writes only a `PENDING_APPROVAL` row. Show:

```sql
SELECT *
FROM RETAILPULSE_AI.DATA.RETAIL_ACTION_QUEUE
ORDER BY REQUESTED_AT DESC;
```

Emphasize that the Agent proposes and records; a human or downstream workflow approves.

## 13-15 minutes: make it feel live and show governance

Generate a controlled POS burst:

```sql
CALL RETAILPULSE_AI.AGENT.SIMULATE_POS_EVENTS(50);
```

Refresh the risk question and show that the analytical layer responds to new transactions. Finish with the X-Small auto-suspend warehouse, resource monitor, optional Agent budget, role grants, and GitHub deployment workflow.

## Strong follow-up prompts

- “Which categories have declining margin even though revenue increased?”
- “Which products combine high return rates and negative customer evidence?”
- “Show promotion lift by region and channel.”
- “Explain exactly how the stockout-risk and protected-revenue estimates are calculated.”
- “What evidence would we still need before changing the product or supplier?”

## Demo guardrails

- Describe revenue exposure and protected revenue as estimates.
- Do not present correlated complaints as a proven product defect.
- Do not claim a transfer occurred; the included tool creates a request only.
- Avoid exposing customer PII; the synthetic dataset intentionally contains none.
