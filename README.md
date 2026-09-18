# WhatsApp Insurance Agent

AI agent for insurance customer service through WhatsApp.

The project is being built around a modular architecture where WhatsApp messaging,
workflow orchestration, AI capabilities and persistent data are separated into
independent components.

## Architecture

```text
                         WhatsApp
                            │
                            ▼
                    ┌─────────────────┐
                    │  Evolution API  │
                    │ WhatsApp Adapter │
                    └────────┬────────┘
                             │
                             ▼
                    ┌─────────────────┐
                    │      n8n        │
                    │  Orchestration  │
                    └────────┬────────┘
                             │
                 ┌───────────┼───────────┐
                 │           │           │
                 ▼           ▼           ▼
             PostgreSQL    Redis       LLM
             + pgvector
                 │
                 ▼
             AI Agent / RAG
```

### Components

| Component | Responsibility |
|---|---|
| **Evolution API** | WhatsApp integration and message adapter |
| **n8n** | Workflow orchestration |
| **PostgreSQL** | Persistent application/workflow data |
| **pgvector** | Vector storage for semantic search/RAG |
| **Redis** | Cache and supporting state |
| **LLM** | Natural-language understanding and generation |
| **Terraform** | Infrastructure as Code |
| **Docker Compose** | Local/server service orchestration |
| **OCI** | Cloud infrastructure |

The WhatsApp adapter is intentionally kept separate from the agent logic. This
makes it possible to replace Evolution API with another WhatsApp provider later,
such as the Meta WhatsApp Cloud API, without redesigning the agent itself.

---

# Project Status

## Infrastructure

The base infrastructure has been provisioned and validated on Oracle Cloud
Infrastructure.

```text
Terraform                 OK
OCI VM                    OK
ARM64                     OK
Docker                    OK
Docker Compose             OK
PostgreSQL + pgvector      OK
Redis                     OK
Evolution API              OK
n8n                        OK
Evolution → n8n            OK
```

The current validated VM uses:

```text
Shape:       VM.Standard.A1.Flex
OCPUs:       2
Memory:      12 GB
Architecture: ARM64
Region:      sa-saopaulo-1
```

## Application

The following layers are still under development:

```text
WhatsApp
   ↓
Evolution API
   ↓
Webhook
   ↓
n8n
   ↓
AI Agent
   ↓
LLM
   ↓
RAG / Database
   ↓
Response
```

---

# Repository Structure

```text
whatsapp-insurance-agent/
│
├── docker/
│   ├── docker-compose.yml
│   ├── .env.example
│   └── init-multi-db.sh
│
├── n8n/
│   └── workflows/
│
├── terraform/
│   ├── providers.tf
│   ├── variables.tf
│   ├── network.tf
│   ├── compute.tf
│   ├── cloud-init.yaml
│   ├── outputs.tf
│   └── terraform.tfvars.example
│
├── DEPLOY.md
└── README.md
```

## Directory responsibilities

### `terraform/`

Infrastructure as Code.

Responsible for provisioning the OCI environment, including the network and
compute resources.

### `docker/`

Runtime infrastructure.

Contains the Docker Compose stack, environment template and PostgreSQL
multi-database initialization script.

### `n8n/`

Workflow definitions.

This directory will contain the n8n workflows used to orchestrate WhatsApp
messages, AI processing and business rules.

### `DEPLOY.md`

Detailed deployment runbook for installing the project on a new OCI VM.

---

# Infrastructure

The current deployment uses Oracle Cloud Infrastructure.

The VM is an ARM64 `VM.Standard.A1.Flex` instance.

Terraform creates the base infrastructure and cloud-init prepares the operating
system with Docker and Docker Compose.

```text
Terraform
    │
    ▼
OCI
    │
    ├── VCN
    ├── Subnet
    ├── Internet Gateway
    ├── Route Table
    ├── Security List
    │      └── TCP 22
    │
    └── VM
          └── Docker
```

The current network configuration does not expose the application ports directly
to the public internet.

The internal services communicate through the Docker network.

---

# Docker Stack

The Docker Compose stack currently contains four services.

## PostgreSQL

Image:

```text
ankane/pgvector:latest
```

Two databases are initialized:

```text
n8n
evolution
```

The initialization script also enables the `vector` extension for the Evolution
database.

## Redis

Image:

```text
redis:7-alpine
```

Redis is used internally by the application stack and is not intended to be
publicly exposed.

## Evolution API

Image:

```text
evoapicloud/evolution-api:v2.3.7
```

Evolution API provides the WhatsApp integration layer.

## n8n

Image:

```text
n8nio/n8n:latest
```

n8n is responsible for workflow orchestration.

---

# Getting Started

For a complete deployment to a new OCI VM, follow:

**[DEPLOY.md](DEPLOY.md)**

The short version is:

```bash
cd terraform

terraform init
terraform validate
terraform plan
terraform apply
```

Then access the VM:

```bash
ssh -i ~/.ssh/oci_vm_key ubuntu@<IP_DA_VM>
```

Clone the project:

