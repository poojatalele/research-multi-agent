# Agent Workflow

This is the clean LangChain-style n8n workflow for the MVP. It should stay separate from the older REST/Gemini reference workflow in `workflows/research-mvp.json`.

## Canvas

```text
Research Form
  -> Literature Agent
  -> Normalize Literature Results
  -> Summarization Agent
  -> Parse Summary
  -> Aggregate Summaries
  -> Prepare Comparison Context
  -> Comparison Agent
  -> Parse Comparison
  -> Prepare Hypothesis Context
  -> Hypothesis Agent
  -> Parse Hypothesis
  -> Build Report
  -> Write Report
```

## Agent Nodes

- **Literature Agent** uses connected LangChain tools: `arXiv`, `Semantic Scholar`, and `OpenAlex`.
- **Summarization Agent** receives one normalized paper per item and returns summary JSON in `$json.output`.
- **Comparison Agent** receives the aggregated summaries and returns comparison JSON in `$json.output`.
- **Hypothesis Agent** receives summaries plus comparison JSON and returns gaps, hypothesis, experiment plan, and risks in `$json.output`.

## Important Handoffs

LangChain agent nodes return model text under `$json.output`. The parse nodes therefore read `$json.output`, strip optional markdown fences, and parse JSON from that value.

The old REST workflow returns Gemini responses under `candidates[0].content.parts[0].text`. Do not use that parser shape in this workflow.

## Common Clashes

- Do not connect normal `httpRequest` LLM calls between LangChain agents.
- Do not leave `hasOutputParser` enabled unless an actual output parser node is connected.
- Keep the search source calls as `httpRequestTool` nodes connected to the Literature Agent's `ai_tool` input.
- Keep `Normalize Literature Results` between Literature Agent and Summarization Agent; it turns the single search-agent JSON response into one item per paper.

## Provider Notes

Groq is the safest provider for the Literature Agent because that node needs tool calling. Use a smaller Groq model such as `llama-3.1-8b-instant` and set a Maximum Number of Tokens cap on every chat model node.

If using Cerebras through n8n's OpenAI Chat Model node, create an OpenAI-compatible credential with:

- API key: your Cerebras API key
- Base URL: `https://api.cerebras.ai/v1`

Then disable the OpenAI Responses API option if it appears in the node. Cerebras exposes OpenAI-compatible chat completions, but n8n's Responses API path can produce "resource not found" errors against that base URL.
