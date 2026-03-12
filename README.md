# AI Vision POC – On-Shelf Availability (OSA)

An **On-Shelf Availability (OSA)** proof-of-concept that uses Azure AI Vision / Custom Vision to analyse shelf images uploaded from in-store cameras, compute availability scores, raise alerts, and notify staff via Email / Microsoft Teams.

---

## Architecture

```
Camera / Edge Device
        │
        ▼ (upload image)
 Azure Blob Storage ──────────────────────────────────────────────────┐
  (shelf-images container)                                             │
        │ Blob / EventGrid trigger                                     │
        ▼                                                              │
 Azure Function App (Python 3.10)                                     │
  ├─ blob_trigger_starter / shelf_detector_blob                       │
  │     └─▶ shelf_orchestrator (Durable)                              │
  │              ├─▶ AnalyzeImageActivity  ◀── Custom Vision API ◀────┘
  │              ├─▶ WritePredictionActivity ──▶ Azure SQL
  │              ├─▶ PersistAlertActivity   ──▶ Azure SQL (Alerts)
  │              └─▶ PublishEventActivity   ──▶ Azure Event Hub
  │
  ├─ shelf_analyzer  (Event Hub trigger – downstream analytics)
  └─ shelf_status    (HTTP trigger – query current shelf status)

 Azure Logic App ──▶ Email (Office 365) / Teams notification
 Azure Key Vault  ──  stores all secrets
 App Insights     ──  monitoring & telemetry
 Azure IoT Hub    ──  optional edge device management
```

---

## Repository Layout

```
AI-Vision-POC/
├── infra/                          # Terraform Infrastructure-as-Code
│   ├── providers.tf                # AzureRM provider ~4.0
│   ├── variables.tf                # All input variables
│   ├── cognitive.tf                # AI Vision (Cognitive Services)
│   ├── iot_hub.tf                  # IoT Hub (F1 Free)
│   ├── eventhub.tf                 # Event Hub Namespace + Hub
│   ├── app_insights.tf             # Application Insights (x2)
│   ├── keyvault.tf                 # Key Vaults (x2) + secrets
│   ├── identity.tf                 # User-Assigned Managed Identity
│   ├── storage.tf                  # Storage Account + containers/queues/tables
│   ├── sql.tf                      # Azure SQL Server + Database
│   ├── function_app.tf             # Function App + Service Plan
│   ├── connections.tf              # Logic App API connections
│   ├── logic_app.tf                # Logic App Workflow
│   ├── outputs.tf                  # Terraform outputs
│   ├── terraform.tfvars.example    # Example vars file (copy → terraform.tfvars)
│   └── arm/
│       └── template.json           # Original ARM template (reference)
│
├── OSA/                            # Azure Functions project (Python)
│   ├── host.json                   # Functions v2 host config
│   ├── local.settings.json         # Local dev settings (never commit)
│   ├── requirements.txt            # Python dependencies
│   ├── sql_schema.sql              # SQL schema DDL
│   ├── blob_trigger_starter/       # Blob trigger → starts orchestration
│   ├── shelf_orchestrator/         # Durable orchestrator
│   ├── activities/
│   │   ├── AnalyzeImageActivity/   # Custom Vision inference
│   │   ├── WritePredictionActivity/# Persist to SQL
│   │   ├── PersistAlertActivity/   # Threshold evaluation + alert creation
│   │   └── PublishEventActivity/   # Publish to Event Hub
│   ├── shelf_analyzer/             # Event Hub consumer
│   ├── shelf_detector_blob/        # Alternative blob trigger
│   └── shelf_status/               # HTTP status endpoint
│
├── .gitignore
└── README.md
```

---

## Prerequisites