```bash
cd /home/ubuntu
git clone https://github.com/daniloof/whatsapp-insurance-agent.git
cd whatsapp-insurance-agent
```

Configure the environment:

```bash
cp docker/.env.example docker/.env
nano docker/.env
chmod 600 docker/.env
```

Start the stack:

```bash
docker compose pull
docker compose up -d
```

Check:

```bash
docker compose ps
```

---

# Configuration

Environment variables are documented in:

```text
docker/.env.example
```

The real environment file is:

```text
docker/.env
```

The real `.env` must never be committed.

Important secrets include:

```text
POSTGRES_PASSWORD
EVOLUTION_API_KEY
N8N_PASSWORD
LLM_API_KEY
```

For passwords embedded in PostgreSQL connection URIs, hexadecimal secrets are
preferred:

```bash
openssl rand -hex 32
```

---

# Validation

After starting the stack, validate the services.

## Evolution API

```bash
curl http://localhost:8080
```

Expected:

```json
{
  "status": 200,
  "message": "Welcome to the Evolution API, it is working!",
  "version": "2.3.7"
}
```

## n8n

```bash
curl http://localhost:5678
```

The command should return the n8n HTML page.

## Evolution → n8n

```bash
docker exec evolution-api sh -c 'wget -qO- http://n8n:5678/healthz || true'
```

Expected:

```json
{"status":"ok"}
```

This validates the internal Docker communication between Evolution API and n8n.

---

# Security

Secrets must never be committed to Git.

Do not commit:

```text
docker/.env
terraform/terraform.tfvars
*.pem
*.key
```

Do not expose publicly unless explicitly required and secured:

```text
5432  PostgreSQL
6379  Redis
5678  n8n
8080  Evolution API
```

The current OCI configuration allows external SSH access through TCP 22.

Public HTTPS access will be introduced later through a dedicated production
configuration.

---

# Development Roadmap

## Phase 1 — Infrastructure

- [x] OCI infrastructure
- [x] Terraform provisioning
- [x] ARM64 VM
- [x] Docker
- [x] PostgreSQL
- [x] pgvector
- [x] Redis
- [x] Evolution API
- [x] n8n
- [x] Internal Evolution → n8n communication
- [x] Deployment documentation

## Phase 2 — WhatsApp integration

- [ ] n8n webhook
- [ ] Evolution webhook configuration
- [ ] WhatsApp instance
- [ ] QR Code connection
- [ ] Receive inbound messages
- [ ] Send outbound messages
- [ ] End-to-end message test

## Phase 3 — AI Agent

- [ ] LLM integration
- [ ] Agent workflow
- [ ] Conversation context
- [ ] Prompt/guardrails
- [ ] Intent handling
- [ ] Insurance business rules

## Phase 4 — Knowledge and RAG

- [ ] Document ingestion
- [ ] Embeddings
- [ ] pgvector storage
- [ ] Semantic search
- [ ] Retrieval pipeline
- [ ] Grounded responses

## Phase 5 — Production

- [ ] Domain
- [ ] HTTPS
- [ ] Reverse proxy
- [ ] Production secrets management
- [ ] Backups
- [ ] Logging
- [ ] Monitoring
- [ ] Health checks
- [ ] Resource limits
- [ ] Docker image version pinning
- [ ] Security hardening

---

# Design Principles

## Separation of concerns

WhatsApp connectivity should not contain business logic.

```text
WhatsApp Adapter
      ↓
Orchestration
      ↓
Agent
      ↓
Business Logic
      ↓
Data / Knowledge
```

This keeps the system replaceable and easier to maintain.

## Infrastructure as Code

Infrastructure should be reproducible through Terraform rather than manually
configured in the OCI console.

## Configuration through environment

Environment-specific values and secrets belong outside the source code.

## Internal service communication

Services should communicate through the private Docker network whenever possible,
instead of exposing internal ports publicly.

## Reproducible deployment

A new environment should be deployable using the Terraform configuration,
Docker Compose stack and this documentation.

---

# Known Lessons

## OCI A1 capacity

The A1 Flex instance can fail with an `Out of host capacity` error even when
the Terraform configuration is correct.

This is an OCI capacity issue rather than a Terraform configuration error.

If capacity is unavailable in the selected Availability Domain, another
availability/resource configuration may be required.

## PostgreSQL passwords

Avoid generating a PostgreSQL password with arbitrary Base64 characters when
that password is directly embedded into a connection URI.

Use:

```bash
openssl rand -hex 32
```

instead.

## Fresh database initialization

`docker compose down -v` removes project volumes.

It was used during the initial installation because the environment contained no
important data. It must not be used as a generic production recovery command.

---

# Operational Philosophy

The project is intentionally being built in layers.

First:

```text
Infrastructure
```

Then:

```text
Connectivity
```

Then:

```text
Workflow
```

Then:

```text
AI Agent
```

Then:

```text
Knowledge / RAG
```

Then:

```text
Production hardening
```

Each layer should be validated before adding the next one.

This makes failures easier to isolate and makes the deployment reproducible.

---

# License

License not defined yet.
