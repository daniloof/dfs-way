# WhatsApp Insurance Agent

Agente de IA via WhatsApp para coleta de informações de seguro.

## Stack
- **Evolution API** — integração com WhatsApp
- **N8N** — orquestração do fluxo de conversa
- **PostgreSQL + pgvector** — persistência e busca semântica
- **Redis** — cache do Evolution API
- **Terraform** — provisionamento da VM (OCI Always Free — Ampere A1)

## Estrutura
- `docker/` — stack de aplicação (docker-compose)
- `terraform/` — infraestrutura (VM, rede, firewall)
- `n8n/workflows/` — workflows exportados do N8N (versionados como JSON)

## Como subir

### 1. Provisionar a VM
```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# preencha terraform.tfvars com seus dados da OCI
terraform init
terraform apply
```

### 2. Subir a stack na VM
```bash
scp -r ../docker ubuntu@<IP_DA_VM>:~/whatsapp-agent
ssh ubuntu@<IP_DA_VM>
cd ~/whatsapp-agent/docker
cp .env.example .env
# preencha .env com suas chaves/senhas
docker compose up -d
```

### 3. Configurar
- Evolution API: `http://<IP_DA_VM>:8080` — escaneie o QR code para conectar o WhatsApp
- N8N: `http://<IP_DA_VM>:5678` — monte o workflow que recebe o webhook em `/webhook/whatsapp-inbound`
