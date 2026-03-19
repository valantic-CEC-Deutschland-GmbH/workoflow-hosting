<p align="center">
  <img src="assets/logo_orig_large.png" alt="Workoflow Bot Logo" width="360px">
</p>

# Concept
Provide self-hosted infrastructure for AI driven communication.
AI agents are serving as a bridge between the two.

# Privacy
General Data Protection Regulation (GDPR) (EU Datenschutzgrundverordnung EDGVO) law production ready setup.
Minimized risk in leaking any company data, only EU services involved.
ALl cloud services are ISO 27001, ISO 27018, BSI C5 certified.

# Services OnPremise
 - n8n (http://localhost:5678/)
 - qdrant (http://localhost:6333/dashboard)
 - minio (http://localhost:9001/)
 - redis (http://localhost:6379/)
 - postgres (jdbc 5432)
 - workoflow-bot (https://github.com/valantic-CEC-Deutschland-GmbH/workoflow-bot)

# Services Cloud
 - MS Teams (https://admin.teams.microsoft.com/)
 - Azure-Bot Service (https://azure.microsoft.com/de-de/products/ai-services/ai-bot-service)
 - self deployed AI (https://ai.azure.com/)

# DevOps Setup
 - Host Workoflow BOT (nodejs)
 - Setup Cloud Services
   - create azure bot https://portal.azure.com/
     - configure message endpoint
     - in channels, add teams
   - create teams app and copy App ID https://dev.teams.microsoft.com/apps
 - upload and register your "Workoflow Bot" to MS Teams https://admin.teams.microsoft.com/policies/manage-apps

# Local Development Proxy Workoflow-Bot to Azusre
 - npm run watch
 - ngrok http --host-header=rewrite http://localhost:3978
 - add ngrok url to your Azure bot message endpoint
   - open https://portal.azure.com/#@nxs.rocks/resource/subscriptions/9e0780af-a98b-4867-9788-2262bfa387f8/resourceGroups/GenesisHorizonRG/providers/Microsoft.BotService/botServices/GenesisHorizon/config
   - https://8c67-80-246-113-44.ngrok-free.app/api/messages

# SSH access hosting
 - cat ~/.ssh/config

Host val-*
User xxx.xxx
ForwardAgent yes

Host val-srv-nc-heimdall
Hostname hosting.vcec.cloud

Host val-n8n
Hostname xxxx.xxx.xxx.xxx
ProxyJump xxxx-xxxx-xxx-xxxx

 - ssh val-n8n
 - patrick.xxxx@morris:~$ sudo -iu docker
 - cd /home/docker/docker-setups/n8n

# Port Service tunneling
 - ssh -L 5678:localhost:5678 -L 5432:localhost:5432 -L 6333:localhost:6333 -L 9000:localhost:9000 -L 9001:localhost:9001 -L 6379:localhost:6379 val-n8n

# qdrant collection create and delete
curl -X DELETE "http://localhost:6333/collections/workoflow_content_graph"

curl -X PUT "http://localhost:6333/collections/workoflow_user_uploads_vector_n8n" \
-H "Content-Type: application/json" \
--data-raw '{
"vectors": {
"size": 3072,
"distance": "Cosine"
}
}'

# Generate new n8n user
 - $htpasswd -nbBC 12 "" your-password | tr -d ':\n'
 - clone entry in table user, set generated pw
 - clone entry in project_relation, set generated user.id, copy existing projectId

# crontab entries
## automated updates
 - 0 3 * * * cd /home/docker/docker-setups/n8n && docker-compose pull && docker-compose up -d --remove-orphans
## backups
 - 0 2 * * * docker exec -u root -it n8n-n8n-1 sh -c "n8n export:credentials --all --output=/home/backups/credentails.json"
 - 0 2 * * * docker exec -u root -it n8n-n8n-1 sh -c "n8n export:workflow --all --output=/home/backups/workflows.json"
