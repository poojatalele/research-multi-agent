# Multi-Agent Research Assistant (n8n + Gemini)

A small team of cooperating agents that, given a research topic, search the literature, summarize papers, compare methods, surface gaps, and propose a hypothesis with an experiment plan. Runs locally in n8n.

## MVP scope

| # | Agent | Implemented? |
|---|---|---|
| 1 | Literature Search (arXiv + Semantic Scholar + OpenAlex) | yes |
| 2 | Paper Summarizer (Gemini) | yes |
| 3 | Citation Graph | not yet |
| 4 | Comparator (Gemini) | yes |
| 5 | Hypothesis + Experiment Planner (Gemini) | yes |
| 6 | Experiment Planner (standalone) | folded into Agent 5 |
| 7 | Peer Review | not yet |

See [`docs/architecture.md`](docs/architecture.md) for the data flow.

## Prerequisites

- Node.js (already on this machine — v22)
- A Gemini API key — get one free at https://aistudio.google.com/apikey

That's it. No Docker required.

## Setup

```bash
cd /Users/apple/Documents/research-agents
cp .env.example .env
# Open .env and paste your GEMINI_API_KEY
./start-n8n.sh
```

First launch downloads n8n (~300MB) and may take a minute. When you see "Editor is now accessible via http://localhost:5678", open that URL.

n8n will ask you to create a local account on first run (email + password — stays on your machine).

## Import the workflow

In the n8n UI:

1. Top right → **Create Workflow** → **⋯ menu** → **Import from file**
2. Pick [`workflows/research-mvp.json`](workflows/research-mvp.json)
3. Click **Save** (top right)

You should see 14 nodes in a horizontal chain starting at "Research Form".

## Run it

1. Click the **Research Form** node → **Execute step** → it gives you a form URL (something like `http://localhost:5678/form/research-topic-form`).
2. Open that URL in a browser. Enter your topic ("multi-agent systems for smart agriculture") and max papers (default 10).
3. Submit. The workflow runs end-to-end — usually 1–3 minutes for 10 papers.
4. The final report is written to [`reports/`](reports/) as a markdown file like `report-2026-05-19-multi-agent-systems-for-smart-agriculture.md`.

You can also click any node in the n8n editor while it's running to inspect what came in and out — useful when debugging a prompt or a parse.

## Editing the prompts

Three Gemini agents have their prompts inside `Build * Request` Code nodes:

- **Agent 2** prompt — in node *Build Summarize Request*
- **Agent 4** prompt — in node *Build Compare Request*
- **Agent 5** prompt — in node *Build Hypothesis Request*

Source-of-truth copies live in [`prompts/`](prompts/) so you can iterate on them with version control. After editing a prompt in n8n, paste it back into the corresponding `prompts/*.md` file.

## Tuning the search

The search agent's score weights, recency window, and per-source result count are all at the top of the **1. Literature Search Agent** Code node. See [`prompts/01-search.md`](prompts/01-search.md) for what each knob does.

## Cost note

10 papers → ~12 Gemini calls (10 summaries + 1 comparison + 1 hypothesis). On Gemini 2.5 Flash that's well within free-tier limits (15 RPM / 1500 RPD as of early 2026). Run as much as you want.

## Adding the missing agents

- **Agent 3 (Citation graph)** — drop a new Code node between Aggregate Summaries and Build Compare Request. For each summary's DOI, call `https://api.semanticscholar.org/graph/v1/paper/{doi}/references?limit=20`. Build an adjacency map. Feed it into the comparison prompt as additional context.
- **Agent 7 (Peer Review)** — add Build Review Request → Review HTTP → Parse Review nodes after Build Report. Feed the assembled markdown to Gemini with a "find weak assumptions, missing baselines, unrealistic claims" prompt.

## Troubleshooting

- **`GEMINI_API_KEY` is empty / 401 from Gemini** — verify `.env` is set and that you launched via `./start-n8n.sh` (not raw `npx n8n`, which won't load `.env`). The flag `N8N_BLOCK_ENV_ACCESS_IN_NODE=false` must be set for `{{ $env.GEMINI_API_KEY }}` to resolve.
- **Empty / mangled JSON from Gemini** — usually a too-long abstract that ran into the token limit. Lower `max_papers`, or trim abstracts in the Search Agent before they hit the Summarizer.
- **arXiv or Semantic Scholar 429** — rate limits. Wait a minute, or get a Semantic Scholar key and put it in `S2_API_KEY`.
- **`this.helpers.httpRequest is not a function`** — older n8n versions used a different helper API. Update n8n: `npx --yes n8n@latest`.
- **Report not written, but workflow shows green** — check `REPORTS_DIR` is exported (the start script does it). Look at the **Write Report** node output for the resolved path.
