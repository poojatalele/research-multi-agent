# Agent 1 — Literature Search

Not an LLM prompt. The search agent is a deterministic Code node — see [`workflows/research-mvp.json`](../workflows/research-mvp.json) (node "1. Literature Search Agent") for the source.

## Tuning knobs

- **Result pool per source** — currently 30 per source (90 total before dedupe). Raise if you want more recall on niche topics; lower for speed.
- **Score weights** — `0.4 * citations + 0.3 * recency + 0.3 * term-overlap`. If you keep getting old foundational papers when you want frontier work, push `recency` to 0.5 and drop `citations` to 0.2.
- **Recency window** — currently 10 years (linear decay). Tighten to 5 for fast-moving subfields (LLM safety, multi-agent RL).
- **Dedupe key** — DOI first, then title with non-alphanumerics stripped, capped at 80 chars. Conservative; loosen if you see near-duplicates.

## Adding Google Scholar (later)

1. Get a [SerpAPI](https://serpapi.com/) key and put it in `.env` as `SERPAPI_KEY`.
2. In the Search Code node, uncomment the `serpapi` branch in the `requests` array.
3. Map SerpAPI's `organic_results[*]` to the common schema — note Scholar doesn't expose abstracts directly, so the `abstract` field will be the snippet.
