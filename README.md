# Multi-Agent Research Assistant

An n8n workflow that helps a researcher go from a broad topic to a concise literature report. It searches academic papers, summarizes the selected work, compares methods, identifies gaps, and proposes a testable research hypothesis.

The workflow file is:

```text
workflows/Multi-Agent Research Assistant (MVP) - LangChain (1).json
```

## Problem Statement

Researchers often spend a lot of time doing the same early-stage literature review work: searching for relevant papers, extracting the main contribution from each paper, comparing methods, finding gaps, and turning those gaps into an experiment idea.

This project solves that problem with a small multi-agent workflow in n8n. The user enters a research topic, and the workflow produces a downloadable markdown report containing paper summaries, comparison notes, research gaps, a proposed hypothesis, and an experiment plan.

## Agents Used

- **Literature Agent**: searches OpenAlex and selects relevant papers for the topic.
- **Summarization Agent**: summarizes each selected paper into structured fields such as problem, method, dataset, results, limitations, and novelty.
- **Comparison Agent**: compares all paper summaries and groups related approaches.
- **Hypothesis Agent**: identifies research gaps and proposes a falsifiable hypothesis with an experiment plan.
- **Build Report node**: assembles the final markdown report as downloadable binary output.

## Start n8n With Docker

From the project root:

```bash
docker volume create n8n_data
docker run -d --name research-n8n \
  -p 5678:5678 \
  -e N8N_BLOCK_ENV_ACCESS_IN_NODE=false \
  -e N8N_RUNNERS_ENABLED=true \
  -e N8N_SECURE_COOKIE=false \
  -v n8n_data:/home/node/.n8n \
  docker.n8n.io/n8nio/n8n:latest
```

Open n8n:

```text
http://localhost:5678
```

Create the local n8n owner account if this is your first time opening it.

## Import And Configure

1. In n8n, go to **Workflows**.
2. Import the workflow JSON from `workflows/Multi-Agent Research Assistant (MVP) - LangChain (1).json`.
3. Open any **OpenRouter Chat Model** node.
4. Create an OpenRouter credential using your OpenRouter API key.
5. Select that same credential on all four OpenRouter Chat Model nodes.
6. Keep the model set to:

```text
openrouter/free
```

7. Save the workflow.

## Run The Workflow

1. Open the imported workflow.
2. Click **Research Form**.
3. Click **Execute step**.
4. Open the form URL shown by n8n.
5. Enter a topic and set **Max papers**.
6. Submit the form and wait for the workflow to finish.
7. Open the final **Build Report** node.
8. Download the markdown file from the binary output named `data`.

## Demo Video

[You can watch my Demo Video here:](demo-video.mov)
