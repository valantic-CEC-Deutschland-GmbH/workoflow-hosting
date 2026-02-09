# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## 2026-02-09

### Changed
- Removed `gpt-4o` model aliases — all traffic now routes through `gpt-4.1` deployments only
- Fixed OpenAI deployment model from `openai/gpt-4o` to `openai/gpt-4.1`

### Added
- Redis response caching for LiteLLM (1h TTL)
  - Cached call types: `atext_completion`, `aembedding`, `atranscription`
  - `acompletion` (chat completions) intentionally excluded — LiteLLM cache keys don't include `tools`/`functions`, which risks cross-user response leakage in multi-tenant agent workflows
- `docs/litellm-guide.md` — comprehensive LiteLLM documentation covering architecture, configuration, and operational commands
- `store_model_in_db: true` — enables managing model configurations via LiteLLM UI
- `store_prompts_in_spend_logs: true` — logs prompts in spend logs for cost analysis and debugging

## 2026-01-30

### Changed
- Repository moved to official valantic organization: valantic-CEC-Deutschland-GmbH
- Added proprietary license — usage requires a valid commercial license from valantic CEC Deutschland GmbH

## 2026-01-26

### Changed
- LiteLLM failover settings for automatic provider switching
  - `allowed_fails: 1` - mark deployment unhealthy after 1 failure
  - `cooldown_time: 60` - keep failed deployment out of rotation for 60s
  - `retry_after: 0` - retry immediately on different deployment

### Fixed
- Deploy script now uses `git fetch + reset` to handle force pushes

## 2025-12-12

### Fixed
- LiteLLM request timeout increased from 30s to 600s for AI agent workflows
- Switched LiteLLM routing strategy from `usage-based-routing` to `simple-shuffle`
  - Fixes `'NoneType' object has no attribute 'get'` errors in router

### Added
- `CLAUDE.md` with deployment workflow and production server access documentation
- OpenAI API key template in `.env.prod` for model rotation fallback

## 2025-12-10

### Changed
- LiteLLM now uses dedicated PostgreSQL and Redis services
  - Added `litellm-postgres` service (PostgreSQL 17.5-alpine)
  - Added `litellm-redis` service (Redis 8.0.1)
  - New volumes: `litellm-postgres-data`, `litellm-redis-data`
  - Isolated from n8n's shared database and cache
- Replaced Bifrost with LiteLLM Proxy for LLM gateway
  - Migrated from `maximhq/bifrost:latest` to `ghcr.io/berriai/litellm:main-latest`
  - New endpoint: port 4000 (previously 8080)
  - Added `litellm_config.yaml` for model and router configuration
  - Supports 100+ LLM providers with built-in load balancing
  - Virtual key management for per-user tracking and budget limits
  - Phoenix OpenInference tracing for evaluations (previously OTEL GenAI only)
  - Usage-based routing strategy with Redis for distributed rate limiting

### Added
- LiteLLM environment variables
  - `LITELLM_MASTER_KEY` for admin authentication
  - `LITELLM_SALT_KEY` for API credential encryption
  - `LITELLM_DATABASE_URL` for virtual key storage (uses existing PostgreSQL)
- Template for multi-Azure subscription scaling in config

## 2025-12-04

### Added
- n8n v2.0 external task runner preparation
  - Added `n8n-runner` sidecar container for main n8n instance
  - Added `n8n-worker-runner` sidecar container for worker instance
  - Configured broker listen address in x-n8n-shared anchor
  - Uses `n8nio/runners:latest` image with healthchecks
- ~~Bifrost LLM gateway for centralized AI provider management~~ (replaced by LiteLLM on 2025-12-10)
  - ~~Added `bifrost` service with `maximhq/bifrost:latest` image~~
  - ~~Supports Azure OpenAI, OpenAI, and Anthropic providers with fallback~~
  - ~~OpenTelemetry integration for tracing to Phoenix~~
  - ~~Web UI available on port 8080 for provider configuration~~

## 2025-10-27

### Added
- Automated deployment script for staging and production environments
  - `./scripts/deploy.sh` script for automated server deployments
  - Supports both `prod` and `stage` environments
  - VPN connectivity checks before deployment
  - Automated git pull and setup script execution on remote servers

## 2025-10-23

### Changed
- Added n8n environment variables to fix deprecation warnings
  - `OFFLOAD_MANUAL_EXECUTIONS_TO_WORKERS=true` for worker execution offloading
  - `N8N_BLOCK_ENV_ACCESS_IN_NODE=false` to maintain env access in Code nodes
  - `N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS=true` for automatic permission fixes

## 2025-10-14
