# LiteLLM Guide — What It Is & How It's Used in Workoflow

## What is LiteLLM?

LiteLLM is an **LLM Gateway / Proxy Server**. Think of it as a reverse proxy (like nginx) but specifically for LLM API calls. Instead of your applications calling OpenAI, Azure, Anthropic, etc. directly, they all call LiteLLM on a single endpoint, and LiteLLM routes the request to the right provider behind the scenes.

It exposes an **OpenAI-compatible API** on port `4000`, so any tool that can talk to OpenAI can talk to LiteLLM without code changes — you just point the base URL to `http://litellm:4000`.

## Why Use It? (The Problem It Solves)

Without LiteLLM, every service that needs an LLM would need:
- Its own API key configuration per provider
- Its own retry/fallback logic
- Its own rate limit handling
- No centralized cost tracking

With LiteLLM, you get **one gateway** that handles all of that centrally.

## Key Benefits

| Benefit | How It Helps You |
|---------|-----------------|
| **Unified API** | All services call one endpoint (`litellm:4000`). Swap providers without touching consumers. |
| **Load Balancing** | Your `gpt-4.1` model name routes to *both* Azure OpenAI and OpenAI. If one is slow/down, traffic shifts. |
| **Automatic Failover** | If Azure hits a rate limit, LiteLLM retries on OpenAI (3 retries, 60s cooldown). |
| **Cost Tracking** | Every request is logged with token counts and cost. Query spend per key, team, or model. |
| **Virtual Keys** | Generate API keys for different consumers (n8n, bot, etc.) with per-key budgets and rate limits. |
| **Observability** | Integrated with Phoenix for tracing every LLM call — latency, tokens, cost, errors. |
| **Rate Limiting** | Centralized RPM/TPM limits prevent runaway costs from any single consumer. |

## How It's Integrated in Workoflow

```
 Teams Bot --> Integration Platform --> n8n Workflows --> LiteLLM --> Azure / OpenAI
                                              |                |
                                              |          +-----+------+
                                              |          | PostgreSQL | (keys, spend)
                                              |          | Redis      | (cache, routing)
                                              |          | Phoenix    | (tracing)
                                              |          +------------+
                                              |
                                         Uses credential:
                                         "azure-open-ai-proxy"
                                         pointing to litellm:4000
```

**The flow:**
1. A user sends a message in Teams
2. The bot triggers n8n workflows (Jira agent, Confluence agent, etc.)
3. Each n8n workflow uses an "Azure OpenAI" credential that actually points to LiteLLM (`litellm:4000`)
4. LiteLLM load-balances between Azure OpenAI and OpenAI, handles retries, logs the call to Phoenix

## Current Configuration

**File:** `litellm_config.yaml`

```
Models defined:
└── gpt-4.1  -> Azure OpenAI (60 RPM, 80K TPM) + OpenAI (500 RPM, 150K TPM)

Router:
├── Strategy: simple-shuffle (round-robin across providers)
├── Retries: 3
├── Timeout: 600s (long, for agent workflows that chain multiple tool calls)
├── Failover: mark unhealthy after 1 failure, cooldown 60s
├── Caching: Redis (TTL 1h, embeddings + transcriptions only — completions excluded for multi-tenant safety)
└── Tracing: Arize Phoenix (success_callback)
```

**Supporting services** (all in `docker-compose.yaml`):
- `litellm-postgres` — stores virtual keys, spend data, team configs
- `litellm-redis` — response caching (1h TTL) and routing state
- `phoenix` — traces every LLM call for debugging and cost analysis

## Accessing the Admin UI

LiteLLM ships with a web UI at `http://localhost:4000/ui`. Log in with the master key from your `.env` (`LITELLM_MASTER_KEY`). From there you can:
- Create/manage virtual keys
- View spend dashboards
- See model health and error rates
- Manage teams and budgets

## Useful Additional Configuration

Things not currently in use that would add value:

### 1. ~~Response Caching (Redis)~~ — ACTIVE

Response caching is enabled in `litellm_config.yaml` with Redis and a 1-hour TTL.

**Cached call types:** `atext_completion`, `aembedding`, `atranscription`

**Why `acompletion` (chat completions) is excluded:** LiteLLM's cache key does not include the `tools`/`functions` parameter. In our multi-tenant setup, different users have user-specific tool definitions (unique URLs, tool IDs) injected by the integration platform. If chat completions were cached, two requests with identical messages but different tools could return a cached response containing tool calls referencing the wrong user's tool IDs — a cross-user data leakage risk. Since agent conversations are inherently unique (tool results differ per turn/user), the cache hit rate for completions is negligible anyway. Embeddings and transcriptions remain safely cached as they are deterministic operations on specific input content.

### 2. Per-Key Budgets

Create separate virtual keys for each n8n workflow/agent with budget caps:

```bash
# Create a key with $50/month budget
curl -X POST 'http://localhost:4000/key/generate' \
  -H 'Authorization: Bearer <MASTER_KEY>' \
  -H 'Content-Type: application/json' \
  -d '{
    "models": ["gpt-4.1"],
    "max_budget": 50,
    "budget_duration": "30d",
    "key_alias": "jira-agent"
  }'
```

This prevents a single misbehaving agent from burning through your entire budget.

### 3. Add Fallback Models (Cheaper Alternatives)

Add a cheaper model as a fallback when primary models are rate-limited:

```yaml
# Add to model_list in litellm_config.yaml
- model_name: gpt-4.1-mini
  litellm_params:
    model: azure/gpt-4.1-mini
    api_base: os.environ/AZURE_OPENAI_ENDPOINT
    api_key: os.environ/AZURE_OPENAI_API_KEY
    api_version: os.environ/AZURE_OPENAI_API_VERSION

# Then add fallback routing
router_settings:
  model_group_alias:
    gpt-4.1:
      model: gpt-4.1
      hidden: false
  fallbacks:
    - gpt-4.1: ["gpt-4.1-mini"]
```

### 4. Guardrails / Content Moderation

LiteLLM supports pre-request guardrails to block prompt injection or inappropriate content before it reaches the LLM:

```yaml
litellm_settings:
  guardrails:
    - prompt_injection:
        callbacks: [lakera_prompt_injection]
        default_on: true
```

### 5. Request Tagging for Better Spend Analysis

Pass metadata from n8n to track spend per workflow:

```yaml
litellm_settings:
  allow_user_auth: true  # allow passing user/team metadata
```

Then in n8n, add headers like `x-litellm-metadata: {"user": "jira-agent"}` to attribute costs per agent.

### 6. Add Anthropic Models

Add Claude models as additional options:

```yaml
- model_name: claude-sonnet
  litellm_params:
    model: anthropic/claude-sonnet-4-5-20250929
    api_key: os.environ/ANTHROPIC_API_KEY
    rpm: 50
    tpm: 100000
```

## Quick Reference Commands

```bash
# Check LiteLLM health
curl http://localhost:4000/health

# List available models
curl http://localhost:4000/v1/models -H "Authorization: Bearer $LITELLM_MASTER_KEY"

# Check spend for a key
curl http://localhost:4000/key/info?key=sk-... -H "Authorization: Bearer $LITELLM_MASTER_KEY"

# View logs (from project root)
docker compose logs litellm --tail 100

# Restart after config change
docker compose restart litellm
```

## TL;DR

LiteLLM is the **centralized LLM traffic controller**. All n8n agents talk to it instead of directly to OpenAI/Azure. It gives you load balancing between providers, automatic failover, cost tracking, and a single place to manage API keys — instead of scattering that across every service.
