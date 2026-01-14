# Rediver Platform

Rediver is a multi-tenant security platform with a Go backend API and Next.js frontend.

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        Docker Network                           │
│                                                                 │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐      │
│  │   rediver-ui │    │  rediver-api │    │   postgres   │      │
│  │   (Next.js)  │───▶│    (Go)      │───▶│  (Database)  │      │
│  │   Port 3000  │    │   Port 8080  │    │   Port 5432  │      │
│  └──────────────┘    └──────────────┘    └──────────────┘      │
│         │                   │                                   │
│         │                   ▼                                   │
│         │            ┌──────────────┐                          │
│         │            │    redis     │                          │
│         └───────────▶│   (Cache)    │                          │
│                      │   Port 6379  │                          │
│                      └──────────────┘                          │
└─────────────────────────────────────────────────────────────────┘
```

## Quick Start (Staging)

### Prerequisites

- Docker & Docker Compose v2+
- ~4GB RAM available

### 1. Clone and Setup

```bash
cd /path/to/rediverio

# Copy environment template
cp .env.staging.example .env.staging

# Generate secrets
make generate-secrets
```

### 2. Configure Environment

Edit `.env.staging` and paste the generated secrets:

```env
AUTH_JWT_SECRET=<paste_generated_jwt_secret>
CSRF_SECRET=<paste_generated_csrf_secret>
DB_PASSWORD=<paste_generated_db_password>
```

### 3. Start Everything

```bash
# Start all services (postgres, redis, migrations, api, ui)
make staging-up

# Or with test data
make staging-up-seed
```

That's it! The system will:
1. Start PostgreSQL and Redis
2. Run database migrations automatically
3. Build and start the API and UI

### 4. Access Application

- **Frontend**: http://localhost:3000
- **Backend API**: http://localhost:8080
- **API Health**: http://localhost:8080/health

**Test credentials** (when using `staging-up-seed`):
- Email: `admin@rediver.io`
- Password: `Password123`

---

## Makefile Commands

| Command | Description |
|---------|-------------|
| **Quick Start** | |
| `make staging-up` | Start staging (build + migrate + run) |
| `make staging-up-seed` | Start with test data |
| `make staging-down` | Stop all services |
| `make staging-logs` | View all logs |
| `make staging-ps` | Show running containers |
| `make status` | Show service status and URLs |
| **Build** | |
| `make staging-build` | Build images without starting |
| `make staging-rebuild` | Force rebuild and restart |
| `make build-api` | Build only API image |
| `make build-ui` | Build only UI image |
| **Database** | |
| `make db-shell` | Open PostgreSQL shell |
| `make db-seed` | Seed test data |
| `make db-reset` | Reset database (drop all data) |
| `make db-migrate` | Run migrations manually |
| **Cleanup** | |
| `make staging-clean` | Remove containers and volumes |
| `make staging-prune` | Remove unused Docker resources |
| **Utility** | |
| `make generate-secrets` | Generate secure secrets |
| `make help` | Show all commands |

---

## Project Structure

```
rediverio/
├── rediver-api/                    # Go backend API
│   ├── cmd/server/                 # Application entrypoint
│   ├── internal/                   # Private application code
│   │   ├── app/                    # Application services
│   │   ├── domain/                 # Domain models
│   │   └── infra/                  # Infrastructure (DB, HTTP)
│   ├── migrations/                 # Database migrations
│   │   ├── 000001_init_schema.up.sql    # Schema
│   │   ├── 000001_init_schema.down.sql  # Rollback
│   │   └── seed/
│   │       ├── seed_required.sql   # Required data
│   │       └── seed_test.sql       # Test data
│   ├── Makefile                    # API-specific commands
│   └── Dockerfile
│
├── rediver-ui/                     # Next.js frontend
│   ├── src/
│   │   ├── app/                    # App Router pages
│   │   ├── components/             # Shared components
│   │   ├── features/               # Feature modules
│   │   ├── lib/                    # Utilities & API client
│   │   └── stores/                 # Zustand stores
│   ├── Makefile                    # UI-specific commands
│   └── Dockerfile
│
├── docker-compose.staging.yml      # Staging deployment
├── .env.staging.example            # Environment template
├── Makefile                        # Root commands
└── README.md
```

---

## Database Migrations

Migrations run automatically when starting staging. For manual control:

```bash
# Run migrations
make db-migrate

# Rollback last migration
make db-migrate-down

# Reset and re-migrate
make db-reset
make staging-restart
```

### Schema Overview

| Table | Description |
|-------|-------------|
| `users` | User accounts (global) |
| `tenants` | Teams/organizations |
| `tenant_members` | User-tenant relationships |
| `assets` | Asset inventory (RLS) |
| `projects` | Code repositories (RLS) |
| `vulnerabilities` | CVE catalog (global) |
| `findings` | Vulnerability instances (RLS) |

See `rediver-api/docs/development/migrations.md` for details.

---

## Environment Variables

### Required

| Variable | Description | Example |
|----------|-------------|---------|
| `AUTH_JWT_SECRET` | JWT signing secret (64+ chars) | Generated |
| `CSRF_SECRET` | CSRF protection (32+ chars) | Generated |
| `DB_PASSWORD` | Database password | Generated |

### Optional

| Variable | Description | Default |
|----------|-------------|---------|
| `API_PORT` | API external port | `8080` |
| `UI_PORT` | UI external port | `3000` |
| `DB_USER` | Database username | `rediver` |
| `LOG_LEVEL` | Log level | `info` |
| `AUTH_PROVIDER` | Auth type | `local` |
| `SEED_TEST_DATA` | Seed test data | `true` |

### Production URLs

```env
# For production, update these:
NEXT_PUBLIC_API_URL=https://api.yourdomain.com
NEXT_PUBLIC_APP_URL=https://app.yourdomain.com
CORS_ALLOWED_ORIGINS=https://app.yourdomain.com
SECURE_COOKIES=true
```

---

## Development

For local development with hot reload:

### API Development

```bash
cd rediver-api
docker compose -f docker-compose.yml -f docker-compose.dev.yml up
```

### UI Development

```bash
cd rediver-ui
npm install
npm run dev
```

### Full Stack Development

Run API in Docker, UI locally:

```bash
# Terminal 1: API
cd rediver-api
docker compose -f docker-compose.yml -f docker-compose.dev.yml up

# Terminal 2: UI
cd rediver-ui
npm run dev
```

---

## Troubleshooting

### Services won't start

```bash
# Check logs
make staging-logs

# Check specific service
docker compose -f docker-compose.staging.yml logs api
docker compose -f docker-compose.staging.yml logs ui
```

### Database issues

```bash
# Check if postgres is healthy
docker compose -f docker-compose.staging.yml exec postgres pg_isready

# Access database shell
make db-shell

# Reset database
make db-reset
make staging-restart
```

### Build issues

```bash
# Force rebuild
make staging-rebuild

# Clean and restart
make staging-clean
make staging-up
```

### Port conflicts

Change ports in `.env.staging`:
```env
API_PORT=8081
UI_PORT=3001
DB_EXTERNAL_PORT=5433
```

---

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/health` | Health check |
| POST | `/api/v1/auth/register` | Register user |
| POST | `/api/v1/auth/login` | Login |
| GET | `/api/v1/tenants` | List tenants |
| GET | `/api/v1/assets` | List assets |
| GET | `/api/v1/projects` | List projects |

See `rediver-api/docs/api/` for full documentation.

---

## License

Copyright 2024 Rediver. All rights reserved.
