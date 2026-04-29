# Workoflow Hosting

Shared infrastructure for the Workoflow ecosystem (Docker Compose).

## CRITICAL: Integration platform uses docker-compose-prod.yml

```bash
# CORRECT — external volumes with production data
docker-compose -f docker-compose-prod.yml <command>

# WRONG — creates new volumes, loses data!
docker-compose <command>
```

## Production Server Access

```bash
ssh val-workoflow-prod
sudo -iu docker
cd /home/docker/docker-setups/n8n
```

## Key Services

| Service | Port | Purpose |
|---------|------|---------|
| LiteLLM | 4000 | LLM proxy gateway |
| Qdrant | 6333 | Vector database |
| PostgreSQL | 5432 | Main database |
| Redis | 6381 | Cache/queue |
| Phoenix | 6006 | Observability/tracing |
| RustFS | 9004/9007 | KB document storage |
| Docling | 5001 | Document parsing |
| Crawl4AI | 11235 | Web crawling |
| SearXNG | 8090 | Web search |
| Tika | 9998 | Text extraction |
| Gotenberg | 3002 | PDF conversion |

## Essential Commands

```bash
docker compose up -d                    # Start all
docker compose restart <service>        # Restart one
docker compose logs -f <service>        # View logs
docker compose logs --since 1h <svc>    # Recent logs
docker stats --no-stream                # Resource usage
cat litellm_config.yaml                 # LiteLLM config
```

## LiteLLM Configuration

Config file: `litellm_config.yaml`
- `router_settings.timeout`: 600s
- `router_settings.routing_strategy`: simple-shuffle

## Skills

Use `workoflow-skills` (`/add-dir ../workoflow-skills`) for: `architecture`, `deploy`, `check-prod`, `check-stage`, `dev-setup`
