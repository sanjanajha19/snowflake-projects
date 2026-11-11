# Credit controls and trial guidance

This project is intentionally small enough for a Snowflake trial demo, but AI and warehouse usage still consume credits. Trial eligibility, duration, included usage, feature availability, and regional support can change, so confirm the terms displayed during signup and run `00_preflight.sql` before deployment.

## Controls included in the repository

- An X-Small warehouse with 60-second auto-suspend and auto-resume.
- A 20-credit monthly warehouse resource monitor.
- Notifications at 50% and 75%, suspension at 90%, and immediate suspension at 100%.
- Statement timeout and queued-statement timeout limits.
- A procedure that suspends the demo warehouse immediately.
- Views for warehouse, Cortex Search, and Agent usage history.
- An optional Snowflake Budget scoped to the tagged Agent, with a five-credit monthly spending limit for monitoring and alerts.
- Agent orchestration limits for elapsed time and tokens.

## Important distinction

A resource monitor limits warehouse credit consumption. It does not cap every serverless or AI service. Cortex Search and Cortex Agents have separate consumption records. The optional budget helps monitor tagged Agent resources, but budgets alert rather than hard-stop usage. Keep both layers and inspect the usage views after rehearsals.

## Practical rehearsal policy

1. Run the core installer once.
2. Keep the Search target lag at one day for a static synthetic dataset.
3. Reuse the same Search service rather than recreating it before every demo.
4. Use short, specific Agent prompts and avoid needless repeated retries.
5. Suspend the warehouse after validation:

```sql
CALL RETAILPULSE_AI.GOVERNANCE.SUSPEND_DEMO_COMPUTE();
```

6. Inspect usage after the rehearsal. Account-usage views can have reporting latency.

## If a feature is unavailable

- If Cortex Search is unsupported in the account region, skip `07_cortex_search.sql` and deploy `09b_agent_without_search.sql`.
- The SQL fallback view still exposes synthetic reviews, support cases, guides, policies, and store notes for a manual demonstration.
- If Cortex Agents are not enabled, the Semantic Views, analytical views, simulation, and action queue remain usable directly in Snowsight.
- This project does not require External Access Integrations, Snowpark Container Services, Openflow, hybrid tables, or outbound third-party APIs.
