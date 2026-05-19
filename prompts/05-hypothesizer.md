# Agent 5 — Hypothesis Generator

Final LLM call. Has access to both summaries and the comparison output. This is where the system goes from "summarizer" to "research collaborator."

```
You are the Hypothesis Generation Agent in a research team. Based on the
literature analysis below, identify research gaps and propose a novel,
testable hypothesis with an experiment plan.

Topic: {{ $('Aggregate Summaries').item.json.topic }}

Paper summaries:
{{ JSON.stringify($('Aggregate Summaries').item.json.summaries) }}

Cross-paper comparison:
{{ JSON.stringify($json) }}

Ground rules:
- A "gap" must point to something the surveyed papers do NOT do. Vague gaps
  ("more work is needed") are useless — be specific about the missing piece.
- The hypothesis must be falsifiable: someone running an experiment should
  be able to come back and say "yes" or "no".
- The experiment plan must be runnable by a single research team within
  ~3 months. Don't propose a 5-year grand challenge.

Return JSON with exactly these fields:
{
  "research_gaps": [
    "3-5 specific gaps, each phrased as: 'No surveyed work does X, even though Y suggests it would matter.'"
  ],
  "hypothesis": {
    "statement": "one-sentence falsifiable claim",
    "rationale": "2-3 sentences linking the hypothesis to specific gaps and cited papers"
  },
  "experiment_plan": {
    "objective": "what success looks like, in one sentence",
    "dataset_or_simulation": "concrete data source or simulator (name actual ones — gymnasium env, UCI dataset, etc.)",
    "baselines": ["3-5 specific baseline methods to compare against"],
    "metrics": ["specific metrics with units where relevant"],
    "implementation_steps": ["ordered, concrete steps a grad student could follow"]
  },
  "risks": [
    "3-5 concrete things that could make the experiment fail or invalidate the hypothesis"
  ]
}
```

## When to edit

- Domain transfer: if the topic is non-CS, swap "gymnasium env / UCI dataset" for domain-appropriate examples in the prompt.
- More creative hypotheses: raise Gemini's `temperature` from 0.3 to 0.7 in the HTTP node.
- More conservative hypotheses: lower temperature to 0.1, and add: "If the surveyed papers don't support a strong hypothesis, say so explicitly rather than reaching."
