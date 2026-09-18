# Deploy Guide — WhatsApp Insurance Agent

Este documento descreve como provisionar a infraestrutura e subir a stack base do
WhatsApp Insurance Agent em uma nova VM OCI.

> **Escopo**
>
> Este runbook cobre o estado atual validado do projeto:
> Terraform → OCI VM → Docker → PostgreSQL/pgvector → Redis → Evolution API → n8n.
>
> Configuração do fluxo de negócio, agente de IA, webhook funcional do WhatsApp,
> domínio público e HTTPS são etapas posteriores.

## 1. Arquitetura

```text
OCI
└── VM.Standard.A1.Flex — ARM64
    └── Docker Compose
        ├── Evolution API ──────► n8n
        │                          │
        ├── Redis ◄────────────────┘
        │
        └── PostgreSQL + pgvector
            ├── n8n
            └── evolution
```

A comunicação Evolution API → n8n ocorre pela rede interna do Docker.

## 2. Pré-requisitos

No ambiente administrativo:

- Git
- Terraform
- OCI CLI/configuração de acesso à OCI
- chave SSH para a VM
- acesso ao repositório GitHub

O GitHub Codespaces pode ser usado para administração. A aplicação roda na VM.

## 3. Estrutura

```text
whatsapp-insurance-agent/
├── docker/
│   ├── docker-compose.yml
│   ├── .env.example
│   └── init-multi-db.sh
├── n8n/
│   └── workflows/
└── terraform/
    ├── providers.tf
    ├── variables.tf
    ├── network.tf
    ├── compute.tf
    ├── cloud-init.yaml
    ├── outputs.tf
    └── terraform.tfvars.example
```

## 4. Terraform

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
```

Configure os parâmetros específicos da conta.

Configuração validada:

```hcl
region              = "sa-saopaulo-1"
availability_domain = "ykqV:SA-SAOPAULO-1-AD-1"

shape         = "VM.Standard.A1.Flex"
ocpus         = 2
memory_in_gbs = 12
```

Não versione `terraform.tfvars` se ele contiver OCIDs ou outros dados específicos
do ambiente.

Inicialize e valide:

```bash
terraform init
terraform validate
terraform plan
terraform apply
```

Depois:

```bash
terraform output
```

Os outputs relevantes são:

```text
instance_public_ip
n8n_url
evolution_api_url
ssh_command
```

> Os URLs de n8n/Evolution não significam que essas portas estejam acessíveis
> pela internet. Na configuração atual, a Security List libera apenas SSH.

## 5. Acesso SSH

```bash
ssh -i ~/.ssh/oci_vm_key ubuntu@<IP_DA_VM>
```

## 6. Validar a VM

```bash
uname -m
docker --version
docker compose version
cloud-init status --long
```

Esperado para a arquitetura:

```text
aarch64
```

## 7. Clonar o projeto

Na VM:

```bash
cd /home/ubuntu
git clone https://github.com/daniloof/whatsapp-insurance-agent.git
cd whatsapp-insurance-agent
```

Se já estiver clonado:

```bash
git pull
```

## 8. Configurar o ambiente

```bash
cp docker/.env.example docker/.env
nano docker/.env
```

Principais parâmetros:

```env
POSTGRES_USER=postgres
POSTGRES_PASSWORD=<SECRET>

EVOLUTION_API_KEY=<SECRET>
EVOLUTION_PUBLIC_URL=http://localhost:8080

N8N_HOST=localhost
N8N_PORT=5678
N8N_PROTOCOL=http
N8N_PUBLIC_URL=http://localhost:5678/

N8N_USER=<USER>
N8N_PASSWORD=<SECRET>

TZ=America/Sao_Paulo