| Tool | Version |
|------|---------|
| [Terraform](https://developer.hashicorp.com/terraform/downloads) | >= 1.5.0 |
| [Azure CLI](https://docs.microsoft.com/cli/azure/install-azure-cli) | >= 2.50 |
| [Azure Functions Core Tools](https://github.com/Azure/azure-functions-core-tools) | v4 |
| Python | 3.10 |
| ODBC Driver for SQL Server | 18 |

---

## Part 1 – Deploy Infrastructure (Terraform)

### 1. Authenticate

```bash
az login
az account set --subscription "<your-subscription-id>"
```

### 2. Configure variables

```bash
cd infra
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars and fill in all placeholder values
```

### 3. Initialise and apply

```bash
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

### Key outputs after apply

| Output | Description |
|--------|-------------|
| `function_app_default_hostname` | Function App URL |
| `sql_server_fqdn` | SQL Server FQDN |
| `key_vault_uri_eastus` | Key Vault URI (eastus) |
| `eventhub_namespace_id` | Event Hub Namespace resource ID |

---

## Part 2 – Deploy Azure Functions

### 1. Install Python dependencies locally

```bash
cd OSA
python -m venv .venv
source .venv/bin/activate        # Windows: .venv\Scripts\activate
pip install -r requirements.txt
```

### 2. Set up local settings

```bash
# Copy and fill in local.settings.json with your Azure resource values
# (local.settings.json is git-ignored – never commit secrets)
```

### 3. Run locally

```bash
func start
```

### 4. Deploy to Azure

```bash
func azure functionapp publish func-osa-poc --python
```

---

## Part 3 – Initialize the SQL Database

Connect to the Azure SQL database (use Azure Data Studio, SSMS, or the Azure Portal query editor) and run:

```sql
-- Run against db-osa-poc
-- (see OSA/sql_schema.sql for the full script)
```

---

## Environment Variables / App Settings

| Variable | Description |
|----------|-------------|
| `AzureWebJobsStorage` | Storage account connection string |
| `EVENT_HUB_CONN` | Event Hub connection string |
| `AI_VISION_ENDPOINT` | Azure AI Vision endpoint URL |
| `AI_VISION_KEY` | Azure AI Vision API key |
| `CUSTOM_VISION_ENDPOINT` | Custom Vision prediction endpoint |
| `CUSTOM_VISION_KEY` | Custom Vision prediction key |
| `CUSTOM_VISION_PROJECT_ID` | Custom Vision project GUID |
| `CUSTOM_VISION_ITERATION` | Custom Vision published iteration name |
| `SQL_SERVER` | SQL Server FQDN |
| `SQL_DATABASE` | Database name |
| `SQL_USERNAME` | SQL login username |
| `SQL_PASSWORD` | SQL login password |
| `STORAGE_ACCOUNT_NAME` | Storage account name |
| `STORAGE_ACCOUNT_KEY` | Storage account access key |

> **Tip:** In the deployed Function App, `AI_VISION_KEY`, `CUSTOM_VISION_KEY`,
> `EventHubConn`, `SqlPassword`, and `StorageAccountKey` are resolved from
> Azure Key Vault via `@Microsoft.KeyVault(SecretUri=...)` references.

---

## OSA Alert Thresholds

| Score | Severity | Action |
|-------|----------|--------|
| < 50% | **Critical** | Alert created, event published, Logic App notifies via Email + Teams |
| < 75% | **Warning**  | Alert created, event published |
| ≥ 75% | *(no alert)* | Prediction recorded only |

---

## Shelf Image Naming Convention

Upload images to the `shelf-images` container using the path format:

```
shelf-images/<store_id>/<shelf_id>/<YYYYMMDDTHHmmss>_<filename>.jpg
```

Example: `shelf-images/store-001/shelf-A1/20240312T153000_capture.jpg`

---

## Security Notes

- All secrets are stored in **Azure Key Vault** and accessed via managed identity.
- The SQL Server uses **Azure AD authentication** with a user-assigned managed identity.
- `terraform.tfvars` and `local.settings.json` are excluded from git via `.gitignore`.
- Terraform state should be stored in a **remote backend** (e.g., Azure Blob Storage) for team use.