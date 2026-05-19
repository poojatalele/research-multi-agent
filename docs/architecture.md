# Architecture — Multi-Agent Research Assistant (MVP)

## Pipeline

```
[Form Trigger: topic, max_papers]
      |
      v
[Agent 1 — Literature Search]   (Code node)
   - Parallel fetch: arXiv API, Semantic Scholar API, OpenAlex API
   - Normalize to common schema: {title, authors, abstract, year, citations, url, source, doi}
   - Dedupe by DOI then by normalized title
   - Score = 0.4*log(citations) + 0.3*recency + 0.3*term-overlap-with-topic
   - Emit top-N items, one per paper
      |
      | (n8n auto-iterates per item)
      v
[Agent 2 — Paper Summarizer]    (HTTP -> Gemini)
   - Structured JSON: problem, method, dataset, architecture, results, limitations, novelty
      |
      v
[Parse Summary]                  (Code)
   - Unwraps Gemini's candidates[0].content.parts[0].text
   - Attaches paper metadata back via $('Agent 1').item
      |
      v
[Aggregate]                      (Code)   -- N items -> 1 item
      |
      v
[Agent 4 — Comparator]           (HTTP -> Gemini)
   - Returns: markdown comparison table, clusters, cross-paper observations
      |
      v
[Parse Comparison]               (Code)
      |
      v
[Agent 5 — Hypothesizer]         (HTTP -> Gemini)
   - Returns: research_gaps[], hypothesis{statement,rationale}, experiment_plan{...}, risks[]
      |
      v
[Build Report]                   (Code) -- assembles full markdown report as binary
      |
      v
[Write to reports/]              (Read/Write File node)
```

## Why this shape

- **Code node for search, not 3 HTTP nodes + Merge.** A single Code node with `Promise.all` runs arXiv, Semantic Scholar, and OpenAlex in parallel and merges them in-process. Avoids brittle Merge-node timing and keeps the dedupe logic in one readable place.
- **Per-item HTTP fan-out instead of Split In Batches.** When the Search node emits N items, n8n automatically iterates downstream HTTP nodes once per item — no loop topology required, no "done vs loop" output to wire.
- **Inline prompts in HTTP body, mirrored in `/prompts`.** The workflow is self-contained, but `/prompts/*.md` is the human-editable source of truth.

## Sources and what each gives you

| Source | Free | Auth | Strengths | Weaknesses |
|---|---|---|---|---|
| arXiv | yes | none | Fresh CS/ML/physics preprints, full abstracts | No citation counts, CS-skewed |
| Semantic Scholar | yes | optional key | Citation counts, citation graph, broad coverage | Rate limits without key (~1 req/sec) |
| OpenAlex | yes | optional mailto | Broadest catalog incl. life sciences/agriculture | Abstracts as inverted index (reconstructed in code) |
| Google Scholar | n/a | n/a | Best coverage in theory | No official API. Add SerpAPI key + a branch to enable; not wired in MVP. |

## Scoring formula

```
score = 0.4 * log(1 + citations) / log(1 + max_citations)
      + 0.3 * max(0, 1 - (current_year - paper_year) / 10)
      + 0.3 * fraction_of_topic_terms_appearing_in_title_or_abstract
```

Tuneable inside the Search Agent Code node — `citations` weight rewards established work; `recency` keeps the frontier in view; `term-overlap` is a cheap relevance proxy without needing embeddings.

## Gemini call shape

All three LLM agents use the same REST pattern:

```
POST https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent
Header: x-goog-api-key: {{ $env.GEMINI_API_KEY }}
Body: {
  "contents": [{ "parts": [{ "text": "<prompt with injected data>" }] }],
  "generationConfig": {
    "responseMimeType": "application/json",
    "temperature": 0.3
  }
}
```

`responseMimeType: "application/json"` is the Gemini-side guarantee that output parses as JSON.

## What's deliberately out of scope for MVP

- Agent 3 (Citation graph) — adds value but needs Semantic Scholar `references`/`citations` endpoints and a graph-walk step. Add next.
- Agent 6 (Experiment planner) — partially absorbed into Agent 5's `experiment_plan` field. Split out when prompts get too long.
- Agent 7 (Peer Review) — easiest follow-up: one more HTTP→Gemini node that takes the full assembled report and returns a critique.
- PDF ingestion — arXiv abstracts are usually enough for MVP. For full text, add an `httpRequest` to the PDF URL + a PDF→text node.

## Adding agents later

Each new agent is one HTTP→Gemini node + one Code parse node, inserted before "Build Report". Keep the Build Report node aware of any new fields you add to the report.
