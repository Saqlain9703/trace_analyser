# AGENTS.md

This file provides guidance to agents when working with code in this repository.

## Stack

- Python 3.6+ (system), with a `.venv` at project root (pip only has base pip installed — deps installed system-wide)
- Dependencies: `requests`, `python-dotenv` (`dotenv` package). Install: `pip install -r requirements.txt`
- No build system, test framework, or linter configured

## Running Scripts

All Python command must use the .venv virtual environment in the root folder of the project.

All scripts must be run from the **project root** with `PYTHONPATH` set to the root, because `src/` imports resolve relative to root:

```bash
PYTHONPATH=. .venv/bin/python3 server/wxo_api_interface.py
```

The VSCode launch config (`.vscode/launch.json`) does this automatically for `Current File` via `"env": {"PYTHONPATH": "${cwd}"}`.

Environment variables are loaded from `.env` in the project root (loaded automatically by `python-dotenv`).

## Architecture

- **`server/wxo_api_interface.py`** — main API client for Watson Orchestrate (WXO). Runs standalone.
- **`src/wx_auth_utils.py`** — expected at root `src/`; handles auth for two instance types: `"CP4D"` (on-prem) and `"AWS"` (cloud). Auth type determines which API path is used.
- **`src/utils/span_parser.py`** — expected at root `src/utils/`; `build_trace_summary(trace_detail)` returns an object with `.user_input`.
- **`data/traces/`** — local disk cache for downloaded trace JSON files (named `<trace_id>.json`).

## Environment Variables

Key variables read from `.env`:

| Variable | Purpose |
| --- | --- |
| `WXO_INSTANCE_URL` | Watson Orchestrate base URL (CP4D or AWS endpoint) |
| `CP4D_USER_NAME` / `CP4D_API_KEY` | Auth for on-prem CP4D deployments |
| `IBMCLOUD_API_KEY` / `AWS_API_KEY` / `WO_API_KEY` | Auth for cloud/AWS deployments |
| `TRACES_BASE_PATH` | Directory to cache downloaded traces (e.g. `data/traces`) |
| `AGENT_ID` | Default agent to operate on |
| `LOG_SEARCH_HOURS` / `LOG_SEARCH_MINUTES` / `LOG_SEARCH_DAYS` | Time-window for trace search |
| `TRACES_INPUT_PATH` | Input directory for batch trace processing |
| `AGENT_TEST_SPEC` | JSON file with test specs for agent evaluation |
| `AGENT_TEST_THRESHOLD` | Pass/fail threshold (float, e.g. `0.8`) |

## Critical Patterns

### Two API versions co-exist

- **v1 / CP4D**: paginated `POST /v1/traces/search` with `filters` body
- **v3 / AWS**: `GET /v1/agentops-v3/traces` — no time filter on the search call; relies on timestamp ordering to stop pagination
- `WxAuthUtils.get_instance_type()` returns `"CP4D"` or `"AWS"` and determines which path runs

### Trace caching is two-tier

`get_trace_cached()` checks in-memory dict (`_trace_cache`) first, then disk (`TRACES_BASE_PATH/<id>.json`). Disk writes are skipped if the file already exists. `download_trace()` (without cache) always overwrites disk.

### `download_trace()` has a bug — it returns `None`

The return value of `download_trace_v1/v3` is never returned (missing `return` statement on line 237). Callers of `download_trace()` directly will receive `None`.

### Code style

- Type hints on all public method signatures using `typing` imports (`List`, `Dict`, `Any`, `Tuple`) — no `list[...]` / `dict[...]` generics style
- `str | None` union syntax is used (Python 3.10+ style), inconsistent with `List[Any]` imports
- `urllib3.disable_warnings` called at module level (SSL warnings suppressed globally)
- No logging framework — `print()` used for progress; `logging.warning()` used only in exception fallback
