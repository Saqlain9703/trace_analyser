<p align="center">
  <img src="ui/public/favicon.svg" width="64" height="64" alt="Trace Analyzer icon" />
</p>

# Trace Analyzer

A local web UI for browsing and inspecting Watson Orchestrate agent traces, and exploring agent/tool configurations, across multiple WXO instances.

![Basic Usage](docs/screenshots/basic_usage.gif)

## Documentation

The full feature reference is in **[docs/USER_GUIDE.md](docs/USER_GUIDE.md)**.

It covers all six UI tabs (Explorer, Browser, Search, Details, Comparison, Ask), keyboard and Shift-key shortcuts, context management, batch mode, instance management, and the complete environment variable reference.

---

---

## Quick Start

### Option A — Docker (recommended)

No Python or Node.js setup required.

**1. Build the image (one-time)**

```bash
docker build -t trace-analyzer .
```

**2. Configure instances (optional)**

The app starts without an `instances.json` — you'll see an empty instance list and
can add instances from the UI. To pre-populate credentials, copy the template:

```bash
cp instances_template.json instances.json
# edit instances.json with your WXO credentials
```

See **[instances.json Format](#instancesjson-format)** below for the full schema.

**3. Run**

```bash
docker run -p 8080:8080 trace-analyzer
```

Open **<http://localhost:8080>** in your browser.

> To use a different port: `docker run -p 9000:9000 -e UI_PORT=9000 ...`

**With persistent trace cache** (survives container restarts):

```bash
docker run -p 8080:8080 \
  -v $(pwd)/instances.json:/app/instances.json \
  -v $(pwd)/data:/app/data \
  trace-analyzer
```

**Or use Docker Compose** (port + volumes pre-wired):

```bash
docker compose up
```

---

### Option B — Run locally

Requires Python 3.6+ and network access to your WXO instance(s).

**1. Install Python dependencies**

```bash
pip install -r requirements.txt
```

**2. Configure instances (optional)**

```bash
cp instances_template.json instances.json
# edit instances.json with your WXO credentials
```

**3. Configure environment (optional)**

```bash
cp template.env .env
# edit .env to override UI_PORT, TRACES_BASE_PATH, etc.
```

**4. Run**

```bash
PYTHONPATH=. python3 server/app.py
```

Open **<http://localhost:8080>** in your browser.

> To use a different port: `UI_PORT=9000 PYTHONPATH=. python3 server/app.py`

> **Note:** A pre-built `dist/` is committed to the repo so no Node.js build is
> needed for regular use. Only rebuild the UI if you modify the frontend source
> (see **[UI Development Workflow](#ui-development-workflow)** below).

---

## UI Development Workflow

When actively working on the UI, run both the Python backend and the Vite dev server
together. The Vite server hot-reloads UI changes; all `/api/*` calls are proxied to the
Python server.

**Terminal 1 — Python backend:**

```bash
PYTHONPATH=. python3 server/app.py
```

**Terminal 2 — Vite dev server:**

```bash
cd ui && npm run dev
```

Open **<http://localhost:5173>** (Vite) instead of port 8080 while developing.
When done, rebuild to refresh `dist/` for production use:

```bash
cd ui && npm run build
```

### Watch mode (auto-rebuild `dist/` on save)

If you prefer to keep the Python server as the only server (port 8080) and just want the
`dist/` folder rebuilt automatically whenever you save a file, use Vite's watch mode:

```bash
cd ui && npx vite build --watch
```

Vite will rebuild `dist/` on every source change. Refresh the browser at
**<http://localhost:8080>** to pick up the latest build.

---

## instances.json Format

Each entry is one WXO instance. The `name` field is what appears in the UI dropdown.

**CP4D (on-prem):**

```json
[
  {
    "name": "My On-Prem Instance",
    "instance_url": "https://cpd.example.com/orchestrate/.../instances/123",
    "CP4D_API_KEY": "<your-cp4d-api-key>",
    "CP4D_USER_NAME": "<your-cp4d-username>"
  }
]
```

**IBM Cloud (SaaS):**

```json
[
  {
    "name": "My Cloud Instance",
    "instance_url": "https://api.us-south.watson-orchestrate.cloud.ibm.com/instances/<id>",
    "IBMCLOUD_API_KEY": "<your-ibmcloud-api-key>"
  }
]
```

**AWS / Direct API Key:**

```json
[
  {
    "name": "My AWS Instance",
    "instance_url": "https://api.dl.watson-orchestrate.ibm.com/instances/<id>",
    "AWS_API_KEY": "<your-aws-api-key>"
  }
]
```

You can mix all three types in the same file. The app detects the auth type automatically based on which key is present.

---

## Trace Cache

Downloaded traces are saved to `data/traces/<instance-name>/` as individual `<trace-id>.json` files. Repeat lookups are instant. To force a re-download, delete the corresponding file or the whole directory for that instance.

---

## Environment Variables (optional)

All settings have sensible defaults. Override via a `.env` file at project root or shell env. See **[docs/USER_GUIDE.md#configuration](docs/USER_GUIDE.md#configuration)** for the full reference.

| Variable | Default | Purpose |
| --- | --- | --- |
| `UI_PORT` | `8080` | Port the web server listens on |
| `LOG_LEVEL` | `INFO` | Logging level (`DEBUG`, `INFO`, `WARNING`, `ERROR`, `CRITICAL`) |
| `TRACES_BASE_PATH` | `data/traces` | Directory for cached trace JSON files |
| `ARTIFACTS_BASE_PATH` | `data/artifacts` | Directory for exported agent/tool source files |
| `CONTEXTS_FILE` | `data/contexts.json` | Persisted named contexts for the Ask page |
| `INTERACTIONS_BASE_PATH` | `data/interactions` | Directory for Ask interaction logs |
| `MAX_INTERACTIONS` | `50` | Max interactions retained per agent |
| `ASK_TRACE_DELAY_SECONDS` | `5` | Seconds to wait before polling for a trace ID after an Ask query |
