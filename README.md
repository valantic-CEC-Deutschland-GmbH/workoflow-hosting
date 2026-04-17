<p align="center">
  <img src="assets/logo_orig_large.png" alt="Workoflow Bot Logo" width="360px">
</p>

# Workoflow Hosting

Self-hosted infrastructure for AI-driven communication. AI agents act as the bridge between internal systems and cloud services.

## Privacy

This setup is designed for GDPR-ready operation with a minimized risk of leaking company data.

- Only EU-based services are involved.
- Cloud services are ISO 27001, ISO 27018, and BSI C5 certified.

## On-Premise Services

- `n8n`: http://localhost:5678/
- `qdrant`: http://localhost:6333/dashboard
- `minio`: http://localhost:9001/
- `redis`: http://localhost:6379/
- `postgres`: `jdbc:5432`
- `workoflow-bot`: https://github.com/valantic-CEC-Deutschland-GmbH/workoflow-bot

## Cloud Services

- `MS Teams`: https://admin.teams.microsoft.com/
- `Azure Bot Service`: https://azure.microsoft.com/de-de/products/ai-services/ai-bot-service
- `Azure AI`: https://ai.azure.com/

## DevOps Setup

1. Host the Workoflow Bot (`nodejs`).
2. Set up the cloud services.
3. Upload and register the Workoflow Bot in MS Teams.

### Azure And Teams Setup

1. Create an Azure Bot in the Azure portal: https://portal.azure.com/
2. Configure the message endpoint.
3. In Channels, add Microsoft Teams.
4. Create a Teams app and copy the App ID: https://dev.teams.microsoft.com/apps
5. Upload and register the Workoflow Bot in Teams:
   https://admin.teams.microsoft.com/policies/manage-apps

## Local Development Proxy

Use this flow to connect a local `workoflow-bot` instance to Azure.

```bash
npm run watch
ngrok http --host-header=rewrite http://localhost:3978
```

Add the generated ngrok URL to the Azure bot message endpoint.

- Azure bot config:
  https://portal.azure.com/#@nxs.rocks/resource/subscriptions/9e0780af-a98b-4867-9788-2262bfa387f8/resourceGroups/GenesisHorizonRG/providers/Microsoft.BotService/botServices/GenesisHorizon/config
- Example endpoint:
  `https://8c67-80-246-113-44.ngrok-free.app/api/messages`

## SSH Access

Inspect your SSH config:

```bash
cat ~/.ssh/config
```

Example configuration:

```sshconfig
Host val-*
  User xxx.xxx
  ForwardAgent yes

Host val-srv-nc-heimdall
  HostName hosting.vcec.cloud

Host val-n8n
  HostName xxxx.xxx.xxx.xxx
  ProxyJump xxxx-xxxx-xxx-xxxx
```

Connect to the host:

```bash
ssh val-n8n
sudo -iu docker
cd /home/docker/docker-setups/n8n
```

## Port Tunneling

```bash
ssh -L 5678:localhost:5678 \
  -L 5432:localhost:5432 \
  -L 6333:localhost:6333 \
  -L 9000:localhost:9000 \
  -L 9001:localhost:9001 \
  -L 6379:localhost:6379 \
  val-n8n
```

## Qdrant Collections

Delete a collection:

```bash
curl -X DELETE "http://localhost:6333/collections/workoflow_content_graph"
```

Create a collection:

```bash
curl -X PUT "http://localhost:6333/collections/workoflow_user_uploads_vector_n8n" \
  -H "Content-Type: application/json" \
  --data-raw '{
    "vectors": {
      "size": 3072,
      "distance": "Cosine"
    }
  }'
```

## Generate A New n8n User

Generate a password hash:

```bash
htpasswd -nbBC 12 "" your-password | tr -d ':\n'
```

Then:

1. Clone an existing entry in the `user` table and set the generated password hash.
2. Clone the corresponding entry in `project_relation`.
3. Set the new `user.id` and reuse the existing `projectId`.

## Crontab Entries

### Automated Updates

```cron
0 3 * * * cd /home/docker/docker-setups/n8n && docker-compose pull && docker-compose up -d --remove-orphans
```

### Backups

```cron
0 2 * * * docker exec -u root -it n8n-n8n-1 sh -c "n8n export:credentials --all --output=/home/backups/credentails.json"
0 2 * * * docker exec -u root -it n8n-n8n-1 sh -c "n8n export:workflow --all --output=/home/backups/workflows.json"
```