LLM_API_KEY=<SECRET>
```

Proteja o arquivo:

```bash
chmod 600 docker/.env
```

Nunca commite o `.env`.

## 9. Gerar secrets

Para uma senha usada dentro de PostgreSQL connection URI, prefira:

```bash
openssl rand -hex 32
```

Isso evita problemas com caracteres especiais em URLs como:

```text
postgresql://usuario:senha@postgres:5432/evolution
```

## 10. Validar o Compose

```bash
docker compose config
```

Não publique o output desse comando: ele pode conter secrets interpolados.

## 11. Baixar imagens

```bash
docker compose pull
```

Stack atual:

```text
PostgreSQL + pgvector
Redis 7 Alpine
Evolution API v2.3.7
n8n
```

Evolution:

```yaml
image: evoapicloud/evolution-api:v2.3.7
```

## 12. Subir a stack

```bash
docker compose up -d
docker compose ps
```

Esperado:

```text
evolution-api   Up
n8n             Up
postgres        Up (healthy)
redis           Up
```

## 13. Troubleshooting

Se algum container reiniciar:

```bash
docker compose ps
docker logs evolution-api --tail 100
docker logs n8n --tail 100
docker logs postgres --tail 100
```

### Problema conhecido: Prisma P1013

Na primeira instalação, uma senha PostgreSQL gerada com `openssl rand -base64 32`
continha caracteres que quebraram a connection URI da Evolution.

Sintoma:

```text
Prisma P1013
```

Correção:

```bash
openssl rand -hex 32
```

Atualize `docker/.env`.

Em uma instalação nova, sem dados importantes:

```bash
docker compose down -v
docker compose up -d
```

> **ATENÇÃO:** `down -v` remove os volumes Docker do projeto. Não use em
> ambiente com dados que precisam ser preservados.

## 14. Testar PostgreSQL

```bash
docker compose ps
```

O PostgreSQL deve aparecer como:

```text
Up (healthy)
```

A inicialização cria os bancos:

```text
n8n
evolution
```

e habilita `vector` no banco Evolution.

## 15. Testar Redis

```bash
docker compose ps redis
```

O Redis deve estar `Up`.

Ele não precisa estar exposto publicamente.

## 16. Testar Evolution API

Na VM:

```bash
curl http://localhost:8080
```

Resultado esperado:

```json
{
  "status": 200,
  "message": "Welcome to the Evolution API, it is working!",
  "version": "2.3.7"
}
```

## 17. Testar n8n

```bash
curl http://localhost:5678
```

Deve retornar o HTML do n8n.

## 18. Testar Evolution → n8n

Teste principal:

```bash
docker exec evolution-api sh -c 'wget -qO- http://n8n:5678/healthz || true'
```

Resultado esperado:

```json
{"status":"ok"}
```

Também:

```bash
docker exec evolution-api sh -c 'wget -qO- http://n8n:5678/'
```

deve retornar o HTML do n8n.

Isso confirma:

1. resolução do serviço `n8n`;
2. rede interna Docker;
3. acesso HTTP da Evolution ao n8n.

## 19. Checkpoint — Infraestrutura validada

Quando os testes acima passarem:

```text
TERRAFORM             OK
OCI VM                OK
DOCKER                OK
POSTGRESQL/PGVECTOR   OK
REDIS                 OK
EVOLUTION API         OK
N8N                   OK
EVOLUTION → N8N       OK
```

Neste ponto, a infraestrutura base está operacional.

## 20. Ainda não coberto

As etapas seguintes ficam para a camada de aplicação/produção:

- domínio;
- HTTPS;
- reverse proxy;
- exposição externa segura do n8n;
- exposição externa segura da Evolution;
- criação da instância WhatsApp;
- QR Code/conexão WhatsApp;
- webhook `whatsapp-inbound`;
- workflow n8n;
- agente de IA;
- integração com LLM;
- memória/conversação;
- RAG e embeddings;
- regras de negócio;
- observabilidade;
- backup;
- hardening de produção.

## 21. Segurança

Não versione:

```text
docker/.env
*.pem
*.key
terraform.tfvars
```

Nunca publique:

```text
POSTGRES_PASSWORD
EVOLUTION_API_KEY
N8N_PASSWORD
LLM_API_KEY
OCI private key
SSH private key
```

Não abra desnecessariamente:

```text
5432 PostgreSQL
6379 Redis
5678 n8n
8080 Evolution
```

A configuração atual libera externamente apenas:

```text
TCP 22 — SSH
```

## 22. Deploy rápido

### Codespace / máquina administrativa

```bash
cd terraform
terraform init
terraform validate
terraform plan
terraform apply
terraform output
```

### VM

```bash
ssh -i ~/.ssh/oci_vm_key ubuntu@<IP>
```

```bash
cd /home/ubuntu
git clone https://github.com/daniloof/whatsapp-insurance-agent.git
cd whatsapp-insurance-agent

cp docker/.env.example docker/.env
nano docker/.env
chmod 600 docker/.env

docker compose pull
docker compose up -d
docker compose ps

curl http://localhost:8080
curl http://localhost:5678

docker exec evolution-api sh -c 'wget -qO- http://n8n:5678/healthz || true'
```

Se o último comando retornar:

```json
{"status":"ok"}
```

a infraestrutura base está validada.

## 23. Próximo checkpoint

Depois do deploy:

```text
WhatsApp
   ↓
Evolution API
   ↓
Webhook
   ↓
n8n
   ↓
Agente IA
```

A partir daí começa a construção do produto propriamente dito.
