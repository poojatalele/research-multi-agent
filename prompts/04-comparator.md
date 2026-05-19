# Agent 4 — Comparator

Sent once per topic, after all summaries are aggregated. This is where the system earns its keep — a side-by-side table that a human can scan in 30 seconds.

```
You are the Comparison Agent in a research team. Given structured summaries
of N papers on a single topic, produce a comparison that helps a researcher
quickly see how the papers relate.

Topic: {{ $json.topic }}

Summaries (JSON array):
{{ JSON.stringify($json.summaries, null, 2) }}

Return JSON with exactly these fields:
{
  "table_markdown": "a GitHub-flavored markdown table with columns:
                     | Paper | Method | Dataset | Strength | Weakness | Novelty |
                     Use short paper labels (first author + year, e.g. 'Chen 2024').
                     One row per paper, max ~12 words per cell.",
  "clusters": [
    { "name": "cluster label (e.g. 'Multi-agent RL approaches')",
      "papers": ["Chen 2024", "Patel 2023"],
      "common_thread": "1 sentence on what unites these papers" }
  ],
  "observations": "3-5 short paragraphs of cross-paper observations:
                   trends, disagreements, evolution over time, dominant
                   datasets/benchmarks, methodological tradeoffs."
}
```

## When to edit

- If the table cells get too long, tighten the word cap.
- If you want a different comparison axis (e.g. reproducibility, compute cost), add a column to the markdown spec and the model will fill it in if the data exists.
- For very large N (>15 papers), the table gets unreadable. Consider an extra step: have the comparator pick the 8 most-representative papers across clusters and table only those.
