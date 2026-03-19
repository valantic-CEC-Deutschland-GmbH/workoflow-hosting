# CLAUDE.md - workoflow-hosting

## Workoflow Integration Platform (Production)

**CRITICAL**: The integration platform uses a separate prod compose file:
```bash
# Connect and deploy
ssh val-workoflow-prod
sudo -iu docker
cd /home/docker/docker-setups/workoflow-integration-platform

# ALWAYS use docker-compose-prod.yml for production!
docker-compose -f docker-compose-prod.yml up -d
docker-compose -f docker-compose-prod.yml restart frankenphp

# NEVER use plain docker-compose commands - they create new volumes and lose data!
# docker-compose up -d  # WRONG!
```

The `docker-compose-prod.yml` uses `external: true` volumes that reference existing production data. Using the default `docker-compose.yml` creates new prefixed volumes and disconnects from production data.

## Deployment Workflow

**Always apply changes locally first, then pull on remote:**

1. Edit files locally
2. `git add <files> && git commit -m "message" && git push`
3. SSH to prod and pull changes
4. Restart affected containers

## Production Server Access

```bash
# Connect to prod server
ssh val-workoflow-prod

# Switch to docker user
sudo -iu docker

# Navigate to project directory
cd /home/docker/docker-setups/n8n

# Pull latest changes
git pull

# Restart specific container
docker compose restart <service-name>

# Or restart all
docker compose up -d
```

## One-liner for deployment

```bash
ssh val-workoflow-prod "sudo -iu docker bash -c 'cd /home/docker/docker-setups/n8n && git pull && docker compose restart <service-name>'"
```

## Key Services

| Service | Port | Description |
|---------|------|-------------|
| litellm | 4000 | LLM proxy gateway |
| n8n | 5678 | Workflow automation |
| qdrant | 6333 | Vector database |
| postgres | 5432 | Main database |
| redis | 6379 | Cache/queue |
| phoenix | 6006 | Observability/tracing |

## Useful Commands

```bash
# Check container status
docker ps | grep <service>

# View logs
docker compose logs <service> --tail 100

# View logs with timestamp filter
docker compose logs <service> --since 1h

# Check config file
cat litellm_config.yaml
```

## LiteLLM Configuration

Config file: `litellm_config.yaml`

Key settings:
- `router_settings.timeout`: Request timeout in seconds (currently 600s)
- `router_settings.routing_strategy`: Load balancing strategy (currently simple-shuffle)
- `router_settings.num_retries`: Number of retry attempts
